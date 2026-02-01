(var effects nil)

(fn load-effects
  []
  (when (not effects)
    (set effects
      {:player-shot  {:source (love.audio.newSource "assets/sfx_wpn_laser8.wav" :static)}
       :explosion    {:source (love.audio.newSource "assets/sfx_exp_short_hard14.wav" :static)
                      :volume 0.35}
       :player-spawn {:source (love.audio.newSource "assets/sfx_sounds_fanfare3.wav" :static)}
       :player-death {:source (love.audio.newSource "assets/sfx_sound_vaporizing.wav" :static)
                      :volume 0.8}})))

(fn play
  [name pitch]
  (let [effect (. effects name)
        inst (effect.source:clone)]
    (inst:setVolume (or effect.volume 1))
    (inst:setPitch (or pitch (+ 1 (/ (math.random -30 30) 100))))
    (inst:play)))

{: effects
 : play
 : load-effects}
