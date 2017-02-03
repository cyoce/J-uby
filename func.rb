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
  
  
  def !~ (x) # iterate until stable
    loop do
      last = x
      x = call(x)
      break if x == last
    end
    x
  end
  
  def =~ (x) # equal to f of x?
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
