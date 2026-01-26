(fn inc
  [i]
  (+ i 1))

(fn dec
  [i]
  (- i 1))

(fn range
  [start stop step]
  (let [step (or step 1)
        result []]
    (for [i start stop step]
      (table.insert result i))
    result))

(fn keys
  [tbl]
  (icollect [[k _] tbl]
    k))

(fn map
  [f tbl]
  (icollect [_ item (ipairs tbl)]
    (f item)))

(fn map-indexed
  [f tbl]
  (icollect [index item (ipairs tbl)]
    (f index item)))

(fn filter
  [f tbl]
  (if tbl
    (let [result []]
      (each [_ item (ipairs tbl)]
        (when (f item)
          (table.insert result item)))
      result)
    ; todo: probably a better way than to repeat logic
    (fn [itbl]
      (let [result []]
        (each [_ item (ipairs itbl)]
          (when (f item)
            (table.insert result item)))
        result))))

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

;; non-clojure fns
(fn fset
  [x path f]
  (set (. x path) (f (. x path))))

{: inc
 : dec
 : range
 : keys
 : map
 : map-indexed
 : filter
 : reduce
 : reduce-kv
 : fset}
