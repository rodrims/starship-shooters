(fn inc
  [i]
  (+ i 1))

(fn dec
  [i]
  (- i 1))

(fn range
  [start stop step]
  (let [result []]
    (for [i start stop step]
      (table.insert result i))
    result))

(fn keys
  [tbl]
  (icollect [[k _] tbl]
    k))

(fn map
  [f tbl]
  (icollect [_ item (pairs tbl)]
    (f item)))

(fn filter
  [f tbl]
  (let [result []]
    (each [_ item (pairs tbl)]
      (when (f item)
        (table.insert result item)))
    result))

(fn reduce
  [f init-val tbl]
  (var acc init-val)
  (each [_ item (ipairs tbl)]
    (set acc (f acc item)))
  acc)

(fn reduce-kv
  [f init-val tbl]
  (accumulate [acc init-val
               k v (pairs tbl)]
    (f acc k v)))

{: inc
 : dec
 : range
 : keys
 : map
 : filter
 : reduce
 : reduce-kv}
