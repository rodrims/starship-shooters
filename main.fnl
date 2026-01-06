(local c (require "src/core.fnl"))
(local draw (require "src/draw.fnl"))
(local controls (require "src/controls.fnl"))

(var cum-dt 0)

(local scale 2)
(local fps 32)
(local base-dims
       {:w 360
        :h 520})

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
    ; handle collision (messy)
    (each [_ fish (ipairs controls.enemies.fish)]
      (each [_ shot (ipairs controls.shots.coords)]
        (when (controls.collision? shot fish)
          (c.fset controls.score :value c.inc)
          (set fish.deleted true)
          (set shot.deleted true)))
      (when (and (controls.collision? fish controls.player) (not fish.deleted))
        (c.fset controls.player :lives c.dec)
        (set fish.deleted true)))
    (c.fset controls.shots :coords (partial c.filter #(not $1.deleted)))
    (c.fset controls.enemies
            :fish
            (partial c.filter
                     (fn [fish]
                       (when fish.deleted
                         (controls.spawn-explosion fish.x fish.y fps))
                       (not fish.deleted))))
    ;; other updates
    (controls.update-player base-dims.w base-dims.h)
    (c.fset controls.shots :coords (partial c.filter #(> $1.y 0)))
    (each [_ shot (ipairs controls.shots.coords)]
      (set shot.y (+ shot.y controls.shots.dy)))
    (c.fset controls.enemies :fish (partial c.filter #(< $1.y base-dims.h)))
    (each [_ fish (ipairs controls.enemies.fish)]
      (set fish.y (+ fish.y controls.enemies.dy-fish)))
    ; todo: not sure why > 1 instead of > 0
    (c.fset controls.explosions :coords (partial c.filter #(> $1.ftl 0)))
    (each [_ explosion (ipairs controls.explosions.coords)]
      (set explosion.ftl (c.dec explosion.ftl)))))

(fn love.draw
  []
  (love.graphics.scale scale scale)
  (draw.draw-bg base-dims.w base-dims.h)
  (each [_ explosion (ipairs controls.explosions.coords)]
    (draw.draw-explosion explosion.x explosion.y explosion.start-cycle))
  (each [_ fish (ipairs controls.enemies.fish)]
    (draw.draw-fish fish.x fish.y fish.start-cycle))
  (each [_ shot (ipairs controls.shots.coords)]
    (draw.draw-sprite :shots-1 shot.x shot.y))
  (draw.draw-player controls.player.x
                    controls.player.y
                    controls.player.dx)
  (draw.draw-number 4 4 controls.score.value)
  ; need to find a better way to do easy math here with scaling

  (draw.draw-lives (- base-dims.w 24) 12 controls.player.lives)
  )
