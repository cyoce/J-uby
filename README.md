<!--language-all: lang-rb -->

# J-uby - Ruby with J-like extensions

J-uby aims to augment how Ruby programming with Symbols and Procs works by monkeypatching the aforementioned classes. 

Firstly, Symbols are now callable without first calling `.to_proc` on them. Procs have also gained many more operators

```ruby
sym.call(x) == sym.to_proc.call(x)

(p | q).call(x) == q.call(p.call(x))
(p & x).call(y) == p.call(x,y)
(~p).call(x,y) == p.call(y,x)

p ^ x == p.call(x)

p << x == p.call(*x)
p.>>(*x) == p.call(x)
p.-(x,y) == p.call(x).call(y)

p << block == p.call(&block)


p =~ x == (p.call(x) == x)

p / x == x.inject(&p)
p * x == x.map(&p)

 
(p % [q]).call(x) == p.call(x,q.call(x))
(p % [q]).call(x,y) == p.call(x, q.call(y))

(p % [q,r]).call(x) == p.call(q.call(x), p.call(x)
(p % [q,r]).call(x,y) == p.call(q.call(x), r.call(y))     # if q and r accept one argument
(p % [q,r]).call(x,y) == p.call(q.call(x,y), r.call(x,y)) # if q and r accept 2 arguments
```

### Iteration operators
`(p+init).call(n)` starts an array with init, then applies `p` to the last `init.length` entries `n` times
<br>
E.g. `fibonacci = :+ + [0,1]` 


<br>

`(p**n).call(x)` iterates `p` on `x` `n` times.


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
