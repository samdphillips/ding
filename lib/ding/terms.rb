
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

    end
end

