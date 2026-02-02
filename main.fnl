(local c (require :src.core))
(local draw (require :src.draw))
(local sound (require :src.sound))
(local ctrl (require :src.controls))
(local {: state : cfg} (require :src.state))

(var dt-since-frame 0)

(fn love.load
  []
  (love.window.setMode (* cfg.scale cfg.screen.w) (* cfg.scale cfg.screen.h))
  (love.window.setTitle cfg.window-title)
  (love.graphics.setDefaultFilter :nearest)
  (love.graphics.setLineStyle :rough)
  (draw.load-sprites)
  (sound.load-effects)
  ;; set initial game state
  (ctrl.reset-game))

(fn love.keypressed
  [k]
  (ctrl.handle-key k true))

(fn love.keyreleased
  [k]
  (ctrl.handle-key k false))

(fn love.gamepadaxis
  [_ axis val]
  (if (= axis :leftx)
      (set state.player.dx (* val state.player.abs-delta))
      (= axis :lefty)
      (set state.player.dy (* val state.player.abs-delta))))

(fn love.gamepadpressed
  [_ button]
  (when (= button :x)
    (ctrl.handle-key :space true)))

(fn love.update
  [dt]
  (ctrl.spawn-enemies dt cfg.screen.w)
  (ctrl.update-timers dt)
  (set dt-since-frame (+ dt-since-frame dt))
  (when (>= dt-since-frame (/ 1 cfg.fps))
    (set dt-since-frame 0)
    (draw.inc-cycle)
    (ctrl.update-hud cfg.fps)
    (ctrl.handle-collisions cfg.fps)
    (ctrl.update-player cfg.screen.w cfg.screen.h)
    (ctrl.update-shots-and-explosions)
    (ctrl.update-enemies cfg.screen.h)))

(fn love.draw
  []
  (love.graphics.scale cfg.scale)
  ;; bg
  (draw.draw-bg cfg.screen.w cfg.screen.h)

  ;; nodes
  (c.map #(draw.draw-explosion $1.x $1.y $1.start-cycle) state.explosions.insts)
  (c.map #(draw.draw-sprite :shots-1 $1.x $1.y) state.shots.insts)
  (c.run! (fn [k v]
            (c.map #(draw.draw-enemy k $1.x $1.y $1.start-cycle) v.insts))
          state.enemies)
  (when (ctrl.player-alive?)
    (draw.draw-player state.player.x state.player.y state.player.dx))

  ;; hud
  (draw.draw-number cfg.hud.offset cfg.hud.offset state.score)
  ;; need to find a better way to do easy math here with scaling
  ;; this at least involves knowing the original dimensions 
  (draw.draw-lives (- cfg.screen.w 24) cfg.hud.offset state.player.lives)
  (when state.game-start.display?
    (draw.draw-game-start (- (/ cfg.screen.w 2) 48) 160 state.game-start.opacity))
  (when state.game-end.display?
    (draw.draw-game-end (- (/ cfg.screen.w 2) 72) 160 state.game-end.opacity)))
