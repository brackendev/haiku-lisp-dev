;;; qtui-client.abcl.lisp - ABCL client for qtui-server
;;;
;;; Prerequisites:
;;;   Build qtui-server: make
;;;   ABCL on Haiku needs the :unix feature shim. The script applies it inline,
;;;   so it runs on a fresh ABCL install. See ../../README.md "ABCL" for background.
;;;
;;; Run:
;;;   abcl --batch --load qtui-client.abcl.lisp

(pushnew :unix *features*)

(require :asdf)
(let ((init (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file init) (load init)))

(defvar *qtui-process* nil)
(defvar *qtui-input* nil)
(defvar *qtui-output* nil)

(defun qtui-start ()
  (let ((process (uiop:launch-program "./qtui-server"
                                       :input :stream
                                       :output :stream)))
    (setf *qtui-process* process
          *qtui-input* (uiop:process-info-input process)
          *qtui-output* (uiop:process-info-output process))))

(defun qtui-send (cmd)
  (write-line cmd *qtui-input*)
  (force-output *qtui-input*))

(defun qtui-recv ()
  (read-line *qtui-output* nil nil))

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

(defun parse-event (line)
  (let ((parts (uiop:split-string line)))
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

  (format t "~a~%" (qtui-window "main" "Hello from ABCL!" 400 300))
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
