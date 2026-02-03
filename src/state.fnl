(local c (require :src.core))

(local cfg {:scale 3
            :fps 32
            :screen {:w 360 :h 520}
            :window-title "Starship Shooters"
            :hud {:offset 8}})

(local init {:game-start {:ftl 32 :opacity 1 :display? true}
             :game-end {:display? false :opacity 0}
             :score 0
             :player {:start-lives 2
                      :lives 2
                      :start-x 172
                      :start-y 320
                      :x 172
                      :y 320
                      :abs-delta 8
                      :dx 0
                      :dy 0}
             :shots {:insts [] :dx 0 :dy -15}
             :enemies {:fish {:dt-since -1
                              :dt-bw 1
                              :dy 6
                              :max-cnt 5
                              :hp 1
                              :insts []}
                       :clam {:dt-since -5
                              :dt-bw 2
                              :dy 4
                              :max-cnt 3
                              :hp 2
                              :insts []}
                       :alien {:dt-since -10
                               :dt-bw 3
                               :dy 2
                               :max-cnt 1
                               :hp 5
                               :insts []}}
             :explosions {:insts []}
             :timers {}})

(local state {})

(fn reset-state
  []
  (c.run!
    (fn [k v]
      (set (. state k) (c.deep-copy v)))
    init))

{: cfg
 : state
 : reset-state}
