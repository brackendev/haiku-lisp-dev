# chicken-sdl2

Chicken Scheme calls SDL2 through the `sdl2` egg. It opens a window, draws a yellow rectangle on a blue background, waits three seconds, and exits.

## Prerequisites

```bash
pkgman install chicken chicken_devel libsdl2 libsdl2_devel
```

Source the environment script and install the SDL2 egg once:

```bash
. ../../chicken-env.sh
chicken-install sdl2
```

`chicken-env.sh` sets `CHICKEN_REPOSITORY_PATH`, `CHICKEN_EGG_CACHE`, `CHICKEN_INSTALL_PREFIX`, and `C_INCLUDE_PATH` so `chicken-install` and `csi` find the right paths on Haiku. Source it in every shell that runs Chicken.

## Run

```bash
. ../../chicken-env.sh
csi -s sdl2-test.scm
```

## Architecture

```
Chicken <-> sdl2 egg (FFI) <-> libSDL2-2.0.so.0
```
