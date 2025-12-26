(local c (require "src/core.fnl"))

(var loaded? false)
(var spritesheet nil)
(var sprites nil)
(var cycle 1)

(local size 16)
(local cycle-max 8)
(local load-data
       {:player {:start [32 48]
                 :grid [3 3]
                 :default [2 1]}})

(fn inc-cycle
  []
  (if (< (+ cycle 1) cycle-max)
      (set cycle (+ cycle 1))
      (set cycle 1)))

(fn phase
  [cycle-size]
  (let [mult (/ cycle cycle-max)]
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
                   grid []]
               (for [x x-start (- (+ x-start (* n-cols size)) 1) size]
                 (let [row []]
                   (for [y y-start (- (+ y-start (* n-rows size)) 1) size]
                     (table.insert row (love.graphics.newQuad x y size size spritesheet)))
                   (table.insert grid row)))
               (set (. acc k) grid))
             acc)
           {}
           load-data))
    (set loaded? true)))

(fn draw-sprite
  [name x y col row]
  (let [default (. load-data name :default)
        row (or row (. default 1))
        col (or col (. default 2))]
    (love.graphics.draw spritesheet
                        (. sprites name row col)
                        x
                        y)))

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
               (+ 1 (phase 2))
               (if (< dx 0) 1
                   (= dx 0) 2
                   (> dx 0) 3)))

{: inc-cycle
 : load-sprites
 : draw-sprite
 : draw-player}
