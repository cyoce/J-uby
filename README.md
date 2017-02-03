# J-uby - Ruby with J-like extensions

J-uby aims to augment how Ruby programming with Symbols and Procs works by monkeypatching the aforementioned classes. 

Firstly, Symbols are now callable without first calling `.to_proc` on them. Procs have also gained many more operators

    sym.call(x) == sym.to_proc.call(x)
    
    (p|q).call(x) == q.call(p.call(x))
    (p&x).call(y) == p.call(x,y)
    (~p).call(x,y) == p.call(y,x)
    
    p^x == p.call(x)
    
    p << x == p.call(*x)
    p.>>(*x) == p.call(x)
    
    p =~ x == (p.call(x) == x)
    
    
    (p%[q]).call(x) == p.call(x,q.call(x))
    (p%[q]).call(x,y) == p.call(x, q.call(y))
    
    (p%[q,r]).call(x) == p.call(q.call(x), p.call(x)
    (p%[q,r]).call(x,y) == p.call(q.call(x), r.call(y))     # if p and r accept one argument
    (p%[q,r]).call(x,y) == p.call(q.call(x,y), r.call(x,y)) # if p and r accept 2 arguments
