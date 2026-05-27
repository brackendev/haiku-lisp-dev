/*
 * qtui-server: A Qt-based UI server controlled via stdin/stdout
 *
 * Protocol (line-based):
 *   Commands (stdin):
 *     window <id> <title> <w> <h>           - Create window
 *     button <id> <parent> <label>          - Create button
 *     label <id> <parent> <text>            - Create label
 *     input <id> <parent> [placeholder]     - Create text input
 *     textarea <id> <parent>                - Create text area
 *     checkbox <id> <parent> <label>        - Create checkbox
 *     combo <id> <parent> <items...>        - Create combo box
 *     list <id> <parent> <items...>         - Create list widget
 *     hbox <id> <parent>                    - Horizontal layout container
 *     vbox <id> <parent>                    - Vertical layout container
 *     show <id>                             - Show window
 *     hide <id>                             - Hide window
 *     set <id> <property> <value>           - Set property
 *     get <id> <property>                   - Get property
 *     quit                                  - Exit
 *
 *   Events (stdout):
 *     ready                    - Server started
 *     ok <id>                  - Success
 *     error <msg>              - Failure
 *     clicked <id>             - Button clicked
 *     changed <id> <value>     - Text changed
 *     checked <id> <0|1>       - Checkbox toggled
 *     selected <id> <index>    - List/combo selection
 *     closed <id>              - Window closed
 *     value <id> <value>       - Property value
 *
 * Build:
 *   pkgman install qt6_base_devel llvm17_lld
 *   make
 */

#include <QApplication>
#include <QCheckBox>
#include <QComboBox>
#include <QHBoxLayout>
#include <QLabel>
#include <QLineEdit>
#include <QListWidget>
#include <QMainWindow>
#include <QPushButton>
#include <QSocketNotifier>
#include <QTextEdit>
#include <QVBoxLayout>
#include <QWidget>

#include <iostream>
#include <map>
#include <sstream>
#include <string>
#include <unistd.h>
#include <vector>

static std::map<std::string, QWidget*> widgets;
static std::map<std::string, QLayout*> layouts;


void
sendOutput(const std::string& msg)
{
	std::cout << msg << std::endl;
	std::cout.flush();
}

class QtuiWindow : public QMainWindow {
    Q_OBJECT
public:
    std::string id;

    QtuiWindow(const std::string& id_, const QString& title, int w, int h)
        : id(id_) {
        setWindowTitle(title);
        resize(w, h);
        QWidget* central = new QWidget(this);
        setCentralWidget(central);
        QVBoxLayout* layout = new QVBoxLayout(central);
        layout->setAlignment(Qt::AlignTop);
        layouts[id] = layout;
    }

protected:
    void closeEvent(QCloseEvent*) override {
        sendOutput("closed " + id);
        widgets.erase(id);
        layouts.erase(id);
        deleteLater();
    }
};


std::string
parseToken(std::istringstream& iss)
{
	std::string token;
	char c;
	while (iss.get(c) && isspace(c))
		;
	if (!iss)
		return "";
	if (c == '"') {
		std::getline(iss, token, '"');
	} else {
		iss.putback(c);
		iss >> token;
	}
	return token;
}


std::vector<std::string>
parseRest(std::istringstream& iss)
{
	std::vector<std::string> tokens;
	std::string t;
	while ((t = parseToken(iss)) != "")
		tokens.push_back(t);
	return tokens;
}


QLayout*
findLayout(const std::string& id)
{
	auto it = layouts.find(id);
	return it != layouts.end() ? it->second : nullptr;
}


