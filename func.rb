module Func
    def | (other) # compose
        ->(*args, &block){ other.call(call(*args, &block)) }
    end

    def ** (n)
        if n.is_a?(Integer)
            ->(x){
                n.times do
                    x = call(x)
                end
                x
            }
        else
            ->(*args){
                n.(*args.map(&self))
            }
        end
    end

    def ^ (*args, &block)
        call(*args, &block)
    end
    alias [] ^

    def & (x) # curry
        ->(*args, &block){ call(x, *args, &block) }
    end

    def - (*args)
        :^ / [self, *args]
    end

    def / (x) # fold
        x.inject(&self)
    end

    def * (x) # map
        x.map(&self)
    end

    def ~ # rev arguments
        ->(*args, &block){ call(*args.reverse!, &block) }
    end

    def << (args, &block) # splat
        call(*args, &block)

    end

    def >> (*args, &block) # unsplat
        block ? call(args, block) : call(args)
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

    def train (arg)
        if arg.is_a?(Array)
            if arg.length == 2
                fork(*arg)
            elsif arg.length == 1
                hook(*arg)
            end
        else
            self.call(&arg)
        end
    end
    alias % train


    def !~ (x) # iterate until stable
        loop do
            last = x
            x = call(x)
            break if x == last
        end
        x
    end

    def =~ (x)
        call(x) == x
    end

    def + (init)
        len = 1-init.length
        ->(n){
            out = init.dup
            (n+len).times do
                out << call(*out)
                out.shift()
            end
            out.last
        }
    end

end

class Symbol
    include Func

    def call(*args, &block)
        to_proc.call(*args, &block)
    end

    alias [] call

    def =~ (other)
        to_proc =~ other
    end
end

class Proc
    include Func
end

class Method
    include Func
end
