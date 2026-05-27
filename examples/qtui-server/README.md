# qtui-server

qtui-server is a Qt-based UI server for controlling Qt widgets through stdin/stdout. It provides more widgets than beui-server and includes layout management.

## Building

```bash
pkgman install qt6_base_devel llvm17_lld
make
```

The Makefile invokes `moc` and links with the LLD linker to work around a Haiku binutils bug.

## Protocol

Commands (stdin):
```
window <id> <title> <w> <h>           Create window
button <id> <parent> <label>          Create button
label <id> <parent> <text>            Create label
input <id> <parent> [placeholder]     Create text input
textarea <id> <parent>                Create text area
checkbox <id> <parent> <label>        Create checkbox
combo <id> <parent> <items...>        Create combo box
list <id> <parent> <items...>         Create list widget
hbox <id> <parent>                    Horizontal layout container
vbox <id> <parent>                    Vertical layout container
show <id>                             Show window
hide <id>                             Hide window
set <id> <property> <value>           Set property (text, enabled, checked)
get <id> <property>                   Get property
quit                                  Exit
```

Events (stdout):
```
ready                    Server started
ok <id>                  Success
error <msg>              Failure
clicked <id>             Button clicked
changed <id> <value>     Text changed
checked <id> <0|1>       Checkbox toggled
selected <id> <index>    List/combo selection
closed <id>              Window closed
value <id> <value>       Property value (response to get)
```

## Quick Test

```bash
echo -e 'window win1 "Test" 400 300\nbutton btn1 win1 "Hello"\nshow win1' | ./qtui-server
```

## Lisp Clients

Every client renders the same UI: a window titled "Hello from <Lang>!", a label, an input, a checkbox, and Greet/Quit buttons in an hbox. Clicking Quit sends the `quit` command, exits the server, and ends the client.

### Chicken Scheme

```bash
. ../../chicken-env.sh
csi -s qtui-client.scm
```

### SBCL

```bash
sbcl --load qtui-client.lisp
```

### ABCL

```bash
abcl --batch --load qtui-client.abcl.lisp
```

The script applies the `(pushnew :unix *features*)` shim inline. See the "ABCL" section in the top-level [README](../../README.md) for background.

### CLISP

```bash
clisp -q -norc qtui-client.clisp.lisp
```

The script uses `ext:make-pipe-io-stream` instead of `ext:run-program`. CLISP's `ext:run-program` with `:input :stream` is broken on Haiku and discards writes to the child's stdin.

### Clojure

```bash
java -cp '/boot/home/clojure-jars/*' clojure.main qtui-client.clj
```

This requires the Maven jars described in [`examples/clojure-swing/README.md`](../clojure-swing/README.md). The script drives qtui-server through `java.lang.ProcessBuilder` with separate `BufferedReader` and `BufferedWriter` streams.

### ECL

```bash
ecl --norc -load qtui-client.ecl.lisp
```

The script uses `ext:run-program` directly rather than `uiop:launch-program`. uiop classifies Haiku as a separate OS rather than a unix variant and errors on `launch-program`.

### Fennel

```bash
fennel qtui-client.fnl
```

The script bridges qtui-server's stdin/stdout through two FIFOs because Lua's `io.popen` is unidirectional. The server reads from `/tmp/qtui-cmd` and writes to `/tmp/qtui-evt`.

### Guile

```bash
guile --no-auto-compile qtui-client.scm.guile
```

The script uses `(open-pipe* OPEN_BOTH ...)` from `(ice-9 popen)` for bidirectional pipes.

### Janet

```bash
janet qtui-client.janet
```

The script uses `os/spawn` with `:in :pipe :out :pipe` and reads server output one byte at a time.

### NewLISP

```bash
newlisp qtui-client.lsp
```

The script drives qtui-server through `process` with two pipe pairs and closes the child's pipe ends so the server sees EOF on stdin.

## Architecture

```
Lisp code <-> stdin/stdout <-> qtui-server <-> Qt Widgets
```

The server runs a QApplication event loop while reading commands via QSocketNotifier on stdin.

## Compared with beui-server

| Feature | beui-server | qtui-server |
|---------|-------------|-------------|
| Toolkit | BeAPI (native) | Qt6 |
| Layout | Manual (x,y,w,h) | Automatic (hbox/vbox) |
| Widgets | Basic (window, button, label) | Rich (input, checkbox, combo, list, textarea) |
| Look | Native Haiku | Qt (configurable) |
| Dependencies | libroot, libbe | Qt6 |
