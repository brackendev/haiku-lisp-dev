; qtui-client.lsp - NewLISP client for qtui-server
;
; Prerequisites:
;   Build qtui-server: make
;   pkgman install newlisp
;
; Run:
;   newlisp qtui-client.lsp

(define qtui-in nil)
(define qtui-out nil)

(define (qtui-start)
  (let (in-pair (pipe) out-pair (pipe))
    (let (server-stdin (in-pair 0)
          our-write    (in-pair 1)
          our-read     (out-pair 0)
          server-stdout (out-pair 1))
      (process "./qtui-server" server-stdin server-stdout)
      (close server-stdin)
      (close server-stdout)
      (set 'qtui-out our-write 'qtui-in our-read))))

(define (qtui-send cmd)
  (write-line qtui-out cmd))

(define (qtui-recv)
  (read-line qtui-in))

(define (qtui-cmd cmd)
  (qtui-send cmd)
  (qtui-recv))

(define (qtui-window id title w h)
  (qtui-cmd (format "window %s \"%s\" %d %d" id title w h)))

(define (qtui-button id parent label)
  (qtui-cmd (format "button %s %s \"%s\"" id parent label)))

(define (qtui-label id parent text)
  (qtui-cmd (format "label %s %s \"%s\"" id parent text)))

(define (qtui-input id parent placeholder)
  (if placeholder
      (qtui-cmd (format "input %s %s \"%s\"" id parent placeholder))
      (qtui-cmd (format "input %s %s" id parent))))

(define (qtui-checkbox id parent label)
  (qtui-cmd (format "checkbox %s %s \"%s\"" id parent label)))

(define (qtui-hbox id parent)
  (qtui-cmd (format "hbox %s %s" id parent)))

(define (qtui-show id) (qtui-cmd (string "show " id)))
(define (qtui-quit) (qtui-cmd "quit"))

(define (parse-event line)
  (let (parts (parse line " "))
    (list (parts 0)
          (if (>= (length parts) 2) (parts 1) "")
          (if (>= (length parts) 3) (parts 2) ""))))

(define (qtui-event-loop handler)
  (let (line (qtui-recv))
    (while line
      (let (ev (parse-event line))
        (handler (ev 0) (ev 1) (ev 2)))
      (set 'line (qtui-recv)))))

(define (main)
  (println "Starting qtui-server...")
  (qtui-start)

  (println "Server: " (qtui-recv))

  (println (qtui-window "main" "Hello from NewLISP!" 400 300))
  (println (qtui-label  "lbl1" "main" "Enter your name:"))
  (println (qtui-input  "name" "main" "Type here..."))
  (println (qtui-checkbox "chk1" "main" "Enable feature"))

  (println (qtui-hbox "buttons" "main"))
  (println (qtui-button "btn1" "buttons" "Greet"))
  (println (qtui-button "btn2" "buttons" "Quit"))

  (println (qtui-show "main"))

  (println "Waiting for events...")
  (qtui-event-loop
    (fn (event id value)
      (cond
        ((= event "clicked")
         (println "Button clicked: " id)
         (if (= id "btn2") (qtui-quit)))
        ((= event "changed")
         (println "Text changed in " id ": " value))
        ((= event "checked")
         (println "Checkbox " id " is now " (if (= value "1") "checked" "unchecked")))
        ((= event "closed")
         (println "Window closed: " id)
         (qtui-quit))
        (true
         (println "Event: " event " " id " " value))))))

(main)
(exit)
