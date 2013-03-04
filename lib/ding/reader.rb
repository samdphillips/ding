
module Ding
    class Charset
        attr_reader :pat

        def initialize(rx)
            @pat = Regexp.new(rx)
        end

        def contains(char)
            not @pat.match(char).nil?
        end

        def +(other_cs)
            Charset.new(Regexp.union(@pat, other_cs.pat))
        end
    end
end

