# beui-server

beui-server is a small UI server for controlling native Haiku widgets through stdin/stdout. Any language can create native BeAPI interfaces by sending text commands.

## Building

```bash
make
```

## Protocol

Commands (stdin):
```
window <id> <title> <x> <y> <w> <h>         Create window
button <id> <parent> <label> <x> <y> <w> <h>   Create button
label <id> <parent> <text> <x> <y> <w> <h>     Create text label
show <id>                                    Show window
quit                                         Exit application
```

Events (stdout):
```
ready                    Server is ready
ok <id>                  Command succeeded
error <message>          Command failed
clicked <id>             Button was clicked
closed <id>              Window was closed
```

## Quick Test

```bash
echo -e 'window win1 "Test" 100 100 300 200\nbutton btn1 win1 "Hello" 10 10 80 30\nshow win1' | ./beui-server
```

The server keeps running after stdin closes. Close the window or send `quit` to exit.

## Lisp Clients

### Chicken Scheme

```bash
. ../../chicken-env.sh
csi -s beui-client.scm
```

### SBCL

```bash
sbcl --load beui-client.lisp
```

### ABCL

```bash
abcl --batch --load beui-client.abcl.lisp
```

The script applies the `(pushnew :unix *features*)` shim inline. See the "ABCL" section in the top-level [README](../../README.md) for background.

### CLISP

```bash
clisp -q -norc beui-client.clisp.lisp
```

The script uses `ext:make-pipe-io-stream` instead of `ext:run-program`. CLISP's `ext:run-program` with `:input :stream` is broken on Haiku and discards writes to the child's stdin. See the "CLISP" section in the top-level [README](../../README.md) for background.

### Clojure

```bash
java -cp '/boot/home/clojure-jars/*' clojure.main beui-client.clj
```

This requires the Maven jars described in [`examples/clojure-swing/README.md`](../clojure-swing/README.md). The script drives beui-server through `java.lang.ProcessBuilder` with separate `BufferedReader` and `BufferedWriter` streams.

### ECL

```bash
ecl --norc -load beui-client.ecl.lisp
```

The script uses `ext:run-program` directly rather than `uiop:launch-program`. uiop classifies Haiku as a separate OS rather than a unix variant and errors on `launch-program`. See the "ECL" section in the top-level [README](../../README.md) for background.

### Fennel

```bash
fennel beui-client.fnl
```

The script bridges beui-server's stdin/stdout through two FIFOs because Lua's `io.popen` is unidirectional.

### Guile

```bash
guile --no-auto-compile beui-client.scm.guile
```

The script uses `(open-pipe* OPEN_BOTH ...)` from `(ice-9 popen)` for bidirectional pipes.

### Janet

```bash
janet beui-client.janet
```

The script uses `os/spawn` with `:in :pipe :out :pipe` and reads server output one byte at a time because Janet's `core/stream` does not support line-oriented reads.

### NewLISP

```bash
newlisp beui-client.lsp
```

The script drives beui-server through `process` with two pipe pairs and closes the child's pipe ends so the server sees EOF on stdin.

## Architecture

```
Lisp code <-> stdin/stdout <-> beui-server <-> BeAPI (native widgets)
```

The server runs a BApplication message loop while reading commands from a separate thread. Events are sent back through stdout.
