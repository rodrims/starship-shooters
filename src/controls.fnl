(local c (require :src.core))
(local draw (require :src.draw))
(local sound (require :src.sound))
(local {: state : reset-state} (require :src.state))

(fn player-alive?
  []
  (and (> state.player.lives 0)
       (not state.timers.player-dead)))

(fn update-player
  [screen-w screen-h]
  (when (player-alive?)
    (let [new-x (+ state.player.x state.player.dx)]
      (when (and (< 0 new-x) (< (+ new-x 16) screen-w))
        (set state.player.x new-x)))
    (let [new-y (+ state.player.y state.player.dy)]
      (when (and (< 0 new-y) (< (+ new-y 16) screen-h))
        (set state.player.y new-y)))))

(fn handle-player-respawn
  []
  (set state.player.x state.player.start-x)
  (set state.player.y state.player.start-y)
  (sound.play :player-spawn
              (- 1 (* 0.1 (- state.player.start-lives
                             state.player.lives)))))

(fn spawn-shot
  [player-x player-y]
  (when (and (player-alive?)
             (< (length state.shots.insts) 5))
    (table.insert state.shots.insts {:x player-x :y player-y})
    (sound.play :player-shot)))


(fn spawn-explosion
  [x y fps]
  (table.insert state.explosions.insts
                {:x x
                 :y y
                 :ftl (math.floor (/ fps 3))
                 :start-cycle draw.cycle.value})
  (sound.play :explosion))

(fn update-shots-and-explosions
  []
  (->> state.shots.insts
       (c.filter #(and (> $1.y 0) (not $1.deleted?)))
       (c.map #(do (set $1.y (+ $1.y state.shots.dy)) $1))
       (set state.shots.insts))
  (->> state.explosions.insts
       (c.filter #(> $1.ftl 0))
       (c.map #(do (c.fset $1 :ftl c.dec) $1))
       (set state.explosions.insts)))

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
      state.enemies)))

(fn update-enemies
  [h]
  (c.run!
    (fn [_ v]
      (->> v.insts
           (c.filter #(and (< $1.y h) (not $1.deleted?)))
           (c.map #(do (set $1.y (+ $1.y v.dy)) $1))
           (set v.insts)))
    state.enemies))

(fn update-hud
  [fps]
  (when state.game-start.display?
    (c.fset state.game-start :ftl c.dec)
    (set state.game-start.opacity (/ state.game-start.ftl 32))
    (when (< state.game-start.ftl 1)
      (set state.game-start.display? false)))
  (when state.game-end.display?
    (c.fset state.game-end :opacity #(let [new-val (+ $1 (/ 1 fps))] (if (> new-val 1) 1 new-val)))))

(fn timer
  [name seconds f]
  (set (. state.timers name) {:ttl seconds :handler f}))

(fn update-timers
  [dt]
  (c.run!
    (fn [k v]
      ;; had this in reverse order before, but I think it's fine
      (c.fset v :ttl #(- $1 dt))
      (when (< v.ttl 0)
        (v.handler)
        (set (. state.timers k) nil)))
    state.timers))

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
    (c.fset state :score c.inc)
    (set enemy.deleted? true)
    (set shot.deleted? true)
    (spawn-explosion enemy.x enemy.y fps)))

(fn handle-player-collision
  [enemy fps]
  (when (and (player-alive?)
             (collision? enemy state.player)
             (not enemy.deleted?))
    (c.fset state.player :lives c.dec)
    (set enemy.deleted? true)
    ;; todo: two explosions?
    (spawn-explosion state.player.x state.player.y fps)
    (spawn-explosion enemy.x enemy.y fps)
    (if (> state.player.lives 0)
        (timer :player-dead 1 handle-player-respawn)
        (do (set state.game-end.display? true)
            (sound.play :player-death)))))

(fn handle-collisions
  [fps]
  (c.run!
    (fn [_ v]
      (c.map
        (fn [enemy]
          ;; order matters!
          ;; shots should kill enemies before enemies kill player
          (c.map #(handle-shot-collision $1 enemy fps) state.shots.insts)
          (handle-player-collision enemy fps))
        v.insts))
    state.enemies))

(fn reset-game
  []
  (reset-state)
  (handle-player-respawn))

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
    :up (update-delta state.player :dy false press?)
    :w (update-delta state.player :dy false press?)

    :down (update-delta state.player :dy true press?)
    :s (update-delta state.player :dy true press?)

    :left (update-delta state.player :dx false press?)
    :a (update-delta state.player :dx false press?)

    :right (update-delta state.player :dx true press?)
    :d (update-delta state.player :dx true press?)

    :space (when press? (spawn-shot state.player.x state.player.y))
    :r (when (and press? (= state.player.lives 0)) (reset-game))
    :q (love.event.quit)))

{: player-alive?
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
