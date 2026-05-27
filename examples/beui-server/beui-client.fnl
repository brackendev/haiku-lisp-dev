;; beui-client.fnl - Fennel client for beui-server
;;
;; Prerequisites:
;;   Build beui-server: make
;;   pkgman install fennel
;;
;; Run:
;;   fennel beui-client.fnl

;; Lua's io.popen is unidirectional, so this client bridges beui-server's
;; stdin/stdout through two FIFOs. The server runs in the background reading
;; from /tmp/beui-cmd and writing to /tmp/beui-evt.

(local cmd-fifo "/tmp/beui-cmd")
(local evt-fifo "/tmp/beui-evt")

(var beui-out nil)
(var beui-in nil)

(fn beui-start []
  (os.execute (.. "rm -f " cmd-fifo " " evt-fifo
                  " && mkfifo " cmd-fifo " " evt-fifo))
  (os.execute (.. "./beui-server <" cmd-fifo " >" evt-fifo " &"))
  ;; Open the writer first. The server is blocked opening cmd-fifo for read,
  ;; so opening it for write unblocks the server, which then opens evt-fifo
  ;; for write, which unblocks our open for read.
  (set beui-out (assert (io.open cmd-fifo "w")))
  (set beui-in  (assert (io.open evt-fifo "r"))))

(fn beui-send [cmd]
  (beui-out:write cmd "\n")
  (beui-out:flush))

(fn beui-recv []
  (beui-in:read "*l"))

(fn beui-cmd [cmd]
  (beui-send cmd)
  (beui-recv))

;; High-level API
(fn beui-window [id title x y w h]
  (beui-cmd (string.format "window %s \"%s\" %d %d %d %d" id title x y w h)))

(fn beui-button [id parent label x y w h]
  (beui-cmd (string.format "button %s %s \"%s\" %d %d %d %d" id parent label x y w h)))

(fn beui-label [id parent text x y w h]
  (beui-cmd (string.format "label %s %s \"%s\" %d %d %d %d" id parent text x y w h)))

(fn beui-show [id] (beui-cmd (.. "show " id)))
(fn beui-quit [] (beui-cmd "quit"))

(fn parse-event [line]
  (let [space (line:find " ")
        event (if space (line:sub 1 (- space 1)) line)
        id    (if space (line:sub (+ space 1)) "")]
    (values event id)))

(fn beui-event-loop [handler]
  (var line (beui-recv))
  (while line
    (let [(event id) (parse-event line)]
      (handler event id))
    (set line (beui-recv))))

;; Demo application
(fn main []
  (print "Starting beui-server...")
  (beui-start)

  (print (.. "Server: " (beui-recv)))

  (print (beui-window "main" "Hello from Fennel!" 100 100 300 200))
  (print (beui-label  "lbl1" "main" "Click the button:" 20 20 200 20))
  (print (beui-button "btn1" "main" "Click Me!" 20 50 100 30))
  (print (beui-button "btn2" "main" "Quit" 20 90 100 30))
  (print (beui-show   "main"))

  (print "Waiting for events...")
  (beui-event-loop
    (fn [event id]
      (if (= event "clicked")
          (do (print (.. "Button clicked: " id))
              (when (= id "btn2") (beui-quit)))
          (= event "closed")
          (do (print (.. "Window closed: " id))
              (beui-quit))
          (print (.. "Event: " event " " id))))))

(main)
