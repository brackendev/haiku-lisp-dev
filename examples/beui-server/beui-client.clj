;;; beui-client.clj - Clojure client for beui-server
;;;
;;; Prerequisites:
;;;   Build beui-server: make
;;;   pkgman install openjdk17 openjdk17_default
;;;   See examples/clojure-swing/README.md for the Maven jar setup.
;;;
;;; Run:
;;;   java -cp '/boot/home/clojure-jars/*' clojure.main beui-client.clj

(import '(java.lang ProcessBuilder)
        '(java.io BufferedReader BufferedWriter InputStreamReader OutputStreamWriter))

(def proc (atom nil))
(def reader (atom nil))
(def writer (atom nil))

(defn beui-start []
  (let [pb (doto (ProcessBuilder. ["./beui-server"])
             (.redirectErrorStream false))
        p (.start pb)]
    (reset! proc p)
    (reset! reader (BufferedReader. (InputStreamReader. (.getInputStream p))))
    (reset! writer (BufferedWriter. (OutputStreamWriter. (.getOutputStream p))))))

(defn beui-send [cmd]
  (.write @writer cmd)
  (.newLine @writer)
  (.flush @writer))

(defn beui-recv []
  (.readLine @reader))

(defn beui-cmd [cmd]
  (beui-send cmd)
  (beui-recv))

(defn beui-window [id title x y w h]
  (beui-cmd (format "window %s \"%s\" %d %d %d %d" id title x y w h)))

(defn beui-button [id parent label x y w h]
  (beui-cmd (format "button %s %s \"%s\" %d %d %d %d" id parent label x y w h)))

(defn beui-label [id parent text x y w h]
  (beui-cmd (format "label %s %s \"%s\" %d %d %d %d" id parent text x y w h)))

(defn beui-show [id]
  (beui-cmd (str "show " id)))

(defn beui-quit []
  (beui-cmd "quit"))

(defn parse-event [line]
  (let [parts (.split line " " 2)]
    [(aget parts 0) (if (> (alength parts) 1) (aget parts 1) "")]))

(defn beui-event-loop [handler]
  (loop [line (beui-recv)]
    (when line
      (let [[event id] (parse-event line)]
        (handler event id))
      (recur (beui-recv)))))

(defn -main []
  (println "Starting beui-server...")
  (beui-start)

  (println "Server:" (beui-recv))

  (println (beui-window "main" "Hello from Clojure!" 100 100 300 200))
  (println (beui-label  "lbl1" "main" "Click the button:" 20 20 200 20))
  (println (beui-button "btn1" "main" "Click Me!" 20 50 100 30))
  (println (beui-button "btn2" "main" "Quit" 20 90 100 30))
  (println (beui-show   "main"))

  (println "Waiting for events...")
  (beui-event-loop
    (fn [event id]
      (cond
        (= event "clicked")
        (do (println "Button clicked:" id)
            (when (= id "btn2") (beui-quit)))

        (= event "closed")
        (do (println "Window closed:" id)
            (beui-quit))

        :else
        (println "Event:" event id)))))

(-main)
