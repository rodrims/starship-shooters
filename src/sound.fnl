(local effects {})

(fn load-effects
  []
  (set effects.player-shot
       {:source (love.audio.newSource "assets/sfx_wpn_laser8.wav" :static)})
  (set effects.explosion
       {:source (love.audio.newSource "assets/sfx_exp_short_hard14.wav" :static)
        :volume 0.35})
  (set effects.player-spawn
       {:source (love.audio.newSource "assets/sfx_sounds_fanfare3.wav" :static)
        :volume 1.0}))

(fn play
  [name]
  (let [effect (. effects name)
        inst (effect.source:clone)]
    (inst:setVolume (or effect.volume 1))
    (inst:setPitch (+ 1 (/ (math.random -30 30) 100)))
    (inst:play)))

{: effects
 : play
 : load-effects}
