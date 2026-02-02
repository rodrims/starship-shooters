(local c (require :src.core))
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

(local init-enemies
       {:fish {:dt-since -1
               :dt-bw 1
               :dy 6
               :max-cnt 5
               :insts []}
        :clam {:dt-since -10
               :dt-bw 2
               :dy 4
               :max-cnt 3
               :insts []}})

(local enemies {})

(local explosions
       {:coords []})

(var timers
     {})

(fn player-alive?
  []
  (and (> player.lives 0)
       (not timers.player-dead)))

(fn update-player
  [screen-w screen-h]
  (when (player-alive?)
    (let [new-x (+ player.x player.dx)]
      (when (and (< 0 new-x) (< (+ new-x 16) screen-w))
        (set player.x new-x)))
    (let [new-y (+ player.y player.dy)]
      (when (and (< 0 new-y) (< (+ new-y 16) screen-h))
        (set player.y new-y)))))

; todo: should refactor? it's overlapping logic with game-reset
(fn handle-player-respawn
  []
  (set player.x player.start-x)
  (set player.y player.start-y)
  (when (> player.lives 0)
    (sound.play :player-spawn
                (- 1 (* 0.1 (- player.start-lives
                               player.lives))))))

(fn spawn-shot
  [player-x player-y]
  (when (and (player-alive?)
             (< (length shots.coords) 5))
    (table.insert shots.coords {:x player-x :y player-y})
    (sound.play :player-shot)))


(fn spawn-explosion
  [x y fps]
  (table.insert explosions.coords
                {:x x
                 :y y
                 :ftl (math.floor (/ fps 3))
                 :start-cycle draw.cycle.value})
  (sound.play :explosion))

(fn update-shots-and-explosions
  []
  (->> shots.coords
       (c.filter #(and (> $1.y 0) (not $1.deleted)))
       (c.map #(do (set $1.y (+ $1.y shots.dy)) $1))
       (set shots.coords))
  (->> explosions.coords
       (c.filter #(> $1.ftl 0))
       (c.map #(do (c.fset $1 :ftl c.dec) $1))
       (set explosions.coords)))

(fn spawn-enemies
  [dt screen-w]
  (when (player-alive?)
    (c.run!
      (fn [_ v]
        (c.fset v :dt-since #(+ $1 dt))
        (when (and (> v.dt-since v.dt-bw)
                   (< (length v.insts) v.max-cnt))
          (set v.dt-since 0)
          (table.insert v.insts
                        {:x (math.random 0 screen-w)
                         :y 0
                         :start-cycle draw.cycle.value})))
      enemies)))

(fn update-enemies
  [h]
  (c.run!
    (fn [_ v]
      (->> v.insts
           (c.filter #(and (< $1.y h) (not $1.deleted)))
           (c.map #(do (set $1.y (+ $1.y v.dy)) $1))
           (set v.insts)))
    enemies))

(fn update-hud
  [fps]
  (when game-start.display?
    (c.fset game-start :ftl c.dec)
    (set game-start.opacity (/ game-start.ftl 32))
    (when (< game-start.ftl 1)
      (set game-start.display? false)))
  (when game-end.display?
    (c.fset game-end :opacity #(let [new-val (+ $1 (/ 1 fps))] (if (> new-val 1) 1 new-val)))))

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

(fn collision?
  [a b]
  (and
    (or (<= b.x a.x (+ b.x 16))
        (<= b.x (+ a.x 16) (+ b.x 16)))
    (or (<= b.y a.y (+ b.y 16))
        (<= b.y (+ a.y 16) (+ b.y 16)))))

(fn handle-shot-collision
  [shot enemy fps]
  (when (collision? shot enemy)
    (c.fset score :value c.inc)
    (set enemy.deleted true)
    (set shot.deleted true)
    (spawn-explosion enemy.x enemy.y fps)))

(fn handle-player-collision
  [enemy fps]
  (when (and (player-alive?)
             (collision? enemy player)
             (not enemy.deleted))
    (c.fset player :lives c.dec)
    (set enemy.deleted true)
    ; todo: two explosions?
    (spawn-explosion player.x player.y fps)
    (spawn-explosion enemy.x enemy.y fps)
    (timer :player-dead 1 handle-player-respawn)
    (when (= player.lives 0)
      (set game-end.display? true)
      (sound.play :player-death))))

(fn handle-collisions
  [fps]
  (c.run!
    (fn [_ v]
      (c.map
        (fn [enemy]
          ; order matters!
          ; shots should kill enemies before enemies kill player
          (c.map #(handle-shot-collision $1 enemy fps) shots.coords)
          (handle-player-collision enemy fps))
        v.insts))
    enemies))

; todo: should probably move this and the init values in the locals to a cfg file
(fn reset-game
  []
  ; game state
  (set player.lives player.start-lives)
  (set score.value 0)
  (set shots.coords [])
  ; have to do this instead of just (set enemies ...) because the old reference sticks around
  (c.map #(set (. enemies $1) (c.deep-copy (. init-enemies $1))) (c.keys init-enemies))
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

(fn update-delta
  [base name positive? press?]
  (set (. base name)
       (+ (. base name)
          (* (. base :abs-delta)
             (if press? 1 -1)
             (if positive? 1 -1)))))

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
 : spawn-enemies
 : update-enemies
 : spawn-explosion
 : update-shots-and-explosions
 : update-hud
 : collision?
 : handle-collisions
 : timer
 : update-timers
 : reset-game
 : handle-key}
