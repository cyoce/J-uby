<!--language-all: lang-rb -->

# J-uby - Ruby with J-like extensions

J-uby aims to augment how Ruby programming with Symbols and Procs works by monkeypatching the aforementioned classes. 

Firstly, Symbols are now callable without first calling `.to_proc` on them. Procs have also gained many more operators

```ruby
sym.(*args) == sym.to_proc.(*args)

(p | q).(*args) == q.(p.(*args))
(p & x).(*args) == p.(x, *args)
(~p).(x,y, *args) == p.(y,x, *args)

p ^ x == p.call(x)

p << x == p.(*x)
p.>>(*x) == p.(x)
p.-(x,y) == p.(x).(y)


p =~ x == (p.(x) == x)

p / x == x.inject(&p)
p * x == x.map(&p)

p % b == p.(&b)
 
(p % [q]).(x) == p.call(x,q.(x))
(p % [q]).(x,y) == p.(x, q.(y))

(p % [q,r]).(x) == p.(q.(x), p.(x)
(p % [q,r]).(x,y) == p.(q.(x), r.(y))          # if q and r accept one argument
(p % [q,r]).call(x,y) == p.(q.(x,y), r.(x,y))  # if q and r accept 2 arguments
```

### Iteration operators
`(p+init).` starts an array with init, then applies `p` to the last `init.length` entries `n` times
<br>
E.g. `fibonacci = :+ + [0,1]` 


<br>

`(p**n).(x)` iterates `p` on `x` `n` times.


<br>

`p !~ x` iterates `p` on `x` until `x == p.(x)`

# Examples

**Join Array with Commas**

```ruby
~:*&?,

(~ :*) & ','                 # more readable
->(s){ (~ :*).call(',', s) } # turn `&` into explicit lambda
->(s){ :*.call(s, ',') }     # `(~p).call(x,y) == p.call(y,x)`
->(s){ s.*(',') }            # turn symbol call into explicit method call
->(s){ s.join(',') }         # Array#* is an alias for Array#join
```
**Average of an Array**
```ruby
:/ % [:/&:+,:size]

:/ % [:/ & :+, :size]                              # more readable 
->(x){ :/.call((:/ & :+).call(x), :size.call(x)) } # expand fork to lambda
->(x){ (:+ / x) / x.size }                         # transform `.call`s on procs to method accesses
->(x){ x.reduce(:+) / x.size }                     # expand `p / x` to `x.reduce(&p)`
```

**Haskell-Style `foldr` from the existing `/`**
*Note: as this one is especially complicated, some intermediate steps are omitted*
```ruby
:~|:& &:/|:|&:reverse

(:~ | (:& & :/)) | (:| & :reverse)                 # readable
->(f){ :reverse | (:~ | (:& & :/) & f) }           # transform to lambda
->(f){ :reverse |  (:/ & ~f) }                     # reduce
->(f){ ->(x){ (:/ & ~f).call(:reverse.call(x)) } } # expand `|` into curried lambda
->(f){ ->(x){ ~f/ x.reverse } }                    # simplify `.call`s
```
