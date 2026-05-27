# qtui-client.janet - Janet client for qtui-server
#
# Prerequisites:
#   Build qtui-server: make
#
# Run:
#   janet qtui-client.janet

(var qtui-proc nil)

(defn qtui-start []
  (set qtui-proc (os/spawn ["./qtui-server"] :px {:in :pipe :out :pipe})))

(defn qtui-send [cmd]
  (:write (qtui-proc :in) (string cmd "\n")))

(defn qtui-recv []
  (def stream (qtui-proc :out))
  (def buf @"")
  (var done false)
  (while (not done)
    (def b (:read stream 1))
    (cond
      (nil? b) (set done true)
      (zero? (length b)) (set done true)
      (= (get b 0) 10) (set done true)
      (buffer/push-byte buf (get b 0))))
  (if (and (= (length buf) 0) done)
    nil
    (string buf)))

(defn qtui-cmd [cmd]
  (qtui-send cmd)
  (qtui-recv))

(defn qtui-window [id title w h]
  (qtui-cmd (string/format "window %s \"%s\" %d %d" id title w h)))

(defn qtui-button [id parent label]
  (qtui-cmd (string/format "button %s %s \"%s\"" id parent label)))

(defn qtui-label [id parent text]
  (qtui-cmd (string/format "label %s %s \"%s\"" id parent text)))

(defn qtui-input [id parent &opt placeholder]
  (if placeholder
      (qtui-cmd (string/format "input %s %s \"%s\"" id parent placeholder))
      (qtui-cmd (string/format "input %s %s" id parent))))

(defn qtui-checkbox [id parent label]
  (qtui-cmd (string/format "checkbox %s %s \"%s\"" id parent label)))

(defn qtui-hbox [id parent]
  (qtui-cmd (string/format "hbox %s %s" id parent)))

(defn qtui-show [id]
  (qtui-cmd (string "show " id)))

(defn qtui-quit []
  (qtui-cmd "quit"))

(defn parse-event [line]
  (def parts (string/split " " line))
  [(get parts 0) (or (get parts 1) "") (or (get parts 2) "")])

(defn qtui-event-loop [handler]
  (var line (qtui-recv))
  (while line
    (handler ;(parse-event line))
    (set line (qtui-recv))))

(defn main [&]
  (print "Starting qtui-server...")
  (qtui-start)

  (print "Server: " (qtui-recv))

  (print (qtui-window "main" "Hello from Janet!" 400 300))
  (print (qtui-label "lbl1" "main" "Enter your name:"))
  (print (qtui-input "name" "main" "Type here..."))
  (print (qtui-checkbox "chk1" "main" "Enable feature"))

  (print (qtui-hbox "buttons" "main"))
  (print (qtui-button "btn1" "buttons" "Greet"))
  (print (qtui-button "btn2" "buttons" "Quit"))

  (print (qtui-show "main"))

  (print "Waiting for events...")
  (qtui-event-loop
    (fn [event id value]
      (cond
        (= event "clicked")
        (do (print "Button clicked: " id)
            (when (= id "btn2") (qtui-quit)))

        (= event "changed")
        (print "Text changed in " id ": " value)

        (= event "checked")
        (print "Checkbox " id " is now " (if (= value "1") "checked" "unchecked"))

        (= event "closed")
        (do (print "Window closed: " id)
            (qtui-quit))

        (print "Event: " event " " id " " value)))))
