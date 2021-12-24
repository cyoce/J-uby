<!--language-all: lang-rb -->

# J-uby - Ruby with J-like extensions

J-uby aims to augment how Ruby programming with Symbols and Procs works by monkeypatching the aforementioned classes.

Firstly, Symbols are now callable without first calling `.to_proc` on them. Procs have also gained many more operators.

## Tacit programming

Tacit programming is manipulating functions to create other functions without specifying their arguments. A basic example would be a function that adds one to its argument. In Ruby, this would be done with a lambda: `->(x){1+x}`. Using the equality `(:sym & x).(y) == x.sym(y)`, we can simplify this lambda to `:+ & 1`.  

Ruby lambdas or expressions can be converted to tacit J-uby code using the following equalities:

```ruby
sym.(*args) == sym.to_proc.(*args)

(F | G).(*args) == G.(F.(*args))
(F & x).(*args) == F.(x, *args)
(~F).(x) == F.(x,x) # or as many x's as F takes
(~F).(*args) == F.(*args.reverse)
(F + G).(*args) == F.(*args, &G)

F ^ x == F.(x)

F << x == F.(*x)
F.>>(*x) == F.(x)
F.-(x,y) == F.(x).(y)
+F <=> :<< & F

F =~ x == (F.(x) == x)

F / x == x.inject(&F)
F * x == x.map(&F)

F % [G] == F.(&G)

(F**G).(*args) == G.(*args.map(&F))

(F % G).(x)   == F.(x, G.(x))
(F % G).(x,y) == F.(x, G.(y))

(F % [G,H]).(x)   == F.(G.(x), H.(x))
(F % [G,H]).(x,y) == F.(G.(x), H.(y))           # if G and H accept one argument
(F % [G,H]).(x,y) == F.(G.(x,y), H.(x,y))       # if G and H accept 2 arguments
```

### Iteration operators
`(F+init).(n)` starts an array with init, then applies `F` to the last `init.length` entries `n` times
<br>
E.g. `fibonacci = :+ + [0,1]`


<br>

`(F**n).(x)` iterates `F` on `x` `n` times.


<br>

`F !~ x` iterates `F` on `x` until `x == F.(x)`

### Miscellaneous
`-:symbol` returns the global method by that name. (e.g. `(-:puts).("hi")` prints "hi")

`-array` with one argument applies it to the procs in the array. E.g., `-[:+ & 1, :* & 2] ^ 4 == [5, 8]`.

`-array` with `array.length` arguments applies each proc to its corresponding argument. E.g., `(-[:floor, :ceil]).(1.9, 2.1) == [1,3]`

`n.-` is now the same as `n.-@` to save a byte; useful when using a symbol such as `:-|(...)`.

`_` is the identity function; for any object `o`, `_[o] == o`.

`F.& == F.to_proc` for any proc `F`.

`D^F` is a version of `F` that can only be used dyadically

`M^F` is a version of `F` that can only be used monadically

### Aliases
* `+some_array == some_array.+ == some_array.length`
* `+some_string == some_string.+ == some_string.length`
* `some_number.- == -some_number`
* `some_number.| == some_number.abs`
* `Z[any_object] == any_object.to_i`
* `Q[any_object] == any_object.to_f`
* `S[any_object] == any_object.to_s`
* `A[any_object] == any_object.to_a`
* `H[any_objec] == Hash[any_object]`
* `_[any_object] == any_object`
* `int_a !~ int_b == a..b`
* `some_int.+ == 1..some_int`
* `some_int.* == 0...some_int`
* `some_int.to_a == some_int.*`
* `some_string.to_a == some_string.each_char.to_a`
* `~some_string == some_string.reverse`
* `~some_array == some_array.reverse`

# Examples

## Join Array with Commas

```ruby
~:*&?,

(~ :*) & ','                                    # more readable
->(a){ (~ :*).(',', a) }                        # turn `&` into explicit lambda
->(a){ :*.(a, ',') }                            # `(~F).(x,y) == F.(y,x)`
->(a){ a.*(',') }                               # turn symbol call into explicit method call
->(a){ a.join(',') }                            # Array#* is an alias for Array#join
```
## Average of an Array
```ruby
:/ % [:/ & :+, :size]

->(a){ :/.((:/ & :+).(a), :size.(a)) }          # expand fork to lambda
->(a){ (:+ / a) / a.size }                      # transform `.call`s on procs to method accesses
->(a){ a.reduce(:+) / a.size }                  # expand `F / x` to `x.reduce(&F)`
```

## Haskell-Style `foldr` from the existing `/`
*Note: as this one is especially complicated, some intermediate steps are omitted*
```ruby
:~|:& &:/|:|&:reverse

(:~ | (:& & :/)) | (:| & :reverse)              # readable
->(f){ (:| & :reverse).((:~ | (:& & :/)).(f)) } # transform to lambda
->(f){ :reverse |  (:/ & ~f) }                  # reduce
->(f){ ->(a){ (:/ & ~f).(:reverse.(a)) } }      # expand `|` into curried lambda
->(f){ ->(a){ ~f / a.reverse } }                # simplify `.call`s
```


## Check if array is all even

```ruby
:* &:even?|:all?

(:* & :even?) | :all?                           # readable
->(a){ :all?.((:* & :even?).(a))}               # expand | to lambda
->(a){ (:even? * a).all? }                      # simplify explicit symbol calls
->(a){ a.map(&:even?).all? }                    # replace Proc#* with Array#map
```
### Alternative without `map`

```ruby
:all?.& &:even?

->(a){ a.all?(&:even?) }
```
