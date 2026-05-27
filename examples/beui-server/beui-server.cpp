/*
 * beui-server: A simple UI server for controlling Haiku widgets via stdin/stdout
 *
 * Protocol (line-based, space-separated):
 *   Commands (stdin):
 *     window <id> <title> <x> <y> <w> <h>   - Create window
 *     button <id> <parent> <label> <x> <y> <w> <h>  - Create button
 *     label <id> <parent> <text> <x> <y> <w> <h>    - Create text label
 *     show <id>                              - Show window
 *     quit                                   - Exit application
 *
 *   Events (stdout):
 *     ok <id>                    - Command succeeded
 *     error <message>            - Command failed
 *     clicked <id>               - Button was clicked
 *     closed <id>                - Window was closed
 *
 * Build:
 *   g++ -o beui-server beui-server.cpp -lbe -lroot -lpthread
 *
 * Example:
 *   echo -e "window win1 Hello 100 100 300 200\nbutton btn1 win1 Click 10 10 80 30\nshow win1" |
 * ./beui-server The server keeps running after stdin closes. Close the window or send `quit`
 * through the protocol to exit.
 */

#include <Application.h>
#include <Button.h>
#include <Looper.h>
#include <Message.h>
#include <OS.h>
#include <StringView.h>
#include <View.h>
#include <Window.h>

#include <cstdarg>
#include <map>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>

// Message codes
enum { MSG_BUTTON_CLICKED = 'btnc', MSG_WINDOW_CLOSED = 'wndc', MSG_PROCESS_COMMAND = 'pcmd' };

// Forward declarations
class BeuiWindow;
class BeuiApp;

// Global state
static std::map<std::string, BWindow*> windows;
static std::map<std::string, BView*> views;
static BeuiApp* app = NULL;
static pthread_mutex_t output_mutex = PTHREAD_MUTEX_INITIALIZER;

// Thread-safe output
void
send_output(const char* fmt, ...)
{
	pthread_mutex_lock(&output_mutex);
	va_list args;
	va_start(args, fmt);
	vprintf(fmt, args);
	va_end(args);
	fflush(stdout);
	pthread_mutex_unlock(&output_mutex);
}

// Custom window that reports close events
class BeuiWindow : public BWindow {
public:
    std::string id;

    BeuiWindow(const char* id_, const char* title, BRect frame)
        : BWindow(frame, title, B_TITLED_WINDOW, B_QUIT_ON_WINDOW_CLOSE),
          id(id_) {}

    bool QuitRequested() override {
        send_output("closed %s\n", id.c_str());
        windows.erase(id);
        return true;
    }

    void MessageReceived(BMessage* msg) override {
        switch (msg->what) {
            case MSG_BUTTON_CLICKED: {
                const char* btn_id;
                if (msg->FindString("id", &btn_id) == B_OK) {
                    send_output("clicked %s\n", btn_id);
                }
                break;
            }
            default:
                BWindow::MessageReceived(msg);
        }
    }
};

// Custom button that sends click events
class BeuiButton : public BButton {
public:
    std::string id;

    BeuiButton(const char* id_, BRect frame, const char* label)
        : BButton(frame, id_, label, new BMessage(MSG_BUTTON_CLICKED)),
          id(id_) {
        Message()->AddString("id", id_);
    }
};

// Parse and execute a command
void
process_command(const char* line)
{
	char id[64] = {0};
	char parent[64] = {0};
	char text[256] = {0};
	float x, y, w, h;

	if (sscanf(line, "window %63s \"%255[^\"]\" %f %f %f %f", id, text, &x, &y, &w, &h) == 6
		|| sscanf(line, "window %63s %255s %f %f %f %f", id, text, &x, &y, &w, &h) == 6) {
		BRect frame(x, y, x + w, y + h);
		BeuiWindow* win = new BeuiWindow(id, text, frame);

		// Add a background view
		BView* bg = new BView(win->Bounds(), "background", B_FOLLOW_ALL, B_WILL_DRAW);
		bg->SetViewColor(ui_color(B_PANEL_BACKGROUND_COLOR));
		win->AddChild(bg);

		windows[id] = win;
		views[id] = bg;
		send_output("ok %s\n", id);
	} else if (sscanf(line, "button %63s %63s \"%255[^\"]\" %f %f %f %f", id, parent, text, &x, &y,
				   &w, &h)
			== 7
		|| sscanf(line, "button %63s %63s %255s %f %f %f %f", id, parent, text, &x, &y, &w, &h)
			== 7) {
		if (views.find(parent) == views.end()) {
			send_output("error parent_not_found %s\n", parent);
			return;
		}
		BRect frame(x, y, x + w, y + h);
		BeuiButton* btn = new BeuiButton(id, frame, text);
		views[parent]->AddChild(btn);
		views[id] = btn;
		send_output("ok %s\n", id);
	} else if (sscanf(line, "label %63s %63s \"%255[^\"]\" %f %f %f %f", id, parent, text, &x, &y,
				   &w, &h)
			== 7
		|| sscanf(line, "label %63s %63s %255s %f %f %f %f", id, parent, text, &x, &y, &w, &h)
			== 7) {
		if (views.find(parent) == views.end()) {
			send_output("error parent_not_found %s\n", parent);
			return;
		}
		BRect frame(x, y, x + w, y + h);
		BStringView* label = new BStringView(frame, id, text);
		views[parent]->AddChild(label);
		views[id] = label;
		send_output("ok %s\n", id);
	} else if (sscanf(line, "show %63s", id) == 1) {
		if (windows.find(id) == windows.end()) {
			send_output("error window_not_found %s\n", id);
			return;
		}
		windows[id]->Show();
		send_output("ok %s\n", id);
	} else if (strncmp(line, "quit", 4) == 0) {
		send_output("ok quit\n");
		be_app->PostMessage(B_QUIT_REQUESTED);
	} else if (line[0] != '\0' && line[0] != '#') {
		send_output("error unknown_command\n");
	}
}

// Reader thread - reads stdin and posts commands to app
void*
reader_thread(void* /*arg*/)
{
	char line[1024];
	while (fgets(line, sizeof(line), stdin)) {
		// Strip newline
		size_t len = strlen(line);
		if (len > 0 && line[len - 1] == '\n')
			line[len - 1] = '\0';

		// Post command to main thread
		BMessage msg(MSG_PROCESS_COMMAND);
		msg.AddString("line", line);
		be_app->PostMessage(&msg);
	}
	// EOF: stop reading but keep the app running so the user can interact.
	return NULL;
}

// Application
class BeuiApp : public BApplication {
public:
    BeuiApp() : BApplication("application/x-vnd.beui-server") {}

    void ReadyToRun() override {
        send_output("ready\n");
    }

    void MessageReceived(BMessage* msg) override {
        switch (msg->what) {
            case MSG_PROCESS_COMMAND: {
                const char* line;
                if (msg->FindString("line", &line) == B_OK) {
                    process_command(line);
                }
                break;
            }
            default:
                BApplication::MessageReceived(msg);
        }
    }
};


int
main()
{
	// Unbuffered output
	setvbuf(stdout, NULL, _IONBF, 0);

	// Create app
	app = new BeuiApp();

	// Start reader thread
	pthread_t reader;
	pthread_create(&reader, NULL, reader_thread, NULL);

	// Run app (blocks until quit)
	app->Run();

	delete app;
	return 0;
}
