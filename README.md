<!--language-all: lang-rb -->

# J-uby - Ruby with J-like extensions

J-uby aims to augment how Ruby programming with Symbols and Procs works by monkeypatching the aforementioned classes.

Firstly, Symbols are now callable without first calling `.to_proc` on them. Procs have also gained many more operators

```ruby
sym.(*args) == sym.to_proc.(*args)

(P | Q).(*args) == Q.(P.(*args))
(P & x).(*args) == P.(x, *args)
(~P).(*args) == P.(*args.reverse)

P ^ x == P.call(x)

P << x == P.(*x)
P.>>(*x) == P.(x)
P.-(x,y) == P.(x).(y)

P << block == P.call(&block)


P =~ x == (P.(x) == x)

P / x == x.inject(&P)
P * x == x.map(&P)

P % b == P.(&b)

(P**Q).(*args) == P.(*args.map(&Q))

(P % [Q]).(x) == P.call(x,Q.(x))
(P % [Q]).(x,y) == P.(x, Q.(y))

(P % [Q,R]).(x) == P.(Q.(x), P.(x)
(P % [Q,R]).(x,y) == P.(Q.(x), R.(y))          # if Q and R accept one argument
(P % [Q,R]).(x,y) == P.(Q.(x,y), R.(x,y))  # if Q and R accept 2 arguments
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

(~ :*) & ','                 # more readable
->(s){ (~ :*).call(',', s) } # turn `&` into explicit lambda
->(s){ :*.call(s, ',') }     # `(~P).call(x,y) == P.call(y,x)`
->(s){ s.*(',') }            # turn symbol call into explicit method call
->(s){ s.join(',') }         # Array#* is an alias for Array#join
```
## Average of an Array
```ruby
:/ % [:/&:+,:size]

:/ % [:/ & :+, :size]                              # more readable
->(x){ :/.call((:/ & :+).call(x), :size.call(x)) } # expand fork to lambda
->(x){ (:+ / x) / x.size }                         # transform `.call`s on procs to method accesses
->(x){ x.reduce(:+) / x.size }                     # expand `P / x` to `x.reduce(&P)`
```

## Haskell-Style `foldr` from the existing `/`
*Note: as this one is especially complicated, some intermediate steps are omitted*
```ruby
:~|:& &:/|:|&:reverse

(:~ | (:& & :/)) | (:| & :reverse)                 # readable
->(f){ :reverse | (:~ | (:& & :/) & f) }           # transform to lambda
->(f){ :reverse |  (:/ & ~f) }                     # reduce
->(f){ ->(x){ (:/ & ~f).call(:reverse.call(x)) } } # expand `|` into curried lambda
->(f){ ->(x){ ~f/ x.reverse } }                    # simplify `.call`s
```

## Check if array is all even

```ruby
:* *:even?|:all?

(:* * :even?) | :all?           # readable
->(a){ :all?.((:* * :even?).(a))} # expand | to lambda
->(a){ (:even? * a).all? }      # simplify explicit symbol calls
->(a){ a.map(&:even?).all? }    # replace Proc#* with Array#map
```
### Alternative without `map`

```ruby
:& &:all?|~:<<&:even?

(:& & :all?) | (~:<< & :even?)              # readable
->(a){ (~:<< & :even?).((:& & :all?).(a)) } # expand | into lambda
->(a){ (~:<<).(:even?, :all? & a) }         # uncurry &'s
->(a){ (:all? & a) << :even? }              # apply ~:<<
->(a){ a.all?(&:even?) }                    # simplify & and <<
```
