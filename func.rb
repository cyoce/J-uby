#!/usr/bin/ruby
require 'optparse'
$main = self

def on(sym)
    x = $options[sym] and yield x
end

def main()
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
        if options[:args].length > 0
            p result.(*options[:args])
        elsif result.respond_to?(:call)
            p result.()
        else
            p result
        end
    end

end

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
        b ? ->(*args){ call(*a, *args, &b) } : a.length == 0 ? to_proc : ->(*args){ call(*a, *args) }
    end

    def - (*args)
        :^ / [self, *args]
    end

    def / (x) # fold
        x.inject(&self)
    end

    def * (x) # map
        if x.is_a?(Enumerable)
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
                i = 0
                loop do
                    begin
                        return call(*[args[0]]*i)
                    rescue ArgumentError
                        i += 1
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
        if init.is_a?(Array)
            len = 1-init.length
            ->(n){
                out = init.dup
                (n+len).times do
                    out << call(*out)
                    out.shift()
                end
                out.last
            }
        else
            ->(*args){
                call(*args, &init)
            }
        end
    end

    def D
        ->(x,y){call(x,y)}
    end

    def M
        ->(x){call(x)}
    end

    def +@
        :<< & self
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
                zip(args).map { |f, x| f ^ x }
            elsif args.length == 1
                map { |f| f[args[0]] }
            else
                raise 'length error'
            end
        }
    end

    alias _or |
    def | (x)
        return _or(x) if x.is_a?(Array)
        rotate(x)
    end

    alias +@ length

    alias ~ reverse
end

class String

    alias +@ length

    def to_a; each_char.to_a end

    alias ~ reverse
end

class Fixnum
    alias _old_or |
    def | (x=nil)
        x ? _old_or(x) : abs
    end

    def !~ (other)
        Array(self..other)
    end

    alias _old_plus +
    def + (other=nil)
        if other.nil?
            Array(1..self)
        else
            _old_plus (other)
        end
    end



    alias _old_mul *
    def * (other=nil)
        if other.nil?
            Array(0...self)
        else
            _old_mul(other)
        end
    end

    alias to_a *
end

def $main.__ # pair
    ->(x,y){ [x,y] }
end

Q = ->(x){ x.to_f }
Z = ->(x){ x.to_i }
S = ->(x){ x.to_s }
A = ->(x){ x.to_a }
H = ->(x){ Hash[x] }
I = _ = ->(x){ x }

















main() if $0 == __FILE__
