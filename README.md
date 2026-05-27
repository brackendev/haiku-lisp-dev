# Haiku Lisp Development

This repository documents GUI options for Lisp dialects on Haiku®. It includes runnable examples for ten implementations and two stdin/stdout UI servers ([`beui-server`](https://github.com/brackendev/haiku-lisp-dev/releases) for native BeAPI, [`qtui-server`](https://github.com/brackendev/haiku-lisp-dev/releases) for Qt6) that any Lisp can drive without a foreign function interface.

The examples use three paths:

- SDL2 through FFI for SBCL and Chicken.
- Stdin/stdout UI servers (`beui-server`, `qtui-server`), usable from any implementation in this repository.
- Swing on the JVM through Haiku's native AWT backend for Clojure and ABCL.

## Choosing an Approach

Use these questions to choose a path.

1. **Do you need custom rendering**, such as a game, graphics, or custom drawing, instead of form widgets?
   - Yes: use Direct SDL2 FFI.
   - No: continue.

2. **Is a JVM acceptable** as a runtime dependency?
   - Yes: use Native Swing on the JVM.
   - No: continue.

3. **Do you want native Haiku look, or richer widgets and automatic layout?**
   - Native Haiku look with manual positioning: use beui-server.
   - Qt look with automatic layout and more widgets: use qtui-server.

### Comparison

| Path | Look | Layout | Languages | Threading | FFI required | Process model |
|------|------|--------|-----------|-----------|--------------|---------------|
| **Direct SDL2 FFI** | Custom drawing | Manual | SBCL, Chicken | Not required | Yes (CFFI) | Single Lisp process |
| **Swing on the JVM** | Native BeAPI | Java layout managers | Clojure, ABCL | JVM threads | No | Single JVM process |
| **beui-server** (stdin/stdout) | Native BeAPI | Manual `(x, y, w, h)` | Every implementation in this repository | Not required | No | Lisp + C++ server |
| **qtui-server** (stdin/stdout) | Qt6 | Automatic (hbox/vbox) | Every implementation in this repository | Not required | No | Lisp + C++ server |

### Direct SDL2 FFI (SBCL, Chicken)

Use this path for graphics, games, custom drawing, or FFI checks.

- **Pros**: Single process, full control over rendering, no protocol overhead.
- **Cons**: No native widgets. All rendering is manual. Only SBCL and Chicken have SDL2 examples here. The high-level `cl-sdl2` wrapper requires `bordeaux-threads`, which does not load without `:sb-thread`, so the SBCL example calls SDL2 through CFFI directly.

See [examples/sbcl-sdl2](examples/sbcl-sdl2) and [examples/chicken-sdl2](examples/chicken-sdl2).

### Native Swing on the JVM (Clojure, ABCL)

Use this path for JVM-hosted Lisps that need native Haiku widgets in the same process.

- **Pros**: Native BeAPI rendering through `sun.hawt.HaikuToolkit`, JVM threading, AWT/Swing widgets, no FFI binding.
- **Cons**: Requires OpenJDK 17. Only Clojure and ABCL are JVM-hosted in this repository. ABCL needs `(pushnew :unix *features*)` before ASDF or Quicklisp load.

See [examples/clojure-swing](examples/clojure-swing) and [examples/abcl-swing](examples/abcl-swing).

### beui-server (stdin/stdout)

Use this path for native Haiku widgets from any implementation in this repository, without a JVM.

- **Pros**: Native BeAPI look, no Lisp-side FFI, works from every implementation in this repository, simple line protocol.
- **Cons**: Manual `(x, y, w, h)` positioning. Two processes to manage. Limited widget set (window, button, label).

See [examples/beui-server](examples/beui-server) for the protocol, build steps, and client examples.

### qtui-server (stdin/stdout)

Use this path for automatic layout or a larger widget set when Qt styling is acceptable.

- **Pros**: Automatic layout via `hbox`/`vbox`, more widgets (input, textarea, checkbox, combo, list), event coverage for changes, checks, and selections, works from every implementation.
- **Cons**: Qt look rather than native Haiku look. Requires Qt6 and the LLD linker workaround at build time. Two processes to manage.

See [examples/qtui-server](examples/qtui-server) for the protocol, build steps, and client examples.

## Setup

Install the native Lisp implementations:

```bash
pkgman install sbcl ecl clisp abcl chicken janet guile_tools newlisp fennel
```

The `guile_tools` package provides the `guile` binary. The `guile` package alone installs only the runtime libraries.

Install SDL2 for the direct FFI examples:

```bash
pkgman install libsdl2 libsdl2_devel
```

Install Qt6 for the qtui-server example:

```bash
pkgman install qt6_base_devel llvm17_lld
```

The Qt example requires LLD because of a binutils bug on Haiku.

Install OpenJDK 17 for the JVM examples:

```bash
pkgman install openjdk17 openjdk17_default
```

`openjdk17_default` adds `java` to `/boot/system/bin`. Clojure has no Haiku package. Install the language jars manually as described in [examples/clojure-swing](examples/clojure-swing).

### Quicklisp (SBCL)

If Quicklisp is not installed:

```bash
curl -o /tmp/quicklisp.lisp https://beta.quicklisp.org/quicklisp.lisp
sbcl --non-interactive --load /tmp/quicklisp.lisp \
     --eval '(quicklisp-quickstart:install)'
```

Add to `~/.sbclrc`:

```lisp
#-quicklisp
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                       (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))
```

### Chicken environment

Source [`chicken-env.sh`](chicken-env.sh) before any `chicken-install` or `csi` command. The script fixes hard-coded paths in the Haiku Chicken package:

```bash
. chicken-env.sh
chicken-install srfi-1   # confirms the install path is wired up
```

## Compatibility Matrix

Rows are ordered by how clean the GUI path is and how many GUI options each implementation has.

| Implementation | Type | Threading | FFI | OS Detection | GUI Examples |
|----------------|------|-----------|-----|--------------|--------------|
| **Clojure** | Lisp on JVM | Yes (JVM) | JNI | ✓ (`os.name=Haiku`) | [Swing](examples/clojure-swing), [beui-server](examples/beui-server), [qtui-server](examples/qtui-server) |
| **Guile** | Scheme (GNU) | Yes (native) | Yes | ✓ (`%host-type=*-haiku`) | [beui-server](examples/beui-server), [qtui-server](examples/qtui-server) |
| **SBCL** | Common Lisp | No | CFFI ✓ | ✓ | [SDL2](examples/sbcl-sdl2), [beui-server](examples/beui-server), [qtui-server](examples/qtui-server) |
| **Chicken** | Scheme | No | Yes | ✓ | [SDL2](examples/chicken-sdl2), [beui-server](examples/beui-server), [qtui-server](examples/qtui-server) |
| **ABCL** | Common Lisp (JVM) | Yes (JVM) | Java | ✓ with `:unix` shim | [Swing](examples/abcl-swing), [beui-server](examples/beui-server), [qtui-server](examples/qtui-server) |
| **Janet** | Lisp dialect | Event loop only | Yes | `(os/which) => :posix` | [beui-server](examples/beui-server), [qtui-server](examples/qtui-server) |
| **ECL** | Common Lisp | No | Yes | ✓ (`:HAIKU`) | [beui-server](examples/beui-server), [qtui-server](examples/qtui-server) |
| **NewLISP** | Lisp dialect | No | Yes | Shell `uname` | [beui-server](examples/beui-server), [qtui-server](examples/qtui-server) |
| **CLISP** | Common Lisp | No | Yes | ✓ (`:HAIKU`) | [beui-server](examples/beui-server), [qtui-server](examples/qtui-server) |
| **Fennel** | Lisp on Lua | No | Via Lua | Shell `uname` | [beui-server](examples/beui-server), [qtui-server](examples/qtui-server) (FIFO bridge) |

## Lisp Implementation Notes

### ABCL

ABCL runs on the JVM with full threading support and reports `(software-type) => "Haiku"`, but it does not add an OS marker to `*features*`. ASDF/uiop recognizes `:unix`, `:windows`, `:genera`, and `:macos`. Without one of those markers, ASDF errors with:

```
Congratulations for trying ASDF on an operating system
that is neither Unix, nor Windows, nor Genera, nor even old MacOS.
Now you port it.
```

Haiku is POSIX-compatible, so `:unix` is the correct marker. Add it in `~/.abclrc`:

```lisp
(pushnew :unix *features*)
```

ABCL loads `.abclrc` on startup. After that, `(require :asdf)` and `(load "~/quicklisp/setup.lisp")` succeed. Verified on ABCL 1.9.2 / OpenJDK 17.0.14: ASDF 3.3.6 loads, `uiop:os-unix-p` returns T, and `(ql:quickload :alexandria)` completes. See [`examples/beui-server/beui-client.abcl.lisp`](examples/beui-server/beui-client.abcl.lisp) for a beui-server client.

The shim is needed for ASDF and Quicklisp. AWT/Swing through `sun.hawt.HaikuToolkit` works through `(require :java)` and the `jnew`/`jcall`/`jstatic`/`jfield` interop primitives, which do not touch ASDF. See [`examples/abcl-swing/swing-test.lisp`](examples/abcl-swing/swing-test.lisp).

A durable fix belongs in ABCL's `Lisp.java` `_FEATURES_` initialization: push `:unix` when `os.name=Haiku`. SBCL, ECL, and CLISP report `:UNIX` without intervention.

### Chicken Scheme

The SDL2 example uses the [SDL2 egg](http://wiki.call-cc.org/eggref/5/sdl2).

Install the runtime and headers:

```bash
pkgman install chicken chicken_devel libsdl2 libsdl2_devel
```

Source [`chicken-env.sh`](chicken-env.sh) in every shell that runs Chicken. See [`examples/chicken-sdl2/`](examples/chicken-sdl2/) for a complete working example.

### CLISP

CLISP recognizes Haiku (`:HAIKU` in `*features*`) and has FFI support. It has no threading on Haiku (`:MT` feature missing).

`ext:run-program` with `:input :stream` is broken on Haiku: the pipe is created, but bytes written to it are discarded before reaching the child's stdin. `:output :stream` works for one-way reads from the child. Use `ext:make-pipe-io-stream` for bidirectional pipes. See [`examples/beui-server/beui-client.clisp.lisp`](examples/beui-server/beui-client.clisp.lisp) for a working beui-server client.

### Clojure

Clojure runs on the JVM. OpenJDK 17 is packaged for Haiku and exposes a native AWT backend (`sun.hawt.HaikuToolkit`, `sun.hawt.HaikuGraphicsDevice`). Swing components render as native BeAPI windows.

| Component | Status | Notes |
|-----------|--------|-------|
| OpenJDK 17 | Packaged | `pkgman install openjdk17 openjdk17_default` |
| `os.name` reported by JVM | `Haiku` | Verified on OpenJDK 17.0.14 |
| Threading | Working | `future`, `core.async`, JVM thread pool all available |
| AWT/Swing | Working | `GraphicsEnvironment/isHeadless` returns false |
| Clojure CLI / Leiningen | Not packaged | Use the Maven jars directly |

Install the jars once:

```bash
pkgman install openjdk17 openjdk17_default
mkdir -p ~/clojure-jars && cd ~/clojure-jars
curl -O https://repo1.maven.org/maven2/org/clojure/clojure/1.12.0/clojure-1.12.0.jar
curl -O https://repo1.maven.org/maven2/org/clojure/spec.alpha/0.5.238/spec.alpha-0.5.238.jar
curl -O https://repo1.maven.org/maven2/org/clojure/core.specs.alpha/0.4.74/core.specs.alpha-0.4.74.jar
```

Run the Swing example from `examples/clojure-swing`:

```bash
java -cp '/boot/home/clojure-jars/*' clojure.main swing-test.clj
```

The JVM expands the classpath glob, not the shell, so quote the literal asterisk.

Clojure also drives the stdin/stdout UI servers through `java.lang.ProcessBuilder` with `BufferedReader` and `BufferedWriter`. See [`examples/beui-server/beui-client.clj`](examples/beui-server/beui-client.clj) for a working beui-server client.

### Fennel

Fennel compiles to Lua and runs on the Lua runtime. It is packaged on Haiku as `fennel`. The beui-server and qtui-server clients use two named FIFOs because Lua's `io.popen` is unidirectional.

### Guile

Guile is GNU Scheme. It is packaged on Haiku as `guile_tools`. It has a SRFI-compliant module system, FFI through `(system foreign)`, and bidirectional process pipes through `(ice-9 popen)` `open-pipe*`. See [`examples/beui-server/beui-client.scm.guile`](examples/beui-server/beui-client.scm.guile) for a working beui-server client.

### ECL

ECL compiles Common Lisp to C. It recognizes Haiku (`:HAIKU` in `*features*` and `(software-type)` returns `"Haiku"`). It has no threading on Haiku.

ECL ships ASDF and uiop, but `uiop:detect-os` returns `:HAIKU`. uiop classifies Haiku as a separate OS rather than a unix variant, so `uiop:launch-program` errors with an ETYPECASE failure. Use `ext:run-program` directly for bidirectional pipes. See [`examples/beui-server/beui-client.ecl.lisp`](examples/beui-server/beui-client.ecl.lisp) for a working beui-server client.

### Janet

Janet is a Lisp dialect with FFI. `(os/which)` returns `:posix` because Janet has no Haiku-specific value. `(os/arch)` returns `:x64`. Janet exposes no OS threads to user code. Concurrency is cooperative through the `ev/` event loop.

`os/spawn` accepts `{:in :pipe :out :pipe}` and returns a process struct whose `:in` and `:out` slots are `core/stream` objects. Streams support `:write` and byte-count `:read`, but not `:flush` or line-oriented reads. The example builds a one-byte-at-a-time line reader. See [`examples/beui-server/beui-client.janet`](examples/beui-server/beui-client.janet) for a working beui-server client.

[SDL2 FFI bindings](https://github.com/ericnewton/janet-sdl2-tutorial) are available; not exercised in this repository.

### NewLISP

NewLISP is a small dynamic Lisp. It is packaged on Haiku as `newlisp`. It has built-in networking, FFI, and process control through `process` and `pipe`. See [`examples/beui-server/beui-client.lsp`](examples/beui-server/beui-client.lsp) for a working beui-server client.

### McCLIM

[McCLIM](https://mcclim.common-lisp.dev/) is the free implementation of CLIM (Common Lisp Interface Manager).

| Backend | Requirements | Status |
|---------|--------------|--------|
| CLX | X11 server | Needs X11 installed on Haiku |
| CLDK/SDL2 | bordeaux-threads | Blocked by the threading constraint below |
| Raster Image | None | Headless only |

McCLIM is not viable on Haiku without native Common Lisp threading.

### SBCL

| Component | Status | Notes |
|-----------|--------|-------|
| SBCL | 2.6.0 | Official Haiku support, links against `-lbe` |
| Quicklisp | Working | Install via the bootstrap above |
| CFFI | Working | Foreign function interface |
| BSD Sockets | Working | Network access functional |
| Threading | Missing | No `:sb-thread` feature |

Without threading, event handling must poll in the main loop. Complex applications must avoid blocking calls.

If the SBCL Haiku port gains threading, the following become available:

- Full `cl-sdl2` library
- McCLIM with the CLDK/SDL2 backend
- The `bordeaux-threads` ecosystem

See the [Haiku community discussion](https://discuss.haiku-os.org/t/porting-sbcl-common-lisp-to-haiku/8928) for background on the threading limitation.

## Threading Constraint

All native Common Lisp implementations on Haiku lack threading support:

```lisp
;; SBCL
(member :sb-thread *features*)  ; => NIL

;; ECL
(member :threads *features*)    ; => NIL

;; CLISP
(member :mt *features*)         ; => NIL
```

Chicken Scheme on Haiku also has no threading. Libraries that require `bordeaux-threads` do not load:

- `cl-sdl2` (the high-level SDL2 wrapper)
- McCLIM interactive backends
- Most asynchronous and concurrent libraries

Event loops in this repository must poll or delegate the event loop to an external process through the stdin/stdout server pattern.

ABCL and Clojure run on the JVM and have full threading. ABCL needs the `*features*` shim described above before ASDF and Quicklisp load. Clojure does not depend on ASDF.

## Working with the VM

The companion [`haiku-macos-dev`](https://github.com/brackendev/haiku-macos-dev) repository covers macOS host setup: QEMU/UTM launcher configuration, NFS file sharing between macOS and Haiku, and SSH access.

When the repository is shared into the VM over NFS, Lisp source files (`*.lisp`, `*.scm`, `*.clj`) run correctly from the mount because interpreters load them as data. Compiled ELF binaries do not. Haiku's runtime loader cannot map ELF binaries from an NFS share. The binary exits with status 255 and no message. Build the C++ servers on the mount, then copy the binary to a local path before running it.

## References

- [McCLIM Manual](https://mcclim.common-lisp.dev/static/manual/mcclim.html)
- [McCLIM Backends Wiki](https://github.com/McCLIM/McCLIM/wiki/Backends)
- [cl-sdl2](https://github.com/lispgames/cl-sdl2)
- [SBCL Haiku Port Discussion](https://discuss.haiku-os.org/t/porting-sbcl-common-lisp-to-haiku/8928)
- [CLDK (SDL2 backend for McCLIM)](https://github.com/gas2serra/cldk)
- [Chicken SDL2 Egg](http://wiki.call-cc.org/eggref/5/sdl2)
- [Janet SDL2 Tutorial](https://github.com/ericnewton/janet-sdl2-tutorial)

## Related Projects

| Project | Description |
|---------|-------------|
| [HaikuClip](https://github.com/brackendev/HaikuClip) | Clipboard sync between Haiku and macOS |
| [haiku-control-mcp](https://github.com/brackendev/haiku-control-mcp) | MCP server for controlling Haiku |
| [haiku-macos-dev](https://github.com/brackendev/haiku-macos-dev) | macOS tools for running Haiku in QEMU |

## Trademarks

Haiku® and the HAIKU logo® are registered trademarks of [Haiku, Inc.](http://www.haiku-inc.org) and are developed by the [Haiku Project](http://www.haiku-os.org).

haiku-lisp-dev is an independent project. It is not affiliated with, endorsed, or sponsored by Haiku, Inc. or the Haiku Project.

## License

[MIT](LICENSE)
