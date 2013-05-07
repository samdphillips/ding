
require 'ding'

def make_sequence(s)
    Ding::Reader.from_string(s).as_term_sequence
end

describe Ding::Terms::Patterns::Builder do
    it "should match nothing with an empty pattern" do
        pat = described_class.build do 
        end

        seq = make_sequence("class A { }")
        match = pat.match(seq)
        match.should be_success
        match.rest.first.should eql(seq.first)
    end

    it "should match an id term" do
        pat = described_class.build do 
            term_id
        end

        seq = make_sequence("class A { }")
        match = pat.match(seq)

        match.should be_success
        match.rest.first.name.should eql("A")
    end

    it "should match an id term by name" do
        pat = described_class.build do 
            term_id('class')
        end

        seq = make_sequence("class A { }")
        match = pat.match(seq)

        match.should be_success
        match.rest.first.name.should eql("A")
    end

    it "should not match an id term with the wrong name" do
        pat = described_class.build do 
            term_id('var')
        end

        seq = make_sequence("class A { }")
        match = pat.match(seq)

        match.should_not be_success
    end

    it "should not match an id term with the wrong name" do
        pat = described_class.build do 
            term_id('class')
            term_id('B')
        end

        seq = make_sequence("class A { }")
        match = pat.match(seq)

        match.should_not be_success
    end

    it "should not match an empty sequence with a non empty pattern" do
        pat = described_class.build do 
            term_id('class')
        end

        seq = make_sequence("")
        match = pat.match(seq)

        match.should_not be_success
    end

    it "should bind a term to a name in the match" do
        pat = described_class.build do 
            term_id('class')
            bind_id(:classname)
        end

        seq = make_sequence("class A { }")
        match = pat.match(seq)

        match.should be_success
        match.binding[:classname].name.should eql('A')
    end

    it "should match a pattern built from other patterns"

    it "should match a pattern with an empty block" do
        pat = described_class.build do
            term_id('class')
            bind_id(:classname)
            term_block do
            end
        end

        seq = make_sequence("class A { }")
        match = pat.match(seq)

        match.should be_success
        match.rest.should be_empty
    end

end

