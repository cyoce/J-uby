module Func
  def | (other) # compose
    ->(*args){ other.call(call(*args)) }
  end
  
  def ^ (*args, &block)
    call(*args, &block)
  end
  
  alias >> ^
  alias [] ^
  
  def & (x) # curry
    ->(*args){ call(x, *args) }
  end
  
  def / (x) # fold
    x.inject(&self)
  end
  
  def * (x) # map
    x.map(&self)
  end
  
  def ~ # rev arguments
    ->(x, y, *args){ call(y, x, *args) }
  end
  
  def << (args) # splat
    call(*args)
  end
  
  def >> (*args) # unsplat
    call(args)
  end
  
  def fork(u,v)
    ->(*args){
      if args.length == 2
        fork2(u, v, args[0], args[1])
      else
        fork1(u, v, args[0])
      end
    }
  end
  
  def fork2(u,v, x,y)
    call(u.call(x,y), v.call(x,y))
  rescue ArgumentError
    call(u.call(x), v.call(y))
  end
  
  def fork1(u,v, x)
    call(u.call(x), v.call(x))
  end
  
  def hook(u)
    ->(*args){
      if args.length == 2
        hook2(u, *args)
      else
        hook1(u, *args)
      end
    }
  end
  
  def hook1(u, x)
    call(x, u.call(x))
  end
  
  def hook2(u, x,y)
    call(x, u.call(y))
  end
  
  def % (args)
    if args.length == 2
      fork(*args)
    elsif args.length == 1
      hook(*args)
    end
  end
  
  
  def !~ (x) # iterate until stable
    loop do
      last = x
      x = call(x)
      break if x == last
    end
    x
  end
  
  def =~ (x) # x == f(x) ?
    call(x) == x
  end
  
end

class Symbol
  prepend Func
  
  def call(*args, &block)
    to_proc.call(*args, &block)
  end
end

class Proc
  include Func
end
