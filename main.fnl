(local draw (require "src/draw.fnl"))

(fn love.load
  []
  (love.window.setMode 480 640) 
  (love.window.setTitle "Starship Shooters")
  (draw.load-sprites))

(fn love.draw
  []
  (draw.draw-sprite :player 240 320))
