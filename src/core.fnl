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
  (icollect [k _ (pairs tbl)]
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

; not quite like the clojure fn
; run! normally takes any seq, but this is specific to kv tables
(fn run!
  [f tbl]
  (reduce-kv
    (fn [_ k v]
      (f k v)
      nil)
    nil
    tbl))

(fn concat
  [a b]
  (let [len-a (length a)
        len-b (length b)]
    (map #(if (<= $1 len-a)
              (. a $1)
              (. b (- $1 len-a)))
         (range 1 (+ len-a len-b)))))

;; non-clojure fns
(fn fset
  [x path f]
  (set (. x path) (f (. x path))))

(fn is-list?
  [x]
  (and (> (length x) 0)
       (. x 1)))

(fn try-str
  [x]
  (if (= (type x) "table")
      (if (is-list? x)
          (table.concat (map try-str x) ", ")
          (.. (reduce-kv (fn [acc k v]
                           (.. acc k ": " (try-str v) ", "))
                         "{"
                         x)
              "}"))
      (tostring x)))

(fn deep-copy
  [x]
  (if (= (type x) "table")
      (if (is-list? x)
          (map deep-copy x)
          (reduce-kv (fn [acc k v]
                       (set (. acc k) (deep-copy v))
                       acc)
                     {}
                     x))
      x))

{: inc
 : dec
 : range
 : keys
 : map
 : map-indexed
 : filter
 : reduce
 : reduce-kv
 : run!
 : concat
 : fset
 : is-list?
 : deep-copy
 : try-str}
