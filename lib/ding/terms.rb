
require 'singleton'

module Ding
    module Terms

        class Term
            def eof_term?
                false
            end

            def id_term?
                false
            end

            def compound_term?
                false
            end

            def delimit_term?
                false
            end
        end

        class IdTerm < Term
            attr_reader :name

            def initialize(name)
                @name = name
            end

            def id_term?
                true
            end
        end

        class DelimitTerm < Term
            attr_reader :name

            def initialize(name)
                @name = name
            end

            def delimit_term?
                true
            end
        end

        class CompoundTerm < Term
            attr_reader :shape, :terms

            def initialize(shape, terms)
                @shape = shape
                @terms = terms
            end

            def compound_term?
                true
            end

            def as_term_sequence
                TermSequence.from_array(@terms)
            end
        end

        class EofTerm < Term
            include Singleton
            def eof_term?
                true
            end
        end

        class TermSequenceEmpty < StandardError; end
        
        class TermSequence
            class Empty
                include Singleton

                def empty?
                    true
                end

                def first
                    raise TermSequenceEmpty
                end
                
                def rest
                    raise TermSequenceEmpty
                end

                def new_state=(seq)
                end
            end

            class Pending
                attr_writer :new_state

                def initialize(st)
                    @st = st
                end

                def step
                    elem = @st.next_term
                    if elem.eof_term? then
                        state = Empty.instance
                    else
                        rest = TermSequence.for_stream(@st)
                        state = Complete.new(elem, rest)
                    end
                    @new_state.call(state)
                end

                def empty?
                    step.empty?
                end

                def first
                    step.first
                end

                def rest
                    step.rest
                end
            end

            class Complete
                attr_reader :first, :rest

                def initialize(first, rest)
                    @first = first
                    @rest = rest
                end

                def empty?
                    false
                end

                def new_state=(st)
                end
            end

            def self.from_array(arr)
                arr.reverse.reduce(empty_state) do |seq, term|
                    self.cons(term, seq)
                end
            end

            def self.from_string(str)
                r = Reader.from_string(str)
                self.for_stream(r)
            end

            def self.for_stream(st)
                self.new(Pending.new(st))
            end

            def self.cons(first, rest)
                self.new(Complete.new(first, rest))
            end

            def self.empty_state
                self.new(Empty.instance)
            end

            def initialize(state)
                @state = state
                @state.new_state = lambda {|st| @state = st }
            end

            def empty?
                @state.empty?
            end

            def first
                @state.first
            end

            def rest
                @state.rest
            end
        end

    end
end

