
require 'pp'
require 'singleton'

require 'ding'
include Ding::Terms

class Operator
    attr_reader :next_op

    def initialize(next_op)
        @next_op = next_op
    end
end

class AdvSequence < Operator
    def step(m)
        m.step_seq
        m.next_op
    end
end

class MatchProperty < Operator
    def initialize(next_op, &matcher)
        super(next_op)
        @matcher = matcher
    end

    def step(m)
        if @matcher.call(m.current_term) then
            m.next_op
        else
            m.fail
        end
    end
end

class BindTerm < Operator
    def initialize(next_op, bind_name)
        super(next_op)
        @bind_name = bind_name
    end

    def step(m)
        m.bind(@bind_name)
        m.next_op
    end
end

class PatBinds
    class Empty < PatBinds
        include Singleton

        def initialize; end
    end

    def initialize(prev, name, term)
        @prev = prev
        @name = name
        @term = term
    end

    def self.empty
        Empty.instance
    end

    def bind(name, term)
        PatBinds.new(self, name, term)
    end
end

class Matcher
    attr_reader :seq

    def initialize(pat, seq)
        @pat    = pat
        @seq    = seq
        @binds  = PatBinds.empty
        @fail   = []
        @bstack = []
    end

    def current_term
        @seq.first
    end

    def step
        @pat.step(self)
    end

    def match
        while running? do
            step
        end
    end

    def running?
        not @pat.nil?
    end

    def step_seq
        @seq = @seq.rest
    end

    def next_op
        @pat = @pat.next_op
    end

    def bind(name)
        @binds = @binds.bind(name, seq.first)
    end

end


p3 = BindTerm.new(nil, :classname)
p2 = MatchProperty.new(p3) { |term| term.id_term? }
p1 = AdvSequence.new(p2)
p0 = MatchProperty.new(p1) { |term| term.id_term? and term.name == 'class' }
m = Matcher.new(p0, TermSequence.from_string('class A { }'))
m.match
pp m
