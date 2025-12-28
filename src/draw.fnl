(local c (require "src/core.fnl"))

(var loaded? false)
(var spritesheet nil)
(var sprites nil)
(var bg-spritebatch nil)

(local size 16)
(local cycle {:value 1})
(local cycle-max 32)
(local load-data
       {:player {:start [32 48]
                 :grid [3 3]
                 :default [2 1]}
        :shots-1 {:start [32 128]
                  :grid [1 1]
                  :default [1 1]}
        :fish {:start [96 48]
               :grid [4 1]
               :default [1 1]}
        :explosion {:start [272 128]
                    :grid [5 1]
                    :default [1 1]}
        :numbers {:start [208 81]
                  :grid [5 2]
                  :size 8
                  :default [1 1]}
        :bg-1 {:start [272 208]
               :size 64
               :grid [1 1]
               :default [1 1]}
        :bg-2 {:start [352 208]
               :size 64
               :grid [1 1]
               :default [1 1]}})

(fn inc-cycle
  []
  (if (< cycle.value cycle-max)
      (set cycle.value (+ cycle.value 1))
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
           load-data))
    (set bg-spritebatch (love.graphics.newSpriteBatch spritesheet))
    (set loaded? true)))

(fn draw-bg
  [screen-w screen-h]
  (bg-spritebatch:clear)
  (let [scroll-phase (phase 32)
        bg-size (. load-data :bg-1 :size)
        neg-buffer (* bg-size -2)]
    (for [x neg-buffer (+ screen-w 1) bg-size]
      (for [y neg-buffer (+ screen-h 1) bg-size]
        (bg-spritebatch:add (. sprites (.. "bg-" (math.random 1 2)) 1 1)
                            ; the multiplier here has to line up with the size and phase
                            ; in order to loop correctly
                            (+ x (* 2 scroll-phase))
                            (+ y (* 2 scroll-phase))))))
  (love.graphics.draw bg-spritebatch))

(fn draw-sprite
  [name x y col row]
  (let [default (. load-data name :default)
        row (or row (. default 1))
        col (or col (. default 2))]
    (love.graphics.draw spritesheet
                        (. sprites name row col)
                        x
                        y)))

(fn draw-number
  [x y n]
  (love.graphics.push)
  (love.graphics.scale 2 2)
  (let [str-n (tostring n)]
    (c.map (fn [i]
             (let [digit (tonumber (str-n:sub i i))
                   sprite-row (if (< 0 digit 6) 1 2)
                   sprite-col (if (< 0 digit 6) digit (= digit 0) 5 (- digit 5))]
               (draw-sprite :numbers (+ x (* 8 (c.dec i))) y sprite-row sprite-col)))
           (c.range 1 (length str-n))))
  (love.graphics.pop))

(fn draw-player
  [x y dx]
  ; draw ship
  (draw-sprite :player
               x
               y
               1
               (if (< dx 0) 1
                   (= dx 0) 2
                   (> dx 0) 3))
  ; draw flame behind ship
  (draw-sprite :player
               x
               (+ y size)
               ; speed up the animation
               ; todo: perhaps move this logic into phase fn
               (+ 2 (% (phase 8) 2))
               (if (< dx 0) 1
                   (= dx 0) 2
                   (> dx 0) 3)))

(fn draw-fish
  [x y start-cycle]
  (let [seq [4 1 2 3 2 1]]
    (draw-sprite :fish
                   x
                   y
                   1
                   (. seq (phase 6 start-cycle)))))

(fn draw-explosion
  [x y start-cycle]
  (draw-sprite :explosion
               x
               y
               1
               (phase 5 start-cycle)))

{: cycle
 : cycle-max
 : inc-cycle
 : load-sprites
 : draw-bg
 : draw-sprite
 : draw-number
 : draw-player
 : draw-fish
 : draw-explosion}
