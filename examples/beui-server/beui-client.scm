;;; beui-client.scm - Chicken Scheme client for beui-server
;;;
;;; Prerequisites:
;;;   Build beui-server: make
;;;   Setup Chicken: . ../../chicken-env.sh
;;;
;;; Run:
;;;   csi -s beui-client.scm

(import (chicken process)
        (chicken io)
        (chicken string)
        (chicken port)
        (chicken format))

;; Start beui-server and return (input-port . output-port)
(define (beui-start)
  (let-values (((in out pid) (process "./beui-server")))
    (cons in out)))

;; Send command to server
(define (beui-send conn cmd)
  (display cmd (cdr conn))
  (newline (cdr conn))
  (flush-output (cdr conn)))

;; Read response from server
(define (beui-recv conn)
  (read-line (car conn)))

;; Send command and wait for response
(define (beui-cmd conn cmd)
  (beui-send conn cmd)
  (beui-recv conn))

;; High-level API
(define (beui-window conn id title x y w h)
  (beui-cmd conn (sprintf "window ~a \"~a\" ~a ~a ~a ~a" id title x y w h)))

(define (beui-button conn id parent label x y w h)
  (beui-cmd conn (sprintf "button ~a ~a \"~a\" ~a ~a ~a ~a" id parent label x y w h)))

(define (beui-label conn id parent text x y w h)
  (beui-cmd conn (sprintf "label ~a ~a \"~a\" ~a ~a ~a ~a" id parent text x y w h)))

(define (beui-show conn id)
  (beui-cmd conn (sprintf "show ~a" id)))

(define (beui-quit conn)
  (beui-cmd conn "quit"))

;; Event loop - call handler for each event
(define (beui-event-loop conn handler)
  (let loop ()
    (let ((line (beui-recv conn)))
      (unless (eof-object? line)
        (let ((parts (string-split line)))
          (when (pair? parts)
            (handler (car parts) (if (pair? (cdr parts)) (cadr parts) #f))))
        (loop)))))

;;; Demo application
(define (main)
  (print "Starting beui-server...")
  (let ((conn (beui-start)))

    ;; Wait for ready
    (let ((ready (beui-recv conn)))
      (print "Server: " ready))

    ;; Create UI
    (print (beui-window conn "main" "Hello from Chicken!" 100 100 300 200))
    (print (beui-label conn "lbl1" "main" "Click the button:" 20 20 200 20))
    (print (beui-button conn "btn1" "main" "Click Me!" 20 50 100 30))
    (print (beui-button conn "btn2" "main" "Quit" 20 90 100 30))
    (print (beui-show conn "main"))

    ;; Event loop
    (print "Waiting for events...")
    (beui-event-loop conn
      (lambda (event id)
        (cond
          ((string=? event "clicked")
           (print "Button clicked: " id)
           (when (string=? id "btn2")
             (beui-quit conn)))
          ((string=? event "closed")
           (print "Window closed: " id)
           (beui-quit conn))
          (else
           (print "Event: " event " " id)))))))

(main)
