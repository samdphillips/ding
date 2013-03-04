
require 'ding'

class Contain
    def initialize(char)
        @char = char
    end

    def matches?(charset)
        @charset = charset
        @charset.contains(@char)
    end

    def description
        "contains #{@char}"
    end

    def failure_message
        "expected #{@charset} to contain #{@char}"
    end

    def negative_failure_message
        "expected #{@charset} to not contain #{@char}"
    end
end

def contain(char)
    Contain.new(char)
end

def alnum
    (?0..?9).each { | c | yield c }
    (?a..?z).each { | c | yield c }
    (?A..?Z).each { | c | yield c }
end

describe Ding::Charset do

    (?a..?z).each do | char |
        it "should contain #{char} when created with '[[:alpha:]]'" do
            cs = Ding::Charset.new('[[:alpha:]]')
            cs.should contain(char)
        end

        it "should contain #{char} when created with /[[:alpha:]]/" do
            cs = Ding::Charset.new(/[[:alpha:]]/)
            cs.should contain(char)
        end

        it "should not contain #{char} when created with /\d/" do
            cs = Ding::Charset.new(/\d/)
            cs.should_not contain(char)
        end
    end

    alnum do | char |
        it "should contain #{char} when composed from an alpha charset and digit charset"  do
            charset = Ding::Charset.new(/[[:alpha:]]/) + Ding::Charset.new(/[[:digit:]]/)
            charset.should contain(char)
        end
    end
end

