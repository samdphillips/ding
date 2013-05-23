
require 'singleton'

module Ding
    module Terms
        module Patterns
            class PBinding
                class NoSuchValue
                    include Singleton
                end

                class Empty < PBinding
                    include Singleton

                    def initialize; end

                    def get(name, default=NoSuchValue.instance)
                        if default == NoSuchValue.instance then
                            raise "#{name} is not bound"
                        end
                        default
                    end
                end

                def self.empty
                    Empty.instance
                end

                attr_reader :prev, :name, :term

                def initialize(prev, name, term)
                    @prev = prev
                    @name = name
                    @term = term
                end

                def add(name, term)
                    if name.nil? then
                        self
                    else
                        PBinding.new(self, name, term)
                    end
                end

                def [](name)
                    get(name)
                end

                def get(name, default=NoSuchValue.instance)
                    if name == @name then
                        @term
                    else
                        @prev.get(name, default)
                    end
                end
            end

            class Match
                attr_reader :rest

                def self.fail
                    FailMatch.instance
                end

                def initialize(rest, bindings)
                    @rest = rest
                    @bindings = bindings
                end

                def bindings
                    @bindings
                end

                def success?
                    true
                end
            end

            class FailMatch
                include Singleton

                def success?
                    false
                end
            end

            class IdPattern
                def initialize(bind_name, name)
                    @bind_name = bind_name
                    @name = name
                end

                def matches?(term)
                    term.id_term? and (@name.nil? or term.name == @name)
                end

                def match(seq, bindings=PBinding.empty)
                    if seq.empty? then
                        Match.fail
                    elsif matches?(seq.first) then
                        Match.new(seq.rest, bindings.add(@bind_name, seq.first))
                    else
                        Match.fail
                    end
                end
            end

            class DelimitPattern
                def initialize(name)
                    @name = name
                end

                def matches?(term)
                    term.delimit_term? and @name = term.name
                end

                def match(seq, bindings=PBinding.empty)
                    if seq.empty? then
                        Match.fail
                    elsif matches?(seq.first) then
                        Match.new(seq.rest, bindings)
                    else
                        Match.fail
                    end
                end
            end

            class CompoundPattern
                def initialize(next_pattern, shape, subpattern)
                    @next_pattern = next_pattern
                    @shape = shape
                    @subpattern = subpattern
                end

                def matches_shape?(term)
                    term.compound_term? and term.shape == @shape
                end

                def match(seq, bindings=PBinding.empty)
                    if seq.empty? then
                        Match.fail
                    elsif matches_shape?(seq.first) then
                        m = @subpattern.match(seq.first.as_term_sequence, bindings)
                        if m.success? then
                            Match.new(seq.rest, m.bindings)
                        else
                            Match.fail
                        end
                    else
                        Match.fail
                    end
                end
            end

            class SequencePattern
                def initialize(patterns)
                    @patterns = patterns
                end

                def match(seq, bindings=PBinding.empty)
                    m = Match.new(seq, bindings)
                    @patterns.each do |pat|
                        seq = m.rest
                        bindings = m.bindings
                        m = pat.match(seq, bindings)

                        if not m.success? then
                            return m
                        end
                    end
                    m
                end
            end

            class RepeatedPattern
                class Barrier 
                    attr_reader :prev

                    def initialize(prev)
                        @prev = prev
                    end

                    def add(name, term)
                        if name.nil? then
                            self
                        else
                            PBinding.new(self, name, term)
                        end
                    end
                end

                def initialize(subpattern)
                    @subpattern = subpattern
                end

                def merge_bindings(barrier, bindings)
                    b = {}
                    while bindings != barrier do
                        name = bindings.name
                        v = b.fetch(name, [])
                        v.insert(0, bindings.term)
                        b[name] = v
                        bindings = bindings.prev
                    end

                    bindings = bindings.prev
                    b.each do |k,v|
                        bindings = bindings.add(k,v)
                    end
                    bindings
                end

                def match(seq, bindings=PBinding.empty)
                    bindings = barrier = Barrier.new(bindings)
                    while true do
                        m = @subpattern.match(seq, bindings)
                        if m.success? then
                            seq = m.rest
                            bindings = m.bindings
                        else
                            break
                        end
                    end

                    Match.new(seq, merge_bindings(barrier, bindings))
                end
            end

            class PatternBuilder
                def self.build(&block)
                    builder = self.new
                    builder.build(&block)
                    builder.compile_pattern
                end

                def initialize
                    @patterns = []
                end

                def build(&build_proc)
                    instance_eval(&build_proc)
                end

                def build_pattern(&build)
                    self.class.build(&build)
                end

                def compile_pattern
                    SequencePattern.new(@patterns)
                end

                def match_pattern(obj)
                    @patterns << obj
                end

                def term_id(name=nil)
                    match_pattern(IdPattern.new(nil, name))
                end

                def bind_id(bind_name)
                    match_pattern(IdPattern.new(bind_name, nil))
                end

                def term_delimit(name)
                    match_pattern(DelimitPattern.new(name))
                end

                def term_block(&build)
                    term_compound(:curly, &build)
                end

                def term_compound(shape, &build)
                    subpat = build_pattern(&build)
                    match_pattern(CompoundPattern.new(nil, shape, subpat))
                end

                def repeatedly(&build)
                    subpat = build_pattern(&build)
                    match_pattern(RepeatedPattern.new(subpat))
                end
            end
        end
    end
end

