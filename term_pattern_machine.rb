
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


class PushFailure < Operator
    def initialize(next_op, fail_to_op)
        super(next_op)
        @fail_to_op = fail_to_op
    end

    def step(m)
        m.push_fail(@fail_to_op)
        m.next_op
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


class MergeBinds < Operator
    def step(m)
        m.merge_binds
        m.next_op
    end
end


class PushBinds < Operator
    def step(m)
        m.push_binds
        m.next_op
    end
end


class Goto < Operator
    def initialize(wrapped_op)
        @wrapped_op = wrapped_op
        @next_op = nil
    end
        
    def patch(next_op)
        @next_op = next_op
    end

    def step(m)
        @wrapped_op.step(m)
    end
end


class FailMatch
end


class Match
end


class PatBinds
    class Empty < PatBinds
        include Singleton

        def initialize; end
    end

    def initialize(prev, name, term, depth=0)
        @prev  = prev
        @name  = name
        @term  = term
        @depth = depth
    end

    def self.empty
        Empty.instance
    end

    def bind(name, term)
        PatBinds.new(self, name, term)
    end

    def merge(other_binds)
        pp other_binds
        raise 'ffo'
        while not other_binds.empty? do
            cur_bind_name = other_binds.name
            # ...
        end
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

        @progress = 0
    end

    def current_term
        @seq.first
    end

    def step
        if @progress > 100 then
            pp self
            raise Exception.new('no progress being made')
        end
        @progress += 1
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
        @progress -= 1
    end

    def bind(name)
        @binds = @binds.bind(name, seq.first)
    end

    def push_fail(fail_op)
        @fail << fail_op
    end

    def push_binds
        @bstack << @binds
        @binds = PatBinds.empty
    end

    def merge_binds
        @binds = @bstack.pop.merge(@binds)
    end
end


def test1
    p5 = MatchProperty.new(nil) { |term| term.compound_term? }
    p4 = AdvSequence.new(p5)
    p3 = BindTerm.new(p4, :classname)
    p2 = MatchProperty.new(p3) { |term| term.id_term? }
    p1 = AdvSequence.new(p2)
    p0 = MatchProperty.new(p1) { |term| term.id_term? and term.name == 'class' }
    m = Matcher.new(p0, TermSequence.from_string('class A { }'))
    m.match
    pp m
end


def test2
    p7 = PushFailure.new(nil, Match)
    p_after_loop = p7

    p6 = Goto.new(MergeBinds.new(nil))
    p_end_loop = p6
    p5 = AdvSequence.new(p6)
    p4 = BindTerm.new(p5, :v)
    p3 = MatchProperty.new(p4) { |term| term.id_term? }
    p2 = PushBinds.new(p3)
    p_end_loop.patch(p2)
    p1 = PushFailure.new(p2, p_after_loop)
    # XXX: maybe this should be the matchers initial state?
    p0 = PushFailure.new(p1, FailMatch)

    m = Matcher.new(p0, TermSequence.from_string('A B C D A { } E F G'))
    m.match
    pp m
end

test2
