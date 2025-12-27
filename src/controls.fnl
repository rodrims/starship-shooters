(local player-deltas
       {:abs-delta 8
        :dx 0
        :dy 0})

; this is the middle of the screen for the default resolution of 480x640 
(local player-coords
       {:x 240
        :y 320})

(local shot-deltas
       {:abs-delta 12
        :dx 0
        :dy -12})

(local shots
     {:coords []})

(fn update-delta
  [base name positive? press?]
  (set (. base name)
       (+ (. base name)
          (* (. base :abs-delta)
             (if press? 1 -1)
             (if positive? 1 -1)))))

(fn spawn-shot
  [player-x player-y]
  (table.insert shots.coords {:x player-x :y player-y}))

(fn handle-key
  [k press?]
  (case k
    :up (update-delta player-deltas :dy false press?)
    :down (update-delta player-deltas :dy true press?)
    :left (update-delta player-deltas :dx false press?)
    :right (update-delta player-deltas :dx true press?)
    :space (when press? (spawn-shot player-coords.x player-coords.y))
    :q (love.event.quit)))

{: player-deltas
 : player-coords
 : shot-deltas
 : shots
 : handle-key}
