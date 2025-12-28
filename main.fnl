(local c (require "src/core.fnl"))
(local draw (require "src/draw.fnl"))
(local controls (require "src/controls.fnl"))

(var cum-dt 0)

(local scale 1.5)
(local fps 32)
(local base-dims
       {:w 480
        :h 640})

(fn love.load
  []
  (love.window.setMode (* scale base-dims.w) (* scale base-dims.h))
  (love.window.setTitle "Starship Shooters")
  (love.graphics.setDefaultFilter :nearest)
  (love.graphics.setLineStyle :rough)
  (draw.load-sprites))

(fn love.keypressed
  [k]
  (controls.handle-key k true))

(fn love.keyreleased
  [k]
  (controls.handle-key k false))

(fn love.update
  [dt]
  (controls.spawn-enemy dt base-dims.w)
  (set cum-dt (+ cum-dt dt))
  (when (>= cum-dt (/ 1 fps))
    (set cum-dt 0)
    (draw.inc-cycle)
    (controls.update-player base-dims.w base-dims.h)
    (set controls.shots.coords (c.filter (fn [shot] (> shot.y 0)) controls.shots.coords))
    (each [_ shot (ipairs controls.shots.coords)]
      (set shot.y (+ shot.y controls.shot-deltas.dy)))
    (set controls.enemies.fish (c.filter (fn [fish] (< fish.y base-dims.h)) controls.enemies.fish))
    (each [_ fish (ipairs controls.enemies.fish)]
      (set fish.y (+ fish.y controls.enemies.dy-fish)))))

(fn love.draw
  []
  (love.graphics.scale scale scale)
  (draw.draw-bg base-dims.w base-dims.h)
  (each [_ fish (ipairs controls.enemies.fish)]
    (draw.draw-fish fish.x fish.y fish.start-cycle))
  (each [_ shot (ipairs controls.shots.coords)]
    (draw.draw-sprite :shots-1 shot.x shot.y))
  (draw.draw-player controls.player-coords.x
                    controls.player-coords.y
                    controls.player-deltas.dx))