void
processCommand(const std::string& line)
{
	std::istringstream iss(line);
	std::string cmd;
	iss >> cmd;

	if (cmd == "window") {
		std::string id = parseToken(iss);
		std::string title = parseToken(iss);
		int w, h;
		iss >> w >> h;
		QtuiWindow* win = new QtuiWindow(id, QString::fromStdString(title), w, h);
		widgets[id] = win;
		sendOutput("ok " + id);
	} else if (cmd == "button") {
		std::string id = parseToken(iss);
		std::string parent = parseToken(iss);
		std::string label = parseToken(iss);
		QLayout* layout = findLayout(parent);
		if (!layout) {
			sendOutput("error no_parent " + parent);
			return;
		}
		QPushButton* btn = new QPushButton(QString::fromStdString(label));
		std::string bid = id;
		QObject::connect(btn, &QPushButton::clicked, [bid]() { sendOutput("clicked " + bid); });
		layout->addWidget(btn);
		widgets[id] = btn;
		sendOutput("ok " + id);
	} else if (cmd == "label") {
		std::string id = parseToken(iss);
		std::string parent = parseToken(iss);
		std::string text = parseToken(iss);
		QLayout* layout = findLayout(parent);
		if (!layout) {
			sendOutput("error no_parent " + parent);
			return;
		}
		QLabel* lbl = new QLabel(QString::fromStdString(text));
		layout->addWidget(lbl);
		widgets[id] = lbl;
		sendOutput("ok " + id);
	} else if (cmd == "input") {
		std::string id = parseToken(iss);
		std::string parent = parseToken(iss);
		std::string ph = parseToken(iss);
		QLayout* layout = findLayout(parent);
		if (!layout) {
			sendOutput("error no_parent " + parent);
			return;
		}
		QLineEdit* inp = new QLineEdit();
		if (!ph.empty())
			inp->setPlaceholderText(QString::fromStdString(ph));
		std::string iid = id;
		QObject::connect(inp, &QLineEdit::textChanged, [iid](const QString& t) {
			sendOutput("changed " + iid + " \"" + t.toStdString() + "\"");
		});
		layout->addWidget(inp);
		widgets[id] = inp;
		sendOutput("ok " + id);
	} else if (cmd == "textarea") {
		std::string id = parseToken(iss);
		std::string parent = parseToken(iss);
		QLayout* layout = findLayout(parent);
		if (!layout) {
			sendOutput("error no_parent " + parent);
			return;
		}
		QTextEdit* te = new QTextEdit();
		layout->addWidget(te);
		widgets[id] = te;
		sendOutput("ok " + id);
	} else if (cmd == "checkbox") {
		std::string id = parseToken(iss);
		std::string parent = parseToken(iss);
		std::string label = parseToken(iss);
		QLayout* layout = findLayout(parent);
		if (!layout) {
			sendOutput("error no_parent " + parent);
			return;
		}
		QCheckBox* cb = new QCheckBox(QString::fromStdString(label));
		std::string cid = id;
		QObject::connect(cb, &QCheckBox::checkStateChanged, [cid](Qt::CheckState s) {
			sendOutput("checked " + cid + " " + (s == Qt::Checked ? "1" : "0"));
		});
		layout->addWidget(cb);
		widgets[id] = cb;
		sendOutput("ok " + id);
	} else if (cmd == "combo") {
		std::string id = parseToken(iss);
		std::string parent = parseToken(iss);
		auto items = parseRest(iss);
		QLayout* layout = findLayout(parent);
		if (!layout) {
			sendOutput("error no_parent " + parent);
			return;
		}
		QComboBox* cb = new QComboBox();
		for (auto& i : items)
			cb->addItem(QString::fromStdString(i));
		std::string cid = id;
		QObject::connect(cb, QOverload<int>::of(&QComboBox::currentIndexChanged),
			[cid](int i) { sendOutput("selected " + cid + " " + std::to_string(i)); });
		layout->addWidget(cb);
		widgets[id] = cb;
		sendOutput("ok " + id);
	} else if (cmd == "list") {
		std::string id = parseToken(iss);
		std::string parent = parseToken(iss);
		auto items = parseRest(iss);
		QLayout* layout = findLayout(parent);
		if (!layout) {
			sendOutput("error no_parent " + parent);
			return;
		}
		QListWidget* lw = new QListWidget();
		for (auto& i : items)
			lw->addItem(QString::fromStdString(i));
		std::string lid = id;
		QObject::connect(lw, &QListWidget::currentRowChanged,
			[lid](int r) { sendOutput("selected " + lid + " " + std::to_string(r)); });
		layout->addWidget(lw);
		widgets[id] = lw;
		sendOutput("ok " + id);
	} else if (cmd == "hbox" || cmd == "vbox") {
		std::string id = parseToken(iss);
		std::string parent = parseToken(iss);
		QLayout* pl = findLayout(parent);
		if (!pl) {
			sendOutput("error no_parent " + parent);
			return;
		}
		QWidget* c = new QWidget();
		QLayout* l = (cmd == "hbox") ? (QLayout*)new QHBoxLayout(c) : (QLayout*)new QVBoxLayout(c);
		l->setContentsMargins(0, 0, 0, 0);
		pl->addWidget(c);
		layouts[id] = l;
		widgets[id] = c;
		sendOutput("ok " + id);
	} else if (cmd == "show") {
		std::string id = parseToken(iss);
		auto it = widgets.find(id);
		if (it == widgets.end()) {
			sendOutput("error not_found " + id);
			return;
		}
		it->second->show();
		sendOutput("ok " + id);
	} else if (cmd == "hide") {
		std::string id = parseToken(iss);
		auto it = widgets.find(id);
		if (it == widgets.end()) {
			sendOutput("error not_found " + id);
			return;
		}
		it->second->hide();
		sendOutput("ok " + id);
	} else if (cmd == "set") {
		std::string id = parseToken(iss);
		std::string prop = parseToken(iss);
		std::string val = parseToken(iss);
		auto it = widgets.find(id);
		if (it == widgets.end()) {
			sendOutput("error not_found " + id);
			return;
		}
		QWidget* w = it->second;
		if (prop == "text") {
			if (auto* l = qobject_cast<QLabel*>(w))
				l->setText(QString::fromStdString(val));
			else if (auto* e = qobject_cast<QLineEdit*>(w))
				e->setText(QString::fromStdString(val));
			else if (auto* t = qobject_cast<QTextEdit*>(w))
				t->setPlainText(QString::fromStdString(val));
			else if (auto* b = qobject_cast<QPushButton*>(w))
				b->setText(QString::fromStdString(val));
		} else if (prop == "enabled") {
			w->setEnabled(val == "1" || val == "true");
		} else if (prop == "checked") {
			if (auto* c = qobject_cast<QCheckBox*>(w))
				c->setChecked(val == "1");
		}
		sendOutput("ok " + id);
	} else if (cmd == "get") {
		std::string id = parseToken(iss);
		std::string prop = parseToken(iss);
		auto it = widgets.find(id);
		if (it == widgets.end()) {
			sendOutput("error not_found " + id);
			return;
		}
		QWidget* w = it->second;
		std::string val;
		if (prop == "text") {
			if (auto* l = qobject_cast<QLabel*>(w))
				val = l->text().toStdString();
			else if (auto* e = qobject_cast<QLineEdit*>(w))
				val = e->text().toStdString();
			else if (auto* t = qobject_cast<QTextEdit*>(w))
				val = t->toPlainText().toStdString();
		} else if (prop == "checked") {
			if (auto* c = qobject_cast<QCheckBox*>(w))
				val = c->isChecked() ? "1" : "0";
		}
		sendOutput("value " + id + " \"" + val + "\"");
	} else if (cmd == "quit") {
		sendOutput("ok quit");
		QApplication::quit();
	} else if (!cmd.empty() && cmd[0] != '#') {
		sendOutput("error unknown " + cmd);
	}
}

class InputHandler : public QObject {
    Q_OBJECT
public:
    InputHandler(QObject* p = nullptr) : QObject(p) {
        n = new QSocketNotifier(STDIN_FILENO, QSocketNotifier::Read, this);
        connect(n, &QSocketNotifier::activated, this, &InputHandler::read);
    }
private slots:
    void read() {
        std::string line;
        if (std::getline(std::cin, line)) processCommand(line);
        else n->setEnabled(false);  // EOF - stop reading but keep windows open
    }
private:
    QSocketNotifier* n;
};

#include "qtui-server.moc"


int
main(int argc, char* argv[])
{
	QApplication app(argc, argv);
	std::cout.setf(std::ios::unitbuf);
	InputHandler h;
	sendOutput("ready");
	return app.exec();
}
