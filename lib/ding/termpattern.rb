
require 'singleton'

module Ding
    module Terms
        module Patterns
            class Match
                attr_reader :rest

                def initialize(rest)
                    @rest = rest
                    @terms = []
                    @binds = {}
                end

                def add_term(term)
                    @terms << term
                end

                def add_binding(name, term)
                    @binds[name] = term
                end

                def binding
                    @binds
                end

                def merge(term, bind_name)
                    add_term(term)
                    if not bind_name.nil? then
                        add_binding(bind_name, term)
                    end
                    self
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

                def merge(term, bind_name)
                    self
                end
            end

            class EmptyPattern
                include Singleton

                def match(seq)
                    Match.new(seq)
                end
            end

            class IdPattern
                def initialize(next_pattern, bind_name, name)
                    @next_pattern = next_pattern
                    @bind_name = bind_name
                    @name = name
                end

                def link(pattern)
                    self.class.new(pattern, @bind_name, @name)
                end

                def matches?(term)
                    if @name.nil? then
                        term.id_term?
                    else
                        term.id_term? and term.name == @name
                    end
                end

                def match(seq)
                    if seq.empty? then
                        FailMatch.instance
                    elsif matches?(seq.first) then
                        m = @next_pattern.match(seq.rest)
                        m.merge(seq.first, @bind_name)
                    else
                        FailMatch.instance
                    end
                end
            end

            class Builder
                def self.build(&block)
                    builder = self.new
                    builder.build(&block)
                    builder.build_pattern
                end

                def initialize
                    @patterns = []
                end

                def build(&build_proc)
                    instance_eval(&build_proc)
                end

                def build_pattern
                    pat = EmptyPattern.instance

                    @patterns.reverse.each do |p|
                        pat = p.link(pat)
                    end
                    pat
                end

                def match_pattern(obj)
                    @patterns << obj
                end

                def term_id(name=nil)
                    match_pattern(IdPattern.new(nil, nil, name))
                end

                def bind_id(bind_name)
                    match_pattern(IdPattern.new(nil, bind_name, nil))
                end
            end
        end
    end
end

