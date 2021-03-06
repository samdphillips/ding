
require 'ding'

require 'stringio'

def setup_reader(s)
    Ding::Reader.new(Ding::BufIo.new(StringIO.new(s)))
end

class ReadExpectation
    def initialize(type, value, &matcher)
        @type = type
        @value = value
        @matcher = matcher
    end

    def matches?(reader)
        @term = reader.next_term
        @matcher.call(@term)
    end

    def failure_message
        "expected #{@type}[#{@value}], got #{@term.inspect}"
    end

    def negative_failure_message
        "expected #{@term.inspect} to not be #{@type}[#{@value}]"
    end
end

class CompoundReadExpectation
    class TermArrayReader
        def initialize(terms)
            @terms = terms
            @pos   = 0
        end

        def next_term
            if @pos == @terms.size then
                Ding::Terms::EofTerm.instance
            else
                i = @pos
                @pos += 1
                @terms[i]
            end
        end
    end

    def initialize(shape, &submatch)
        @shape = shape
        @submatch = submatch
    end

    def matches?(reader)
        @subject = reader.next_term
        @subject.compound_term? and shape_matches? and terms_match?
    end

    def shape_matches?
        @shape == @subject.shape
    end

    def terms_match?
        @submatch.call(TermArrayReader.new(@subject.terms))
    end

    def failure_message
        "#{@subject} did not match CompoundTerm with shape #{@shape}"
    end

    def negative_failure_message
        "#{@subject} should not match CompoundTerm with shape #{@shape}"
    end
end

def read_id(name)
    ReadExpectation.new('IdTerm', name) do | term |
        term.id_term? and term.name == name
    end
end

def read_eof
    ReadExpectation.new('EofTerm', nil) do | term |
        term.eof_term?
    end
end

def read_delimiter(name)
    ReadExpectation.new('DelimitTerm', name) do | term |
        term.delimit_term? and term.name == name
    end
end

def read_compound(shape, &submatch)
    CompoundReadExpectation.new(shape, &submatch)
end

describe Ding::Reader do
    it "should skip whitespace" do
        r = setup_reader('    ')
        r.should read_eof
    end

    it "should skip line comments" do
        r = setup_reader("  // this is a test \n")
        r.should read_eof
    end

    it "should skip line comments at the end of file" do
        r = setup_reader('  // this is a test')
        r.should read_eof
    end

    it "should skip block comments" do
        r = setup_reader('  /* this is a test */  ')
        r.should read_eof
    end

    it "should skip multiline block comments" do
        r = setup_reader("  /* this is a \n\n\n    test */   ")
        r.should read_eof
    end

    it "should skip a block comment with some stars in it" do
        r = setup_reader('  /* this is a ***  test */  ')
        r.should read_eof
    end

    it "should raise an error if a block comment is not closed" do
        r = setup_reader('   /* this is a ')
        lambda { r.next_term }.should raise_error(Ding::ReaderError)
    end

    it "should read a short id '  a  '" do
        r = setup_reader('  a  ')
        r.should read_id('a')
        r.should read_eof
    end

    it "should read a long id ' abc123_456 '" do
        r = setup_reader(' abc123_456 ')
        r.should read_id('abc123_456')
        r.should read_eof
    end

    it "should read a series of ids ' a b c '" do
        r = setup_reader(' a b c ')
        r.should read_id('a')
        r.should read_id('b')
        r.should read_id('c')
        r.should read_eof
    end

    it "should read a series of ids ' a + b '" do
        r = setup_reader(' a + b ')
        r.should read_id('a')
        r.should read_id('+')
        r.should read_id('b')
        r.should read_eof
    end

    it "should read a single id ' a+b '" do
        r = setup_reader(' a+b ')
        r.should read_id('a+b')
        r.should read_eof
    end

    it "should read a single id ' a-b '" do
        r = setup_reader(' a-b ')
        r.should read_id('a-b')
        r.should read_eof
    end

    it "should read a series of ids ' a = b + c '" do
        r = setup_reader(' a = b + c ')
        r.should read_id('a')
        r.should read_id('=')
        r.should read_id('b')
        r.should read_id('+')
        r.should read_id('c')
        r.should read_eof
    end

    it "should read a delimited term ' a,b '" do
        r = setup_reader(' a,b ')
        r.should read_id('a')
        r.should read_delimiter(',')
        r.should read_id('b')
        r.should read_eof
    end

    it "should read a delimited term ' a;b '" do
        r = setup_reader(' a;b ')
        r.should read_id('a')
        r.should read_delimiter(';')
        r.should read_id('b')
        r.should read_eof
    end

    it "should read a delimited term ' foo.bar.baz '" do
        r = setup_reader(' foo.bar.baz ')
        r.should read_id('foo')
        r.should read_delimiter('.')
        r.should read_id('bar')
        r.should read_delimiter('.')
        r.should read_id('baz')
        r.should read_eof
    end

    it "should read a compound term ' (a + b) '" do
        r = setup_reader(' (a + b) ')
        r.should read_compound(:paren) { |t|
            t.should read_id('a')
            t.should read_id('+')
            t.should read_id('b')
            t.should read_eof
        }
        r.should read_eof
    end

    it "should read a compound term ' (a, b, c) '" do
        r = setup_reader(' (a, b, c) ')
        r.should read_compound(:paren) { |t|
            t.should read_id('a')
            t.should read_delimiter(',')
            t.should read_id('b')
            t.should read_delimiter(',')
            t.should read_id('c')
            t.should read_eof
        }
        r.should read_eof
    end

    it "should read a compound term ' [a + b] '" do
        r = setup_reader(' [a + b] ')
        r.should read_compound(:square) { |t|
            t.should read_id('a')
            t.should read_id('+')
            t.should read_id('b')
            t.should read_eof
        }
        r.should read_eof
    end

    it "should read a compound term ' [a, b, c] '" do
        r = setup_reader(' [a, b, c] ')
        r.should read_compound(:square) { |t|
            t.should read_id('a')
            t.should read_delimiter(',')
            t.should read_id('b')
            t.should read_delimiter(',')
            t.should read_id('c')
            t.should read_eof
        }
        r.should read_eof
    end

    it "should read a compound term ' {a + b} '" do
        r = setup_reader(' {a + b} ')
        r.should read_compound(:curly) { |t|
            t.should read_id('a')
            t.should read_id('+')
            t.should read_id('b')
            t.should read_eof
        }
        r.should read_eof
    end

    it "should raise a reader error on unterminated compound term" do
        r = setup_reader(' { a ')
        expect { r.next_term }.to raise_error(Ding::ReaderError)
    end

    it "should read an empty compound term" do
        r = setup_reader('{ }')
        r.should read_compound(:curly) { |t|
            t.should read_eof
        }
        r.should read_eof
    end

    it "should read an compound term with spaces before closing brace" do
        r = setup_reader('{B }')
        r.should read_compound(:curly) { |t|
            t.should read_id('B')
            t.should read_eof
        }
        r.should read_eof
    end

end

