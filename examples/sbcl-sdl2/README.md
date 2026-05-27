# sbcl-sdl2

SBCL calls SDL2 directly through CFFI. It opens a window, draws a yellow rectangle on a blue background, waits three seconds, and exits.

## Prerequisites

```bash
pkgman install sbcl libsdl2 libsdl2_devel
```

Quicklisp provides CFFI. Install it once:

```bash
curl -o /tmp/quicklisp.lisp https://beta.quicklisp.org/quicklisp.lisp
sbcl --load /tmp/quicklisp.lisp --eval '(quicklisp-quickstart:install)' --quit
```

## Run

```bash
sbcl --load sdl2-test.lisp
```

The line `Missing required foreign symbol 'os_context_fp_addr'` prints during startup. It comes from SBCL's CFFI initialization on Haiku and does not affect the example.

## How it works

`sdl2-test.lisp` declares the SDL2 library by its Haiku soname (`libSDL2-2.0.so.0`), binds the SDL_* functions it needs through `cffi:defcfun`, and drives the renderer directly. It does not use a high-level Lisp wrapper.

## Architecture

```
SBCL <-> CFFI <-> libSDL2-2.0.so.0
```
