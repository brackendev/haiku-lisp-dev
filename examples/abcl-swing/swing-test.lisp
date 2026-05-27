;;; ABCL Swing Example for Haiku
;;;
;;; Prerequisites:
;;;   pkgman install openjdk17 openjdk17_default abcl
;;;
;;; Run:
;;;   abcl --batch --load swing-test.lisp

(require :java)

(defun make-quit-button ()
  (let ((btn (jnew "javax.swing.JButton" "Quit"))
        (listener (java:jinterface-implementation
                   "java.awt.event.ActionListener"
                   "actionPerformed"
                   (lambda (event)
                     (declare (ignore event))
                     (format t "Button clicked!~%")
                     (force-output)
                     (jstatic "exit" "java.lang.System" 0)))))
    (jcall "addActionListener" btn listener)
    btn))

(defun make-panel ()
  ;; setLayout(null) lets us position the yellow inner panel with setBounds.
  (let ((panel (jnew "javax.swing.JPanel"))
        (yellow (jnew "javax.swing.JPanel")))
    (jcall "setLayout" panel java:+null+)
    (jcall "setBackground" panel (jnew "java.awt.Color" 50 100 200))
    (jcall "setPreferredSize" panel (jnew "java.awt.Dimension" 400 250))
    (jcall "setBackground" yellow (jnew "java.awt.Color" 255 220 50))
    (jcall "setBounds" yellow 50 50 300 150)
    (jcall "add" panel yellow)
    panel))

(defun show-frame ()
  (let ((frame (jnew "javax.swing.JFrame" "ABCL Swing on Haiku"))
        (border-layout (jnew "java.awt.BorderLayout")))
    (jcall "setLayout" frame border-layout)
    (jcall "add" frame (make-panel) (jfield "java.awt.BorderLayout" "CENTER"))
    (jcall "add" frame (make-quit-button) (jfield "java.awt.BorderLayout" "SOUTH"))
    (jcall "pack" frame)
    (jcall "setLocation" frame 240 180)
    (jcall "setDefaultCloseOperation" frame
           (jfield "javax.swing.JFrame" "EXIT_ON_CLOSE"))
    (jcall "setVisible" frame java:+true+)
    frame))

(jstatic "invokeAndWait" "javax.swing.SwingUtilities"
         (java:jinterface-implementation
          "java.lang.Runnable"
          "run" (lambda () (show-frame))))

;; --batch exits the JVM when the script ends, which would terminate AWT.
;; Block the main thread. The AWT thread keeps running until the window
;; is closed or the Quit button calls System.exit.
(loop (sleep 60))
