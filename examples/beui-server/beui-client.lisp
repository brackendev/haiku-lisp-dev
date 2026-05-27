;;; beui-client.lisp - SBCL client for beui-server
;;;
;;; Prerequisites:
;;;   Build beui-server: make
;;;
;;; Run:
;;;   sbcl --load beui-client.lisp

;; Start beui-server process
(defvar *beui-process* nil)
(defvar *beui-input* nil)
(defvar *beui-output* nil)

(defun beui-start ()
  "Start the beui-server process."
  (let ((process (sb-ext:run-program "./beui-server"
                                      nil
                                      :input :stream
                                      :output :stream
                                      :wait nil)))
    (setf *beui-process* process
          *beui-input* (sb-ext:process-input process)
          *beui-output* (sb-ext:process-output process))))

(defun beui-send (cmd)
  "Send a command to beui-server."
  (write-line cmd *beui-input*)
  (force-output *beui-input*))

(defun beui-recv ()
  "Read a response from beui-server."
  (read-line *beui-output* nil nil))

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

;; Event handling
(defun parse-event (line)
  "Parse event line into (event-type id)."
  (let ((parts (uiop:split-string line)))
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

  ;; Wait for ready
  (format t "Server: ~a~%" (beui-recv))

  ;; Create UI
  (format t "~a~%" (beui-window "main" "Hello from SBCL!" 100 100 300 200))
  (format t "~a~%" (beui-label "lbl1" "main" "Click the button:" 20 20 200 20))
  (format t "~a~%" (beui-button "btn1" "main" "Click Me!" 20 50 100 30))
  (format t "~a~%" (beui-button "btn2" "main" "Quit" 20 90 100 30))
  (format t "~a~%" (beui-show "main"))

  ;; Event loop
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
