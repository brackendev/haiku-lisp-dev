;;; qtui-client.clj - Clojure client for qtui-server
;;;
;;; Prerequisites:
;;;   Build qtui-server: make
;;;   pkgman install openjdk17 openjdk17_default
;;;   See examples/clojure-swing/README.md for the Maven jar setup.
;;;
;;; Run:
;;;   java -cp '/boot/home/clojure-jars/*' clojure.main qtui-client.clj

(import '(java.lang ProcessBuilder)
        '(java.io BufferedReader BufferedWriter InputStreamReader OutputStreamWriter))

(def proc (atom nil))
(def reader (atom nil))
(def writer (atom nil))

(defn qtui-start []
  (let [pb (doto (ProcessBuilder. ["./qtui-server"])
             (.redirectErrorStream false))
        p (.start pb)]
    (reset! proc p)
    (reset! reader (BufferedReader. (InputStreamReader. (.getInputStream p))))
    (reset! writer (BufferedWriter. (OutputStreamWriter. (.getOutputStream p))))))

(defn qtui-send [cmd]
  (.write @writer cmd)
  (.newLine @writer)
  (.flush @writer))

(defn qtui-recv []
  (.readLine @reader))

(defn qtui-cmd [cmd]
  (qtui-send cmd)
  (qtui-recv))

(defn qtui-window [id title w h]
  (qtui-cmd (format "window %s \"%s\" %d %d" id title w h)))

(defn qtui-button [id parent label]
  (qtui-cmd (format "button %s %s \"%s\"" id parent label)))

(defn qtui-label [id parent text]
  (qtui-cmd (format "label %s %s \"%s\"" id parent text)))

(defn qtui-input
  ([id parent] (qtui-cmd (format "input %s %s" id parent)))
  ([id parent placeholder]
   (qtui-cmd (format "input %s %s \"%s\"" id parent placeholder))))

(defn qtui-checkbox [id parent label]
  (qtui-cmd (format "checkbox %s %s \"%s\"" id parent label)))

(defn qtui-hbox [id parent]
  (qtui-cmd (format "hbox %s %s" id parent)))

(defn qtui-show [id]
  (qtui-cmd (str "show " id)))

(defn qtui-quit []
  (qtui-cmd "quit"))

(defn parse-event [line]
  (let [parts (.split line " " 3)]
    [(aget parts 0)
     (if (> (alength parts) 1) (aget parts 1) "")
     (if (> (alength parts) 2) (aget parts 2) "")]))

(defn qtui-event-loop [handler]
  (loop [line (qtui-recv)]
    (when line
      (let [[event id value] (parse-event line)]
        (handler event id value))
      (recur (qtui-recv)))))

(defn -main []
  (println "Starting qtui-server...")
  (qtui-start)

  (println "Server:" (qtui-recv))

  (println (qtui-window "main" "Hello from Clojure!" 400 300))
  (println (qtui-label "lbl1" "main" "Enter your name:"))
  (println (qtui-input "name" "main" "Type here..."))
  (println (qtui-checkbox "chk1" "main" "Enable feature"))

  (println (qtui-hbox "buttons" "main"))
  (println (qtui-button "btn1" "buttons" "Greet"))
  (println (qtui-button "btn2" "buttons" "Quit"))

  (println (qtui-show "main"))

  (println "Waiting for events...")
  (qtui-event-loop
    (fn [event id value]
      (cond
        (= event "clicked")
        (do (println "Button clicked:" id)
            (when (= id "btn2") (qtui-quit)))

        (= event "changed")
        (println "Text changed in" id ":" value)

        (= event "checked")
        (println "Checkbox" id "is now" (if (= value "1") "checked" "unchecked"))

        (= event "closed")
        (do (println "Window closed:" id)
            (qtui-quit))

        :else
        (println "Event:" event id value)))))

(-main)
