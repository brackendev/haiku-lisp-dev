;;; qtui-client.scm - Chicken client for qtui-server
;;;
;;; Prerequisites:
;;;   Build qtui-server: make
;;;   Source environment: . ../../chicken-env.sh
;;;
;;; Run:
;;;   csi -s qtui-client.scm

(import (chicken process)
        (chicken io)
        (chicken string)
        (chicken port)
        (chicken format))

;; Start qtui-server process
(define-values (qtui-in qtui-out qtui-pid)
  (process "./qtui-server"))

(define (qtui-send cmd)
  "Send a command to qtui-server."
  (display cmd qtui-out)
  (newline qtui-out)
  (flush-output qtui-out))

(define (qtui-recv)
  "Read a response from qtui-server."
  (read-line qtui-in))

(define (qtui-cmd cmd)
  "Send command and return response."
  (qtui-send cmd)
  (qtui-recv))

;; High-level API
(define (qtui-window id title w h)
  (qtui-cmd (sprintf "window ~a \"~a\" ~a ~a" id title w h)))

(define (qtui-button id parent label)
  (qtui-cmd (sprintf "button ~a ~a \"~a\"" id parent label)))

(define (qtui-label id parent text)
  (qtui-cmd (sprintf "label ~a ~a \"~a\"" id parent text)))

(define (qtui-input id parent . placeholder)
  (if (null? placeholder)
      (qtui-cmd (sprintf "input ~a ~a" id parent))
      (qtui-cmd (sprintf "input ~a ~a \"~a\"" id parent (car placeholder)))))

(define (qtui-checkbox id parent label)
  (qtui-cmd (sprintf "checkbox ~a ~a \"~a\"" id parent label)))

(define (qtui-hbox id parent)
  (qtui-cmd (sprintf "hbox ~a ~a" id parent)))

(define (qtui-vbox id parent)
  (qtui-cmd (sprintf "vbox ~a ~a" id parent)))

(define (qtui-show id)
  (qtui-cmd (sprintf "show ~a" id)))

(define (qtui-set id prop value)
  (qtui-cmd (sprintf "set ~a ~a \"~a\"" id prop value)))

(define (qtui-quit)
  (qtui-cmd "quit"))

;; Event handling
(define (parse-event line)
  "Parse event line into (event-type id value)."
  (let ((parts (string-split line)))
    (values (car parts)
            (if (> (length parts) 1) (cadr parts) #f)
            (if (> (length parts) 2) (caddr parts) #f))))

(define (qtui-event-loop handler)
  "Read events and call handler with (event-type id value)."
  (let loop ()
    (let ((line (qtui-recv)))
      (unless (eof-object? line)
        (call-with-values (lambda () (parse-event line))
          handler)
        (loop)))))

;;; Demo application
(define (main)
  (print "Starting qtui-server...")

  ;; Wait for ready
  (print "Server: " (qtui-recv))

  ;; Create UI with layout
  (print (qtui-window "main" "Hello from Chicken!" 400 300))
  (print (qtui-label "lbl1" "main" "Enter your name:"))
  (print (qtui-input "name" "main" "Type here..."))
  (print (qtui-checkbox "chk1" "main" "Enable feature"))

  ;; Button row using hbox
  (print (qtui-hbox "buttons" "main"))
  (print (qtui-button "btn1" "buttons" "Greet"))
  (print (qtui-button "btn2" "buttons" "Quit"))

  (print (qtui-show "main"))

  ;; Event loop
  (print "Waiting for events...")
  (qtui-event-loop
   (lambda (event id value)
     (cond
       ((string=? event "clicked")
        (print "Button clicked: " id)
        (when (string=? id "btn2")
          (qtui-quit)))
       ((string=? event "changed")
        (print "Text changed in " id ": " value))
       ((string=? event "checked")
        (print "Checkbox " id " is now " (if (string=? value "1") "checked" "unchecked")))
       ((string=? event "closed")
        (print "Window closed: " id)
        (qtui-quit))
       (else
        (print "Event: " event " " id " " value))))))

(main)
