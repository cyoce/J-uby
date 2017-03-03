<!--language-all: lang-rb -->

# J-uby - Ruby with J-like extensions

J-uby aims to augment how Ruby programming with Symbols and Procs works by monkeypatching the aforementioned classes.

Firstly, Symbols are now callable without first calling `.to_proc` on them. Procs have also gained many more operators.

## Tacit programming

Tacit programming is manipulating functions to create other functions without specifying their arguments. A basic example would be a function that adds one to its argument. In Ruby, this would be done with a lambda: `->(x){1+x}`. Using the equality `(:sym & x).(y) == x.sym(y)`, we can simplify this lambda to `:+ & 1`.  

Ruby lambdas or expressions can be converted to tacit J-uby code using the following equalities:

```ruby
sym.(*args) == sym.to_proc.(*args)

(P | Q).(*args) == Q.(P.(*args))
(P & x).(*args) == P.(x, *args)
(~P).(*args) == P.(*args.reverse)

P ^ x == P.(x)

P << x == P.(*x)
P.>>(*x) == P.(x)
P.-(x,y) == P.(x).(y)

P =~ x == (P.(x) == x)

P / x == x.inject(&P)
P * x == x.map(&P)

P % Q == P.(&Q)

(P**Q).(*args) == P.(*args.map(&Q))

(P % [Q]).(x)   == P.(x, Q.(x))
(P % [Q]).(x,y) == P.(x, Q.(y))

(P % [Q,R]).(x)   == P.(Q.(x), P.(x)
(P % [Q,R]).(x,y) == P.(Q.(x), R.(y))           # if Q and R accept one argument
(P % [Q,R]).(x,y) == P.(Q.(x,y), R.(x,y))       # if Q and R accept 2 arguments
```

### Iteration operators
`(P+init).(n)` starts an array with init, then applies `P` to the last `init.length` entries `n` times
<br>
E.g. `fibonacci = :+ + [0,1]`


<br>

`(P**n).(x)` iterates `P` on `x` `n` times.


<br>

`P !~ x` iterates `P` on `x` until `x == P.(x)`

# Examples

## Join Array with Commas

```ruby
~:*&?,

(~ :*) & ','                                    # more readable
->(a){ (~ :*).(',', a) }                        # turn `&` into explicit lambda
->(a){ :*.(a, ',') }                            # `(~P).(x,y) == P.(y,x)`
->(a){ a.*(',') }                               # turn symbol call into explicit method call
->(a){ a.join(',') }                            # Array#* is an alias for Array#join
```
## Average of an Array
```ruby
:/ % [:/ & :+, :size]

->(a){ :/.((:/ & :+).(a), :size.(a)) }          # expand fork to lambda
->(a){ (:+ / a) / a.size }                      # transform `.call`s on procs to method accesses
->(a){ a.reduce(:+) / a.size }                  # expand `P / x` to `x.reduce(&P)`
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
:& &:all?|~:%&:even?

(:& & :all?) | (~:% & :even?)                   # readable
->(a){ (~:% & :even?).((:& & :all?).(a)) }      # expand | into lambda
->(a){ (~:%).(:even?, :all? & a) }              # uncurry &'s
->(a){ (:all? & a) % :even? }                   # apply ~:%
->(a){ a.all?(&:even?) }                        # simplify & and %
```
