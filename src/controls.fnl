(local draw (require :src.draw))
(local sound (require :src.sound))

(local game-start
       {:ftl 32
        :opacity 1
        :display? true})

(local game-end
       {:display? false
        :opacity 0})

(local score
       {:value 0})

(local player
       (let [start-lives 1]
         {:start-lives start-lives
          :lives start-lives
          :start-x 172
          :start-y 320
          :x 172
          :y 320
          :abs-delta 8
          :dx 0
          :dy 0}))

(local shots
       {:coords []
        :abs-delta 15
        :dx 0
        :dy -15})

(local enemies
       {:dt-since-fish -1
        :dt-bw-fish 1
        :dy-fish 6
        :max-fish 5
        :fish []})

(local explosions
       {:coords []})

(var timers
     {})

(fn player-alive?
  []
  (and (> player.lives 0)
       (not timers.player-dead)))

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
  (when (and (< (length shots.coords) 5)
             (player-alive?))
    (table.insert shots.coords {:x player-x :y player-y})
    (sound.play :player-shot)))

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
                 :start-cycle draw.cycle.value})
  (sound.play :explosion))

(fn collision?
  [a b]
  (and
    (or (<= b.x a.x (+ b.x 16))
        (<= b.x (+ a.x 16) (+ b.x 16)))
    (or (<= b.y a.y (+ b.y 16))
        (<= b.y (+ a.y 16) (+ b.y 16)))))

(fn timer
  [name seconds f]
  (set (. timers name) {:ttl seconds :handler f}))

(fn update-timers
  [dt]
  (each [name m (pairs timers)]
    (let [new-ttl (- m.ttl dt)]
      (if (< new-ttl 0)
          (do
            (m.handler)
            (set (. timers name) nil))
          (set m.ttl new-ttl)))))

; todo: should probably move this and the init values in the locals to a cfg file
(fn reset-game
  []
  ; game state
  (set player.lives player.start-lives)
  (set score.value 0)
  (set shots.coords [])
  (set enemies.fish [])
  (set enemies.dt-since-fish -1)
  (set explosions.coords [])
  (set timers {})
  ; text
  (set game-start.ftl 32)
  (set game-start.opacity 1)
  (set game-start.display? true)
  (set game-end.opacity 0)
  (set game-end.display? false)
  ; sound
  (sound.play :player-spawn 1))

(fn handle-key
  [k press?]
  (case k
    :up (update-delta player :dy false press?)
    :w (update-delta player :dy false press?)

    :down (update-delta player :dy true press?)
    :s (update-delta player :dy true press?)

    :left (update-delta player :dx false press?)
    :a (update-delta player :dx false press?)

    :right (update-delta player :dx true press?)
    :d (update-delta player :dx true press?)

    :space (when press? (spawn-shot player.x player.y))
    :r (when (and press? (= player.lives 0)) (reset-game))
    :q (love.event.quit)))

{: game-start
 : game-end
 : score
 : player
 : shots
 : enemies
 : explosions
 : player-alive?
 : update-player
 : spawn-enemy
 : spawn-explosion
 : collision?
 : timer
 : update-timers
 : reset-game
 : handle-key}
