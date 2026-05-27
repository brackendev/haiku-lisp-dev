;;; SBCL SDL2 Example for Haiku (via CFFI)
;;;
;;; Prerequisites:
;;;   pkgman install sbcl libsdl2 libsdl2_devel
;;;
;;; Setup (first time):
;;;   curl -o /tmp/quicklisp.lisp https://beta.quicklisp.org/quicklisp.lisp
;;;   sbcl --load /tmp/quicklisp.lisp --eval '(quicklisp-quickstart:install)' --quit
;;;
;;; Run:
;;;   sbcl --load sdl2-test.lisp

(ql:quickload :cffi :silent t)

;;; SDL2 library definition
(cffi:define-foreign-library libsdl2
  (:haiku "libSDL2-2.0.so.0")
  (t (:default "SDL2")))

(cffi:use-foreign-library libsdl2)

;;; Function bindings
(cffi:defcfun ("SDL_Init" sdl-init) :int (flags :uint32))
(cffi:defcfun ("SDL_Quit" sdl-quit) :void)
(cffi:defcfun ("SDL_GetError" sdl-get-error) :string)
(cffi:defcfun ("SDL_CreateWindow" sdl-create-window) :pointer
  (title :string) (x :int) (y :int) (w :int) (h :int) (flags :uint32))
(cffi:defcfun ("SDL_DestroyWindow" sdl-destroy-window) :void (window :pointer))
(cffi:defcfun ("SDL_Delay" sdl-delay) :void (ms :uint32))
(cffi:defcfun ("SDL_CreateRenderer" sdl-create-renderer) :pointer
  (window :pointer) (index :int) (flags :uint32))
(cffi:defcfun ("SDL_DestroyRenderer" sdl-destroy-renderer) :void (renderer :pointer))
(cffi:defcfun ("SDL_SetRenderDrawColor" sdl-set-render-draw-color) :int
  (renderer :pointer) (r :uint8) (g :uint8) (b :uint8) (a :uint8))
(cffi:defcfun ("SDL_RenderClear" sdl-render-clear) :int (renderer :pointer))
(cffi:defcfun ("SDL_RenderPresent" sdl-render-present) :void (renderer :pointer))
(cffi:defcfun ("SDL_RenderFillRect" sdl-render-fill-rect) :int
  (renderer :pointer) (rect :pointer))

;;; Constants
(defconstant +sdl-init-video+ #x00000020)
(defconstant +sdl-windowpos-centered+ #x2FFF0000)

;;; Rectangle struct
(cffi:defcstruct sdl-rect
  (x :int) (y :int) (w :int) (h :int))

;;; Main
(when (zerop (sdl-init +sdl-init-video+))
  (let* ((window (sdl-create-window "SBCL SDL2 on Haiku"
                                    +sdl-windowpos-centered+
                                    +sdl-windowpos-centered+
                                    400 300 0))
         (renderer (sdl-create-renderer window -1 0)))
    ;; Blue background
    (sdl-set-render-draw-color renderer 50 100 200 255)
    (sdl-render-clear renderer)
    ;; Yellow rectangle
    (cffi:with-foreign-object (rect '(:struct sdl-rect))
      (setf (cffi:foreign-slot-value rect '(:struct sdl-rect) 'x) 50
            (cffi:foreign-slot-value rect '(:struct sdl-rect) 'y) 50
            (cffi:foreign-slot-value rect '(:struct sdl-rect) 'w) 300
            (cffi:foreign-slot-value rect '(:struct sdl-rect) 'h) 200)
      (sdl-set-render-draw-color renderer 255 220 50 255)
      (sdl-render-fill-rect renderer rect))
    (sdl-render-present renderer)
    (sdl-delay 3000)
    (sdl-destroy-renderer renderer)
    (sdl-destroy-window window))
  (sdl-quit))

(format t "Done!~%")
