# beui-client.janet - Janet client for beui-server
#
# Prerequisites:
#   Build beui-server: make
#
# Run:
#   janet beui-client.janet

(var beui-proc nil)

(defn beui-start []
  "Start the beui-server process via os/spawn."
  (set beui-proc (os/spawn ["./beui-server"] :px {:in :pipe :out :pipe})))

(defn beui-send [cmd]
  "Send a command line to beui-server."
  (:write (beui-proc :in) (string cmd "\n")))

(defn beui-recv []
  "Read one line from beui-server's stdout, or nil on EOF."
  (def stream (beui-proc :out))
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

(defn beui-cmd [cmd]
  "Send command and return the response line."
  (beui-send cmd)
  (beui-recv))

# High-level API
(defn beui-window [id title x y w h]
  (beui-cmd (string/format "window %s \"%s\" %d %d %d %d" id title x y w h)))

(defn beui-button [id parent label x y w h]
  (beui-cmd (string/format "button %s %s \"%s\" %d %d %d %d" id parent label x y w h)))

(defn beui-label [id parent text x y w h]
  (beui-cmd (string/format "label %s %s \"%s\" %d %d %d %d" id parent text x y w h)))

(defn beui-show [id]
  (beui-cmd (string "show " id)))

(defn beui-quit []
  (beui-cmd "quit"))

(defn parse-event [line]
  "Split an event line into [event-type id]."
  (def parts (string/split " " line))
  [(get parts 0) (get parts 1)])

(defn beui-event-loop [handler]
  "Read events and call handler with [event-type id] until EOF."
  (var line (beui-recv))
  (while line
    (handler ;(parse-event line))
    (set line (beui-recv))))

# Demo application
(defn main [&]
  (print "Starting beui-server...")
  (beui-start)

  (print "Server: " (beui-recv))

  (print (beui-window "main" "Hello from Janet!" 100 100 300 200))
  (print (beui-label "lbl1" "main" "Click the button:" 20 20 200 20))
  (print (beui-button "btn1" "main" "Click Me!" 20 50 100 30))
  (print (beui-button "btn2" "main" "Quit" 20 90 100 30))
  (print (beui-show "main"))

  (print "Waiting for events...")
  (beui-event-loop
    (fn [event id]
      (cond
        (= event "clicked")
        (do (print "Button clicked: " id)
            (when (= id "btn2") (beui-quit)))

        (= event "closed")
        (do (print "Window closed: " id)
            (beui-quit))

        (print "Event: " event " " id)))))
