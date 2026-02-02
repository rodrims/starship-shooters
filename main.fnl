(local c (require :src.core))
(local draw (require :src.draw))
(local sound (require :src.sound))
(local controls (require :src.controls))

(var cum-dt 0)

(local scale 3)
(local fps 32)
(local screen
       {:w 360
        :h 520})

(fn love.load
  []
  (love.window.setMode (* scale screen.w) (* scale screen.h))
  (love.window.setTitle "Starship Shooters")
  (love.graphics.setDefaultFilter :nearest)
  (love.graphics.setLineStyle :rough)
  (draw.load-sprites)
  (sound.load-effects)
  ; set initial game state
  (controls.reset-game))

(fn love.keypressed
  [k]
  (controls.handle-key k true))

(fn love.keyreleased
  [k]
  (controls.handle-key k false))

(fn love.gamepadaxis
  [_ axis val]
  (if (= axis :leftx)
      (set controls.player.dx (* val controls.player.abs-delta))
      (= axis :lefty)
      (set controls.player.dy (* val controls.player.abs-delta))))

(fn love.gamepadpressed
  [_ button]
  (when (= button :x)
    (controls.handle-key :space true)))

(fn love.update
  [dt]
  (controls.spawn-enemies dt screen.w)
  (controls.update-timers dt)
  (set cum-dt (+ cum-dt dt))
  (when (>= cum-dt (/ 1 fps))
    (set cum-dt 0)
    (draw.inc-cycle)
    (controls.update-hud fps)
    (controls.handle-collisions fps)
    ;; other updates
    (controls.update-player screen.w screen.h)
    (controls.update-shots-and-explosions)
    (controls.update-enemies screen.h)))

(fn love.draw
  []
  (love.graphics.scale scale scale)

  ; bg
  (draw.draw-bg screen.w screen.h)

  ; nodes
  (each [_ explosion (ipairs controls.explosions.coords)]
    (draw.draw-explosion explosion.x explosion.y explosion.start-cycle))
  (c.reduce-kv
    (fn [_ k v]
      (c.map #(draw.draw-enemy k $1.x $1.y $1.start-cycle) v.insts))
    nil
    controls.enemies)
  (each [_ shot (ipairs controls.shots.coords)]
    (draw.draw-sprite :shots-1 shot.x shot.y))
  (when (controls.player-alive?)
    (draw.draw-player controls.player.x
                      controls.player.y
                      controls.player.dx))

  ; hud
  (draw.draw-number 8 8 controls.score.value)
  ; need to find a better way to do easy math here with scaling
  ; this at least involves knowing the original dimensions 
  (draw.draw-lives (- screen.w 24) 12 controls.player.lives)
  (when controls.game-start.display?
    (draw.draw-game-start (- (/ screen.w 2) 48) 160 controls.game-start.opacity))
  (when controls.game-end.display?
    (draw.draw-game-end (- (/ screen.w 2) 72) 160 controls.game-end.opacity))
  )
