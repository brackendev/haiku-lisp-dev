;;; qtui-client.lisp - SBCL client for qtui-server
;;;
;;; Prerequisites:
;;;   Build qtui-server: make
;;;
;;; Run:
;;;   sbcl --load qtui-client.lisp

;; Start qtui-server process
(defvar *qtui-process* nil)
(defvar *qtui-input* nil)
(defvar *qtui-output* nil)

(defun qtui-start ()
  "Start the qtui-server process."
  (let ((process (sb-ext:run-program "./qtui-server"
                                      nil
                                      :input :stream
                                      :output :stream
                                      :wait nil)))
    (setf *qtui-process* process
          *qtui-input* (sb-ext:process-input process)
          *qtui-output* (sb-ext:process-output process))))

(defun qtui-send (cmd)
  "Send a command to qtui-server."
  (write-line cmd *qtui-input*)
  (force-output *qtui-input*))

(defun qtui-recv ()
  "Read a response from qtui-server."
  (read-line *qtui-output* nil nil))

(defun qtui-cmd (cmd)
  "Send command and return response."
  (qtui-send cmd)
  (qtui-recv))

;; High-level API
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

(defun qtui-vbox (id parent)
  (qtui-cmd (format nil "vbox ~a ~a" id parent)))

(defun qtui-show (id)
  (qtui-cmd (format nil "show ~a" id)))

(defun qtui-set (id prop value)
  (qtui-cmd (format nil "set ~a ~a \"~a\"" id prop value)))

(defun qtui-quit ()
  (qtui-cmd "quit"))

;; Event handling
(defun parse-event (line)
  "Parse event line into (event-type id value)."
  (let ((parts (uiop:split-string line)))
    (values (first parts) (second parts) (third parts))))

(defun qtui-event-loop (handler)
  "Read events and call handler with (event-type id value)."
  (loop for line = (qtui-recv)
        while line
        do (multiple-value-bind (event id value) (parse-event line)
             (funcall handler event id value))))

;;; Demo application
(defun main ()
  (format t "Starting qtui-server...~%")
  (qtui-start)

  ;; Wait for ready
  (format t "Server: ~a~%" (qtui-recv))

  ;; Create UI with layout
  (format t "~a~%" (qtui-window "main" "Hello from SBCL!" 400 300))
  (format t "~a~%" (qtui-label "lbl1" "main" "Enter your name:"))
  (format t "~a~%" (qtui-input "name" "main" "Type here..."))
  (format t "~a~%" (qtui-checkbox "chk1" "main" "Enable feature"))

  ;; Button row using hbox
  (format t "~a~%" (qtui-hbox "buttons" "main"))
  (format t "~a~%" (qtui-button "btn1" "buttons" "Greet"))
  (format t "~a~%" (qtui-button "btn2" "buttons" "Quit"))

  (format t "~a~%" (qtui-show "main"))

  ;; Event loop
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
