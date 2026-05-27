# Changelog

This file tracks user-facing changes.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-05-27

### Added

#### GUI Paths
- Three delivery paths for Lisp GUIs on Haiku: direct SDL2 FFI, stdin/stdout UI servers, and JVM-hosted Swing
- Decision guide for choosing a path based on rendering needs, JVM tolerance, and widget requirements

#### beui-server
- Native BeAPI UI server controlled through stdin/stdout text commands
- Widgets: window, button, label with manual (x, y, w, h) positioning
- Events: ready, ok, error, clicked, closed
- BApplication message loop on the main thread with command reading on a separate thread
- Pre-built Haiku x86_64 binary distributed as a zip archive
- Clients for ABCL, Chicken Scheme, CLISP, Clojure, ECL, Fennel, Guile, Janet, NewLISP, and SBCL

#### qtui-server
- Qt6 UI server controlled through stdin/stdout text commands
- Widgets: window, button, label, input, textarea, checkbox, combo box, list widget
- Layout containers: hbox and vbox for automatic positioning
- Property access: get and set text, enabled, and checked states at runtime
- Events: ready, ok, error, clicked, changed, checked, selected, closed, value
- QApplication event loop with QSocketNotifier-based stdin reading
- LLD linker workaround for the Haiku binutils bug
- Pre-built Haiku x86_64 binary distributed as a zip archive
- Clients for ABCL, Chicken Scheme, CLISP, Clojure, ECL, Fennel, Guile, Janet, NewLISP, and SBCL

#### Direct SDL2 FFI
- SBCL example calling SDL2 through CFFI (low-level, no bordeaux-threads dependency)
- Chicken Scheme example using the SDL2 egg

#### Native Swing on the JVM
- Clojure Swing example rendering as native BeAPI windows through sun.hawt.HaikuToolkit
- ABCL Swing example using java: interop primitives (jnew, jcall, jstatic, jfield)

#### Lisp Client Implementations
- ABCL clients for beui-server and qtui-server with inline (pushnew :unix *features*) shim
- Chicken Scheme clients using process* for bidirectional pipes
- CLISP clients using ext:make-pipe-io-stream (workaround for broken ext:run-program on Haiku)
- Clojure clients using java.lang.ProcessBuilder with BufferedReader and BufferedWriter
- ECL clients using ext:run-program (workaround for uiop:launch-program ETYPECASE failure)
- Fennel clients bridging through two named FIFOs (workaround for unidirectional io.popen)
- Guile clients using (open-pipe* OPEN_BOTH ...) from (ice-9 popen)
- Janet clients using os/spawn with byte-at-a-time line reader (no stream flush or line reads)
- NewLISP clients using process with two pipe pairs and explicit child-end pipe closing
- SBCL clients using uiop:launch-program with bidirectional streams

#### Environment
- chicken-env.sh script to fix hard-coded paths in the Haiku Chicken package
- Compatibility matrix covering threading, FFI, OS detection, and GUI status for all ten implementations
- GUI behavior verification table recording live VM test results for every implementation and path
