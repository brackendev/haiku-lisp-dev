;; qtui-client.fnl - Fennel client for qtui-server
;;
;; Prerequisites:
;;   Build qtui-server: make
;;   pkgman install fennel
;;
;; Run:
;;   fennel qtui-client.fnl
;;
;; Lua's io.popen is unidirectional, so this client bridges qtui-server's
;; stdin/stdout through two FIFOs.

(local cmd-fifo "/tmp/qtui-cmd")
(local evt-fifo "/tmp/qtui-evt")

(var qtui-out nil)
(var qtui-in nil)

(fn qtui-start []
  (os.execute (.. "rm -f " cmd-fifo " " evt-fifo
                  " && mkfifo " cmd-fifo " " evt-fifo))
  (os.execute (.. "./qtui-server <" cmd-fifo " >" evt-fifo " &"))
  (set qtui-out (assert (io.open cmd-fifo "w")))
  (set qtui-in  (assert (io.open evt-fifo "r"))))

(fn qtui-send [cmd]
  (qtui-out:write cmd "\n")
  (qtui-out:flush))

(fn qtui-recv []
  (qtui-in:read "*l"))

(fn qtui-cmd [cmd]
  (qtui-send cmd)
  (qtui-recv))

(fn qtui-window [id title w h]
  (qtui-cmd (string.format "window %s \"%s\" %d %d" id title w h)))

(fn qtui-button [id parent label]
  (qtui-cmd (string.format "button %s %s \"%s\"" id parent label)))

(fn qtui-label [id parent text]
  (qtui-cmd (string.format "label %s %s \"%s\"" id parent text)))

(fn qtui-input [id parent placeholder]
  (if placeholder
      (qtui-cmd (string.format "input %s %s \"%s\"" id parent placeholder))
      (qtui-cmd (string.format "input %s %s" id parent))))

(fn qtui-checkbox [id parent label]
  (qtui-cmd (string.format "checkbox %s %s \"%s\"" id parent label)))

(fn qtui-hbox [id parent]
  (qtui-cmd (string.format "hbox %s %s" id parent)))

(fn qtui-show [id] (qtui-cmd (.. "show " id)))
(fn qtui-quit [] (qtui-cmd "quit"))

(fn parse-event [line]
  (let [s1 (line:find " ")
        event (if s1 (line:sub 1 (- s1 1)) line)
        rest  (if s1 (line:sub (+ s1 1)) "")
        s2 (rest:find " ")
        id   (if s2 (rest:sub 1 (- s2 1)) rest)
        value (if s2 (rest:sub (+ s2 1)) "")]
    (values event id value)))

(fn qtui-event-loop [handler]
  (var line (qtui-recv))
  (while line
    (let [(event id value) (parse-event line)]
      (handler event id value))
    (set line (qtui-recv))))

(fn main []
  (print "Starting qtui-server...")
  (qtui-start)

  (print (.. "Server: " (qtui-recv)))

  (print (qtui-window "main" "Hello from Fennel!" 400 300))
  (print (qtui-label  "lbl1" "main" "Enter your name:"))
  (print (qtui-input  "name" "main" "Type here..."))
  (print (qtui-checkbox "chk1" "main" "Enable feature"))

  (print (qtui-hbox "buttons" "main"))
  (print (qtui-button "btn1" "buttons" "Greet"))
  (print (qtui-button "btn2" "buttons" "Quit"))

  (print (qtui-show "main"))

  (print "Waiting for events...")
  (qtui-event-loop
    (fn [event id value]
      (if (= event "clicked")
          (do (print (.. "Button clicked: " id))
              (when (= id "btn2") (qtui-quit)))
          (= event "changed")
          (print (.. "Text changed in " id ": " value))
          (= event "checked")
          (print (.. "Checkbox " id " is now " (if (= value "1") "checked" "unchecked")))
          (= event "closed")
          (do (print (.. "Window closed: " id))
              (qtui-quit))
          (print (.. "Event: " event " " id " " value))))))

(main)
