#!/usr/bin/ruby
require 'optparse'
$main = self
module Func

    def | (other) # compose
        ->(*args, &block){ other.call(call(*args, &block)) }
    end

    def ** (n)
        ->(x){
            n.times do
                x = call(x)
            end
            x
        }
    end

    def ^ (*args, &block)
        call(*args, &block)
    end
    alias [] ^

    def & (*a, &b) # curry
        if a.length == 0
            if b
                ->(*args){ call(*args, &b)}
            else
                to_proc
            end
        else
            x=a[0]
            ->(*args, &block){ call(x, *args, &block) }
        end
    end

    def - (*args)
        :^ / [self, *args]
    end

    def / (x) # fold
        x.inject(&self)
    end

    def * (x) # map
        if x.is_a?(Array)
            x.map(&self)
        else
            ->(*args){
                x.(*args.map(&self))
            }
        end
    end

    def ~ # rev arguments
        ->(*args, &block){
            if args.size == 1
                @i ||= 0
                loop do
                    begin
                        return call(*[args[0]]*@i)
                    rescue ArgumentError
                        @i+=1
                    end
                end
            else
                call(*args.reverse!, &block)
            end
        }
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
                self.(&arg[0])
            end
        else
            hook(arg)
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

    def -@
        $main.method(self)
    end

end

class Proc
    include Func
end

class Method
    include Func
end

class Array
    def -@
        ->(*args){
            if args.length == length
                self.zip(args).map {|fs| fs[0] ^ fs[1]}
            elsif args.length == 1
                self.map { |f| f ^ args[0]}
            end
        }
    end

    def +@
        length
    end

    alias _old_plus +
    def + (*args)
        if args.length == 0
            length
        else
            _old_plus(*args)
        end
    end
end

class Fixnum
    alias old_minus -
    def - (x=nil)
        if x.nil?
            -self
        else
            old_minus(x)
        end
    end
end

def $main.__
    ->(x,y){[x,y]}
end

class BasicObject
    def _
        self
    end
end

def on(sym)
    x = $options[sym] and yield x
end

if __FILE__ == $0
    $options = options = {eval?: true}
    OptionParser.new do |opts|
        opts.separator ''

        opts.on("-e [CODE]") do |code|
            options[:eval] = code
        end

        opts.on("-i") do # read from STDIN instead of ARGV
            options[:stdin?] = true
        end

        opts.on("-l") do # literal input (no eval)
            options[:eval?] = false
        end

        opts.on("-g") do # greedy
            options[:greedy?] = true
        end

        options[:args] = opts.order(*ARGV)
    end

    on :stdin? do
        options[:args] = []
        options[:args] << $_.chomp! while (print '> '; STDIN.gets)
    end


    file = options[:args].shift unless options[:stdin?] || options[:eval]

    on :eval? do
        options[:args].map! &-:eval
    end

    unless options[:stdin?] || options[:eval]
        result = eval File.read(file)
        p result.(*options[:args]) if options[:args].length > 0
    end

    on :greedy? do
        options[:args] = [options[:args].join(options[:stdin?] ? "\n" : " ")]
    end

    on :eval do |code|
        result = eval code
        p result.(*options[:args]) if options[:args].length > 0
    end

end
