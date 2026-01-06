(local c (require "src/core.fnl"))
(local draw (require "src/draw.fnl"))

(local score
       {:value 0})

(local player
       {:lives 3
        :x 180
        :y 320
        :abs-delta 8
        :dx 0
        :dy 0})

(local shots
       {:coords []
        :abs-delta 15
        :dx 0
        :dy -15})

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
  (let [new-x (+ player.x player.dx)]
    (when (and (< 0 new-x) (< (+ new-x 16) screen-w))
      (set player.x new-x)))
  (let [new-y (+ player.y player.dy)]
    (when (and (< 0 new-y) (< (+ new-y 16) screen-h))
      (set player.y new-y))))

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
                   :start-cycle draw.cycle.value})))

(fn spawn-explosion
  [x y fps]
  (table.insert explosions.coords
                {:x x
                 :y y
                 :ftl (math.floor (/ fps 3))
                 :start-cycle draw.cycle.value}))

(fn collision?
  [a b]
  (and
    (or (<= b.x a.x (+ b.x 16))
        (<= b.x (+ a.x 16) (+ b.x 16)))
    (or (<= b.y a.y (+ b.y 16))
        (<= b.y (+ a.y 16) (+ b.y 16)))))

(fn handle-key
  [k press?]
  (case k
    :up (update-delta player :dy false press?)
    :down (update-delta player :dy true press?)
    :left (update-delta player :dx false press?)
    :right (update-delta player :dx true press?)
    :space (when press? (spawn-shot player.x player.y))
    :q (love.event.quit)))

{: score
 : player
 : shots
 : enemies
 : explosions
 : update-player
 : spawn-enemy
 : spawn-explosion
 : collision?
 : handle-key}
