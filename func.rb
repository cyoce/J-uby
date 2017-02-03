module Func
  def | (other) # compose
    ->(*args){ other.call(call(*args)) }
  end
  
  def ^ (*args, &block)
    call(*args, &block)
  end
  
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
  
  def io
    out = call(*Array.new(arity){gets.chomp})
    puts out
    out
  end
end

class Symbol
  include Func
  
  def call(*args, &block)
    to_proc.call(*args, &block)
  end
  
  alias [] call
end

class Proc
  include Func
end

puts $: