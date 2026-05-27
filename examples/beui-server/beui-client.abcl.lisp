;;; beui-client.abcl.lisp - ABCL client for beui-server
;;;
;;; Prerequisites:
;;;   Build beui-server: make
;;;   ABCL on Haiku needs the :unix feature shim. The script applies it inline,
;;;   so it runs on a fresh ABCL install. Setting it permanently in ~/.abclrc
;;;   lets every ABCL session load ASDF/Quicklisp without the inline form.
;;;   See ../../README.md "ABCL" for background.
;;;
;;; Run:
;;;   abcl --batch --load beui-client.abcl.lisp

;; ABCL on Haiku does not push :unix onto *features*, so ASDF/uiop refuses to
;; load with "neither Unix, nor Windows, nor Genera, nor even old MacOS". Apply
;; the shim before any ASDF-related form.
(pushnew :unix *features*)

;; ABCL ships ASDF/uiop. Loading Quicklisp is optional for this script. The
;; presence check below makes both paths work.
(require :asdf)
(let ((init (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file init) (load init)))

(defvar *beui-process* nil)
(defvar *beui-input* nil)
(defvar *beui-output* nil)

(defun beui-start ()
  "Start the beui-server process via uiop:launch-program."
  (let ((process (uiop:launch-program "./beui-server"
                                       :input :stream
                                       :output :stream)))
    (setf *beui-process* process
          *beui-input* (uiop:process-info-input process)
          *beui-output* (uiop:process-info-output process))))

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

  (format t "Server: ~a~%" (beui-recv))

  (format t "~a~%" (beui-window "main" "Hello from ABCL!" 100 100 300 200))
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
