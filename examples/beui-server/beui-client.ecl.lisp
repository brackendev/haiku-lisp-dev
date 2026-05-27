;;; beui-client.ecl.lisp - ECL client for beui-server
;;;
;;; Prerequisites:
;;;   Build beui-server: make
;;;
;;; Run:
;;;   ecl --norc -load beui-client.ecl.lisp

;; ECL ships ASDF/uiop, but uiop classifies Haiku as a separate OS rather than
;; a unix variant, so uiop:launch-program errors with an ETYPECASE failure on
;; "/bin/cat". ext:run-program works directly without ASDF and gives us
;; bidirectional pipes to the child.

(defvar *beui-stream* nil)

(defun beui-start ()
  "Start the beui-server process and store its bidirectional stream."
  (setf *beui-stream*
        (ext:run-program "./beui-server" '()
                         :input :stream
                         :output :stream
                         :wait nil)))

(defun beui-send (cmd)
  "Send a command to beui-server."
  (write-line cmd *beui-stream*)
  (force-output *beui-stream*))

(defun beui-recv ()
  "Read a response line from beui-server, or NIL on EOF."
  (read-line *beui-stream* nil nil))

(defun beui-cmd (cmd)
  "Send command and return response."
  (beui-send cmd)
  (beui-recv))

;; High-level API
(defun beui-window (id title x y w h)
  (beui-cmd (format nil "window ~a \"~a\" ~a ~a ~a ~a" id title x y w h)))

(defun beui-button (id parent label x y w h)
  (beui-cmd (format nil "button ~a ~a \"~a\" ~a ~a ~a ~a" id parent label x y w h)))

(defun beui-label (id parent text x y w h)
  (beui-cmd (format nil "label ~a ~a \"~a\" ~a ~a ~a ~a" id parent text x y w h)))

(defun beui-show (id)
  (beui-cmd (format nil "show ~a" id)))

(defun beui-quit ()
  (beui-cmd "quit"))

(defun split-on-space (s)
  (loop with len = (length s)
        for start = 0 then (1+ end)
        for end = (position #\Space s :start start)
        while end
        collect (subseq s start end) into parts
        finally (return (if (< start len)
                            (append parts (list (subseq s start)))
                            parts))))

(defun parse-event (line)
  "Parse event line into (event-type id)."
  (let ((parts (split-on-space line)))
    (values (first parts) (second parts))))

(defun beui-event-loop (handler)
  "Read events and call handler with (event-type id)."
  (loop for line = (beui-recv)
        while line
        do (multiple-value-bind (event id) (parse-event line)
             (funcall handler event id))))

;;; Demo application
(defun main ()
  (format t "Starting beui-server...~%")
  (beui-start)

  (format t "Server: ~a~%" (beui-recv))

  (format t "~a~%" (beui-window "main" "Hello from ECL!" 100 100 300 200))
  (format t "~a~%" (beui-label "lbl1" "main" "Click the button:" 20 20 200 20))
  (format t "~a~%" (beui-button "btn1" "main" "Click Me!" 20 50 100 30))
  (format t "~a~%" (beui-button "btn2" "main" "Quit" 20 90 100 30))
  (format t "~a~%" (beui-show "main"))

  (format t "Waiting for events...~%")
  (beui-event-loop
   (lambda (event id)
     (cond
       ((string= event "clicked")
        (format t "Button clicked: ~a~%" id)
        (when (string= id "btn2")
          (beui-quit)))
       ((string= event "closed")
        (format t "Window closed: ~a~%" id)
        (beui-quit))
       (t
        (format t "Event: ~a ~a~%" event id))))))

(main)
