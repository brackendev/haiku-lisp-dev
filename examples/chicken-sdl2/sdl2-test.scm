;;; Chicken SDL2 Example for Haiku
;;;
;;; Prerequisites:
;;;   pkgman install chicken chicken_devel libsdl2 libsdl2_devel
;;;
;;; Setup (first time):
;;;   . ../../chicken-env.sh
;;;   chicken-install sdl2
;;;
;;; Run:
;;;   . ../../chicken-env.sh
;;;   csi -s sdl2-test.scm

(import (sdl2))

;; Initialize SDL2
(init! '(video))

;; Create window
(define win (create-window! "Chicken SDL2 on Haiku"
                            'centered 'centered
                            400 300 '()))

;; Create renderer
(define ren (create-renderer! win))

;; Blue background
(render-draw-color-set! ren '(50 100 200 255))
(render-clear! ren)

;; Yellow rectangle
(render-draw-color-set! ren '(255 220 50 255))
(render-fill-rect! ren (make-rect 50 50 300 200))

;; Show the result
(render-present! ren)

;; Wait 3 seconds
(delay! 3000)

;; Cleanup
(destroy-renderer! ren)
(destroy-window! win)
(quit!)

(print "Done!")
