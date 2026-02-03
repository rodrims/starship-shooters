(local c (require :src.core))

(var loaded? false)
(var spritesheet nil)
(var sprites nil)
(var bg-spritebatch nil)

(local size 16)
(local cycle {:value 1})
(local cycle-max 32)
(local sprite-data
       {:player {:start [32 48]
                 :grid [3 3]
                 :default [2 1]}
        :shots-1 {:start [32 128]
                  :grid [1 1]
                  :default [1 1]}
        :fish {:start [96 48]
               :start-frame 4
               :grid [4 1]
               :default [1 1]}
        :clam {:start [96 64]
               :grid [5 1]
               :default [1 1]}
        :alien {:start [96 80]
                :grid [6 1]
                :default [4 1]}
        :explosion {:start [272 128]
                    :grid [5 1]
                    :default [1 1]}
        :numbers {:start [208 81]
                  :grid [5 2]
                  :size 8
                  :default [1 1]}
        :lives {:start [290 50]
                :grid [1 1]
                :size 12
                :default [1 1]}
        :bg-1 {:start [272 208]
               :size 64
               :grid [1 1]
               :default [1 1]}
        :bg-2 {:start [352 208]
               :size 64
               :grid [1 1]
               :default [1 1]}
        :game-start {:start [256 81]
                     :size 8
                     :grid [6 1]
                     :default [1 1]}
        :game-end {:start [256 89]
                   :size 8
                   :grid [9 1]
                   :default [1 1]}})

(fn inc-cycle
  []
  (if (< cycle.value cycle-max)
      (c.fset cycle :value c.inc)
      (set cycle.value 1)))

(fn phase
  [cycle-size start-cycle]
  (let [curr-cycle (% (+ cycle.value
                         (- cycle-max (or start-cycle 1))
                         1)
                      cycle-max)
        mult (/ curr-cycle cycle-max)]
    (+ 1 (math.floor (* cycle-size mult)))))

(fn load-sprites
  []
  (when (not loaded?)
    (set spritesheet (love.graphics.newImage "assets/arcade_space_shooter.png"))
    (set sprites
         (c.reduce-kv
           (fn [acc k v]
             (let [x-start (. v.start 1)
                   y-start (. v.start 2)
                   n-cols (. v.grid 1)
                   n-rows (. v.grid 2)
                   sz (or (?. v :size) size)
                   grid []]
               (for [x x-start (- (+ x-start (* n-cols sz)) 1) sz]
                 (let [row []]
                   (for [y y-start (- (+ y-start (* n-rows sz)) 1) sz]
                     (table.insert row (love.graphics.newQuad x y sz sz spritesheet)))
                   (table.insert grid row)))
               (set (. acc k) grid))
             acc)
           {}
           sprite-data))
    (set bg-spritebatch (love.graphics.newSpriteBatch spritesheet))
    (set loaded? true)))

(fn draw-bg
  [screen-w screen-h]
  (bg-spritebatch:clear)
  (let [scroll-phase (phase 32)
        bg-size (. sprite-data :bg-1 :size)
        neg-buffer (* bg-size -2)]
    (for [x neg-buffer (+ screen-w 1) bg-size]
      (for [y neg-buffer (+ screen-h 1) bg-size]
        (bg-spritebatch:add (. sprites (.. "bg-" (math.random 1 2)) 1 1)
                            ;; the multiplier here has to line up with the size and phase
                            ;; in order to loop correctly
                            (+ x (* 2 scroll-phase))
                            (+ y (* 2 scroll-phase))))))
  (love.graphics.draw bg-spritebatch))

;; fixme: naming of row/col is confusing, I think backwards???
(fn draw-sprite
  [name x y col row]
  (let [default (. sprite-data name :default)
        row (or row (. default 1))
        col (or col (. default 2))]
    (love.graphics.draw spritesheet
                        (. sprites name row col)
                        x
                        y)))

(fn draw-game-start
  [x y opacity]
  (love.graphics.push)
  (love.graphics.translate x y)
  (love.graphics.scale 2)
  (love.graphics.setColor 1 1 1 opacity)
  (c.map (fn [i]
           (draw-sprite :game-start (* 8 (c.dec i)) 0 1 i))
         (c.range 1 (. sprite-data.game-start.grid 1)))
  (love.graphics.setColor 1 1 1 1)
  (love.graphics.pop))

(fn draw-game-end
  [x y opacity]
  (love.graphics.push)
  (love.graphics.translate x y)
  (love.graphics.scale 2)
  (love.graphics.setColor 1 1 1 opacity)
  (c.map (fn [i]
           (draw-sprite :game-end (* 8 (c.dec i)) 0 1 i))
         (c.range 1 (. sprite-data.game-end.grid 1)))
  (love.graphics.setColor 1 1 1 1)
  (love.graphics.pop))

(fn draw-number
  [x y n]
  (let [scale 2]
    (let [str-n (tostring n)]
      (c.map (fn [i]
               (let [digit (tonumber (str-n:sub i i))
                     sprite-row (if (< 0 digit 6) 1 2)
                     sprite-col (if (< 0 digit 6) digit (= digit 0) 5 (- digit 5))]
                 (love.graphics.push)
                 (love.graphics.translate (+ x (* 8 scale (c.dec i))) y)
                 (love.graphics.scale scale)
                 (draw-sprite :numbers 0 0 sprite-row sprite-col)
                 (love.graphics.pop)))
             (c.range 1 (length str-n))))))

(fn draw-lives
  [x y n]
  (for [m 0 (c.dec n)]
    (draw-sprite :lives (- x (* m sprite-data.lives.size)) y)))

(fn draw-player
  [x y dx]
  ;; draw ship
  (draw-sprite :player
               x
               y
               1
               (if (< dx 0) 1
                   (= dx 0) 2
                   (> dx 0) 3))
  ;; draw flame behind ship
  (draw-sprite :player
               x
               (+ y size)
               ;; speed up the animation
               ;; todo: perhaps move this logic into phase fn
               (+ 2 (% (phase 8) 2))
               (if (< dx 0) 1
                   (= dx 0) 2
                   (> dx 0) 3)))

(fn draw-enemy
  [name {: x : y : start-cycle : blink-ftl}]
  (let [size (. sprite-data name :grid 1)
        ;; for N=4 just generates a sequence like [4 1 2 3 2 1]
        seq (-> [size]
                (c.concat (c.range 1 (- size 1)))
                (c.concat (c.range (- size 2) 1 -1)))
        seq (if (= name :alien) [4 5 6 1 2 3 2 1 6 5] seq)]
    (when (> blink-ftl 0)
      (love.graphics.setColor 1 0 0))
    (draw-sprite name
                 x
                 y
                 1
                 (. seq (phase (* 2 (- size 1)) start-cycle)))
    ;; todo: cleaner to do this?
    (love.graphics.setColor 1 1 1)))

(fn draw-explosion
  [x y start-cycle]
  (love.graphics.push)
  (love.graphics.translate x y)
  (love.graphics.scale 2)
  (draw-sprite :explosion
               0
               0
               1
               (c.inc (% (phase 12 start-cycle) 5)))
  (love.graphics.pop))

{: cycle
 : cycle-max
 : inc-cycle
 : load-sprites
 : draw-bg
 : draw-sprite
 : draw-game-start
 : draw-game-end
 : draw-number
 : draw-lives
 : draw-player
 : draw-enemy
 : draw-explosion}
