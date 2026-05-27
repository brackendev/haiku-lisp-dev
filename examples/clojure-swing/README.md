# clojure-swing

Clojure on OpenJDK 17 drives Swing through Haiku's native AWT backend (`sun.hawt.HaikuToolkit`). It opens a window with a yellow rectangle on a blue panel and a Quit button. Closing the window or clicking Quit exits the JVM.

## Prerequisites

```bash
pkgman install openjdk17 openjdk17_default
```

`openjdk17_default` adds `java` to `/boot/system/bin`. Without it, run the JDK by full path: `/boot/system/lib/openjdk17/bin/java`.

Clojure has no Haiku package. Install the language jars manually from Maven Central:

```bash
mkdir -p ~/clojure-jars && cd ~/clojure-jars
curl -O https://repo1.maven.org/maven2/org/clojure/clojure/1.12.0/clojure-1.12.0.jar
curl -O https://repo1.maven.org/maven2/org/clojure/spec.alpha/0.5.238/spec.alpha-0.5.238.jar
curl -O https://repo1.maven.org/maven2/org/clojure/core.specs.alpha/0.4.74/core.specs.alpha-0.4.74.jar
```

`spec.alpha` and `core.specs.alpha` are required by Clojure 1.12. `clojure.main` fails to load without them.

## Run

```bash
java -cp '/boot/home/clojure-jars/*' clojure.main swing-test.clj
```

The JVM expands the classpath glob, not the shell, so quote the literal asterisk.

## How it works

Clojure 1.12 runs on OpenJDK 17. Swing calls reach the Haiku-native AWT backend through `sun.hawt.HaikuToolkit` and `sun.hawt.HaikuGraphicsDevice`, which render into a native BeAPI window. `java.awt.GraphicsEnvironment/isHeadless` returns false on Haiku, so Swing/AWT is usable. JVM threading is separate from the native Lisp threading constraints that affect SBCL, ECL, and CLISP, so `future`, `core.async`, and other concurrent constructs work.

ABCL also runs on the JVM, but its ASDF integration fails to recognize Haiku, so Quicklisp does not load. Clojure does not depend on ASDF and is not affected by that block.

## Architecture

```
Clojure <-> JVM (OpenJDK 17) <-> Swing/AWT <-> sun.hawt.HaikuToolkit <-> BeAPI
```
