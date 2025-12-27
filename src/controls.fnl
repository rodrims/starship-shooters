(local draw (require "src/draw.fnl"))

(local player-deltas
       {:abs-delta 8
        :dx 0
        :dy 0})

; this is the middle of the screen for the default resolution of 480x640 
(local player-coords
       {:x 240
        :y 320})

(local shot-deltas
       {:abs-delta 15
        :dx 0
        :dy -15})

(local shots
       {:coords []})

(local enemies
       {:dt-since-fish 0
        :dt-bw-fish 1
        :dy-fish 6
        :max-fish 5
        :fish []})

(local explosions
       {:coords []})

(fn update-delta
  [base name positive? press?]
  (set (. base name)
       (+ (. base name)
          (* (. base :abs-delta)
             (if press? 1 -1)
             (if positive? 1 -1)))))

(fn update-player
  [screen-w screen-h]
  (let [new-x (+ player-coords.x player-deltas.dx)]
    (when (and (< 0 new-x) (< (+ new-x 16) screen-w))
      (set player-coords.x new-x)))
  (let [new-y (+ player-coords.y player-deltas.dy)]
    (when (and (< 0 new-y) (< (+ new-y 16) screen-h))
      (set player-coords.y new-y))))

(fn spawn-shot
  [player-x player-y]
  (when (< (length shots.coords) 5)
    (table.insert shots.coords {:x player-x :y player-y})))

(fn spawn-enemy
  [dt screen-w]
  (set enemies.dt-since-fish (+ enemies.dt-since-fish dt))
  (when (and (> enemies.dt-since-fish enemies.dt-bw-fish)
             (< (length enemies.fish) enemies.max-fish))
    (set enemies.dt-since-fish 0)
    (table.insert enemies.fish
                  {:x (math.random 0 screen-w)
                   :y 0
                   :cycle-offset (math.random 1 draw.cycle-max)})))

(fn spawn-explosion
  [x y]
  (table.insert explosions.coords
                {:x x
                 :y y
                 :cycle-offset (math.random 1 draw.cycle-max)}))

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
 : enemies
 : explosions
 : update-player
 : spawn-enemy
 : spawn-explosion
 : handle-key}
