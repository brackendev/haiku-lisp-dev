# abcl-swing

ABCL on OpenJDK 17 drives Swing through Haiku's native AWT backend (`sun.hawt.HaikuToolkit`). It opens a JFrame with a blue panel, a yellow inner panel, and a Quit button. Closing the window or clicking Quit exits the JVM.

## Prerequisites

```bash
pkgman install openjdk17 openjdk17_default abcl
```

`openjdk17_default` adds `java` to `/boot/system/bin`. The `abcl` package uses the same JDK.

The Swing path does not need the `~/.abclrc` shim. The `(pushnew :unix *features*)` workaround in the top-level README applies when ASDF or Quicklisp load. This example uses raw `java:` interop and does not touch ASDF.

## Run

```bash
abcl --batch --load swing-test.lisp
```

ABCL takes several seconds to start before the script displays the JFrame.

## How it works

ABCL compiles Common Lisp to JVM bytecode. The same `sun.hawt.HaikuToolkit` backend that Clojure uses is available through `(require :java)` and the `jnew`/`jcall`/`jstatic`/`jfield` interop primitives. `java.awt.GraphicsEnvironment/isHeadless` returns false, so Swing/AWT is usable.

The script wraps frame construction in `SwingUtilities/invokeAndWait`, which puts Swing UI work on the event dispatch thread. `setDefaultCloseOperation` uses `EXIT_ON_CLOSE`, so closing the window terminates the JVM.

## Architecture

```
ABCL <-> JVM (OpenJDK 17) <-> Swing/AWT <-> sun.hawt.HaikuToolkit <-> BeAPI
```

## ABCL vs. Clojure on the JVM

Clojure and ABCL both use the Haiku AWT backend and render Swing widgets as native BeAPI windows. The Clojure path needs three Maven jars on the classpath. The ABCL path needs the `abcl` package. ABCL's ASDF integration needs the `:unix` shim, but the Swing path bypasses ASDF.
