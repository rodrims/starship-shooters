(local draw (require "src/draw.fnl"))
(local controls (require "src/controls.fnl"))

(var cum-dt 0)

(local scale 1)

(fn love.load
  []
  (love.window.setMode (* scale 480) (* scale 640))
  (love.window.setTitle "Starship Shooters")
  (draw.load-sprites))

(fn love.keypressed
  [k]
  (controls.handle-key k true))

(fn love.keyreleased
  [k]
  (controls.handle-key k false))

(fn love.update
  [dt]
  (set cum-dt (+ cum-dt dt))
  (when (>= cum-dt 0.033)
    (set cum-dt 0)
    (draw.inc-cycle)
    (set controls.player-coords.x
         (+ controls.player-coords.x controls.deltas.dx))
    (set controls.player-coords.y
         (+ controls.player-coords.y controls.deltas.dy))))

(fn love.draw
  []
  (love.graphics.scale scale scale)
  (draw.draw-player controls.player-coords.x
                    controls.player-coords.y
                    controls.deltas.dx))
