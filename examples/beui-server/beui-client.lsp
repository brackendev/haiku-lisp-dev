; beui-client.lsp - NewLISP client for beui-server
;
; Prerequisites:
;   Build beui-server: make
;   pkgman install newlisp
;
; Run:
;   newlisp beui-client.lsp

; NewLISP's `process` does fork+exec but leaves the child's pipe FDs open
; in the parent. The parent must close them explicitly or the child sees no
; EOF on stdin.

(define beui-in nil)   ; we read from this (server stdout)
(define beui-out nil)  ; we write to this (server stdin)

(define (beui-start)
  (let (in-pair (pipe) out-pair (pipe))
    (let (server-stdin (in-pair 0)
          our-write    (in-pair 1)
          our-read     (out-pair 0)
          server-stdout (out-pair 1))
      (process "./beui-server" server-stdin server-stdout)
      (close server-stdin)
      (close server-stdout)
      (set 'beui-out our-write 'beui-in our-read))))

(define (beui-send cmd)
  (write-line beui-out cmd))

(define (beui-recv)
  (read-line beui-in))

(define (beui-cmd cmd)
  (beui-send cmd)
  (beui-recv))

; High-level API
(define (beui-window id title x y w h)
  (beui-cmd (format "window %s \"%s\" %d %d %d %d" id title x y w h)))

(define (beui-button id parent label x y w h)
  (beui-cmd (format "button %s %s \"%s\" %d %d %d %d" id parent label x y w h)))

(define (beui-label id parent text x y w h)
  (beui-cmd (format "label %s %s \"%s\" %d %d %d %d" id parent text x y w h)))

(define (beui-show id) (beui-cmd (string "show " id)))
(define (beui-quit) (beui-cmd "quit"))

(define (parse-event line)
  (let (parts (parse line " "))
    (list (parts 0) (if (>= (length parts) 2) (parts 1) ""))))

(define (beui-event-loop handler)
  (let (line (beui-recv))
    (while line
      (let (ev (parse-event line))
        (handler (ev 0) (ev 1)))
      (set 'line (beui-recv)))))

; Demo application
(define (main)
  (println "Starting beui-server...")
  (beui-start)

  (println "Server: " (beui-recv))

  (println (beui-window "main" "Hello from NewLISP!" 100 100 300 200))
  (println (beui-label  "lbl1" "main" "Click the button:" 20 20 200 20))
  (println (beui-button "btn1" "main" "Click Me!" 20 50 100 30))
  (println (beui-button "btn2" "main" "Quit" 20 90 100 30))
  (println (beui-show   "main"))

  (println "Waiting for events...")
  (beui-event-loop
    (fn (event id)
      (cond
        ((= event "clicked")
         (println "Button clicked: " id)
         (if (= id "btn2") (beui-quit)))
        ((= event "closed")
         (println "Window closed: " id)
         (beui-quit))
        (true
         (println "Event: " event " " id))))))

(main)
(exit)
