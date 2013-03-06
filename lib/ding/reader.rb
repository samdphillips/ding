
require 'singleton'

module Ding
    class Charset
        attr_reader :pat

        def self.from_chars(s)
            self.new("[#{Regexp.escape(s)}]")
        end

        def initialize(rx)
            @pat = Regexp.new(rx)
        end

        def contains?(char)
            not @pat.match(char).nil?
        end

        def +(other_cs)
            Charset.new(Regexp.union(@pat, other_cs.pat))
        end
    end

    class Term
        def eof_term?
            false
        end

        def id_term?
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

    class EofTerm < Term
        include Singleton
        def eof_term?
            true
        end
    end

    class ReaderError < StandardError
        def initialize(expected, actual)
            @actual = actual
            @expected = expected
        end

        def to_s
            "ReaderError: expected #{@expected}, got: #{@actual.inspect}"
        end
    end

    class Reader
        def initialize(io)
            @io = io
        end

        Space = Charset.new(/\s/)
        Digit = Charset.new(/\d/)
        IdStart = Charset.new(/[a-zA-Z_\+\-=]/)
        IdChar = IdStart + Digit
        Delimiter = Charset.from_chars(',.;')

        def skip_spaces
            while true do
                c = @io.peek(1)
                if Space.contains?(c) then
                    @io.read(1)
                elsif c == '/' then
                    s = @io.peek(2)
                    if s == '//' then
                        skip_line_comment
                    elsif s == '/*' then
                        skip_block_comment
                    else
                        break
                    end
                else
                    break
                end
            end
        end

        def skip_line_comment
            @io.read(2)

            unless @io.at_end? then
                while true do
                    if @io.at_end? then
                        break
                    else
                        c = @io.peek(1)
                        if c == "" or c == "\n" then
                            @io.read(1)
                            break
                        end
                        @io.read(1)
                        c = @io.peek(1)
                    end
                end
            end
        end

        def skip_block_comment
            @io.read(2)

            while true do
                if @io.at_end? then
                    raise ReaderError.new('*/', '<eof>')
                end

                s = @io.peek(2)

                if s == '*/' then
                    @io.read(2)
                    break
                elsif s[1] == '*' then
                    @io.read(1)
                else
                    @io.read(2)
                end
            end
        end

        def read_id_term
            s = ""
            while IdChar.contains?(@io.peek(1)) do
                s << @io.read(1)
            end
            IdTerm.new(s)
        end

        def next_term
            skip_spaces

            if @io.at_end? then
                return EofTerm.instance
            end

            c = @io.peek(1)

            if IdStart.contains?(c) then
                read_id_term
            elsif Delimiter.contains?(c) then
                DelimitTerm.new(@io.read(1))
            else
                raise ReaderError.new('term', c)
            end
        end
    end
end

