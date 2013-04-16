
require 'stringio'

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
        include Ding::Terms

        def self.from_string(s)
            self.new(BufIo.new(StringIO.new(s)))
        end

        def initialize(io)
            @io = io
            @at_end = io.at_end?
        end

        Space = Charset.new(/\s/)
        Digit = Charset.new(/\d/)
        IdStart = Charset.new(/[a-zA-Z_\+\-=]/)
        IdChar = IdStart + Digit
        Delimiter = Charset.from_chars(',.;')
        OpenBracket = Charset.from_chars('([{')

        Brackets = { '(' => [')', :paren],
                     '[' => [']', :square],
                     '{' => ['}', :curly]   }

        def at_end?
            @at_end
        end

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

        def read_compound_term
            terms = []
            c = @io.read(1)

            closer, shape = Brackets[c]

            while c != closer do
                terms << next_term
                c = @io.peek(1)
            end

            @io.read(1)

            CompoundTerm.new(shape, terms)
        end

        def next_term
            skip_spaces

            if @io.at_end? then
                @at_end = true
                return EofTerm.instance
            end

            c = @io.peek(1)

            if IdStart.contains?(c) then
                read_id_term
            elsif Delimiter.contains?(c) then
                DelimitTerm.new(@io.read(1))
            elsif OpenBracket.contains?(c) then
                read_compound_term
            else
                raise ReaderError.new('term', c)
            end
        end
    end
end

