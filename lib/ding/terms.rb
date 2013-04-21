
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
        end

        class EofTerm < Term
            include Singleton
            def eof_term?
                true
            end
        end

        class OutOfBounds < StandardError
            def initialize(index, term_buffer)
                @index = index
                @term_buffer = term_buffer
            end
        end

        class TermBuffer
            def initialize(buffer, stream)
                @buffer = buffer
                @stream = stream
            end

            def at_end?
                @stream.at_end?
            end

            def in_range?(i)
                i < @buffer.size
            end

            def [](index)
                unless index < @buffer.size then
                    amount = index + 1
                    while @buffer.size < amount do
                        @buffer << @stream.next_term
                        if @stream.at_end? then
                            raise OutOfBounds.new(index, self)
                        end
                    end
                end
                @buffer[index]
            end
        end

        class EmptyTermStream
            include Singleton

            def at_end?
                true
            end

            def next_term
                EofTerm.instance
            end
        end

        class TermSequenceEmpty < StandardError; end
        
        class TermSequence
            def initialize(offset, buffer)
                @offset = offset
                @buffer = buffer
            end

            def empty?
                @buffer.at_end? and not @buffer.in_range?(@offset)
            end

            def first
                @buffer[@offset]
            end

            def rest
                if empty? then
                    raise TermSequenceEmpty.new
                end

                self.class.new(@offset + 1, @buffer)
            end
        end

    end
end

