(local deltas
       {:abs-delta 8
        :dx 0
        :dy 0})

(local player-coords
       {:x 240
        :y 320})

(fn handle-key
  [k press?]
  (case k
    :up (set deltas.dy (+ deltas.dy (* deltas.abs-delta (if press? -1 1))))
    :down (set deltas.dy (+ deltas.dy (* deltas.abs-delta (if press? 1 -1))))
    :left (set deltas.dx (+ deltas.dx (* deltas.abs-delta (if press? -1 1))))
    :right (set deltas.dx (+ deltas.dx (* deltas.abs-delta (if press? 1 -1))))
    :space nil
    :q (love.event.quit)))

{: deltas
 : player-coords
 : handle-key}
