;;; qtui-client.ecl.lisp - ECL client for qtui-server
;;;
;;; Prerequisites:
;;;   Build qtui-server: make
;;;
;;; Run:
;;;   ecl --norc -load qtui-client.ecl.lisp
;;;
;;; ECL ships ASDF/uiop, but uiop classifies Haiku as a separate OS rather than
;;; a unix variant, so uiop:launch-program errors. ext:run-program works directly.

(defvar *qtui-stream* nil)

(defun qtui-start ()
  (setf *qtui-stream*
        (ext:run-program "./qtui-server" '()
                         :input :stream
                         :output :stream
                         :wait nil)))

(defun qtui-send (cmd)
  (write-line cmd *qtui-stream*)
  (force-output *qtui-stream*))

(defun qtui-recv ()
  (read-line *qtui-stream* nil nil))

(defun qtui-cmd (cmd)
  (qtui-send cmd)
  (qtui-recv))

(defun qtui-window (id title w h)
  (qtui-cmd (format nil "window ~a \"~a\" ~a ~a" id title w h)))

(defun qtui-button (id parent label)
  (qtui-cmd (format nil "button ~a ~a \"~a\"" id parent label)))

(defun qtui-label (id parent text)
  (qtui-cmd (format nil "label ~a ~a \"~a\"" id parent text)))

(defun qtui-input (id parent &optional placeholder)
  (if placeholder
      (qtui-cmd (format nil "input ~a ~a \"~a\"" id parent placeholder))
      (qtui-cmd (format nil "input ~a ~a" id parent))))

(defun qtui-checkbox (id parent label)
  (qtui-cmd (format nil "checkbox ~a ~a \"~a\"" id parent label)))

(defun qtui-hbox (id parent)
  (qtui-cmd (format nil "hbox ~a ~a" id parent)))

(defun qtui-show (id)
  (qtui-cmd (format nil "show ~a" id)))

(defun qtui-quit ()
  (qtui-cmd "quit"))

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
  (let ((parts (split-on-space line)))
    (values (first parts) (second parts) (third parts))))

(defun qtui-event-loop (handler)
  (loop for line = (qtui-recv)
        while line
        do (multiple-value-bind (event id value) (parse-event line)
             (funcall handler event id value))))

(defun main ()
  (format t "Starting qtui-server...~%")
  (qtui-start)

  (format t "Server: ~a~%" (qtui-recv))

  (format t "~a~%" (qtui-window "main" "Hello from ECL!" 400 300))
  (format t "~a~%" (qtui-label "lbl1" "main" "Enter your name:"))
  (format t "~a~%" (qtui-input "name" "main" "Type here..."))
  (format t "~a~%" (qtui-checkbox "chk1" "main" "Enable feature"))

  (format t "~a~%" (qtui-hbox "buttons" "main"))
  (format t "~a~%" (qtui-button "btn1" "buttons" "Greet"))
  (format t "~a~%" (qtui-button "btn2" "buttons" "Quit"))

  (format t "~a~%" (qtui-show "main"))

  (format t "Waiting for events...~%")
  (qtui-event-loop
   (lambda (event id value)
     (cond
       ((string= event "clicked")
        (format t "Button clicked: ~a~%" id)
        (when (string= id "btn2")
          (qtui-quit)))
       ((string= event "changed")
        (format t "Text changed in ~a: ~a~%" id value))
       ((string= event "checked")
        (format t "Checkbox ~a is now ~a~%" id (if (string= value "1") "checked" "unchecked")))
       ((string= event "closed")
        (format t "Window closed: ~a~%" id)
        (qtui-quit))
       (t
        (format t "Event: ~a ~a ~a~%" event id value))))))

(main)
