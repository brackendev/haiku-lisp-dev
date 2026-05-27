;;; Clojure Swing Example for Haiku
;;;
;;; Prerequisites:
;;;   pkgman install openjdk17 openjdk17_default
;;;
;;; Setup (first time):
;;;   mkdir -p ~/clojure-jars && cd ~/clojure-jars
;;;   curl -O https://repo1.maven.org/maven2/org/clojure/clojure/1.12.0/clojure-1.12.0.jar
;;;   curl -O https://repo1.maven.org/maven2/org/clojure/spec.alpha/0.5.238/spec.alpha-0.5.238.jar
;;;   curl -O https://repo1.maven.org/maven2/org/clojure/core.specs.alpha/0.4.74/core.specs.alpha-0.4.74.jar
;;;
;;; Run:
;;;   java -cp '/boot/home/clojure-jars/*' clojure.main swing-test.clj

(import '(javax.swing JFrame JPanel JButton SwingUtilities)
        '(java.awt Color Dimension BorderLayout)
        '(java.awt.event ActionListener))

(defn make-panel []
  (let [panel (proxy [JPanel] []
                (paintComponent [g]
                  (proxy-super paintComponent g)
                  (.setColor g (Color. 255 220 50))
                  (.fillRect g 50 50 300 150)))]
    (.setBackground panel (Color. 50 100 200))
    (.setPreferredSize panel (Dimension. 400 250))
    panel))

(defn make-quit-button []
  (let [btn (JButton. "Quit")]
    (.addActionListener btn
      (reify ActionListener
        (actionPerformed [_ _]
          (println "Button clicked!")
          (System/exit 0))))
    btn))

(SwingUtilities/invokeAndWait
  (fn []
    (let [frame (JFrame. "Clojure Swing on Haiku")]
      (.setLayout frame (BorderLayout.))
      (.add frame (make-panel) BorderLayout/CENTER)
      (.add frame (make-quit-button) BorderLayout/SOUTH)
      (.pack frame)
      (.setLocation frame 240 180)
      (.setDefaultCloseOperation frame JFrame/EXIT_ON_CLOSE)
      (.setVisible frame true))))
