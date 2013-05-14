
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
        match.bindings[:classname].name.should eql('A')
    end

    it "should match a pattern built from other patterns" do
        p1 = described_class.build do
            term_id('class')
            bind_id(:classname)
        end

        p2 = described_class.build do
            match_pattern(p1)
            match_pattern(p1)
        end

        seq1 = make_sequence("class A class B")
        m1 = p2.match(seq1)
        m1.should be_success
        m1.rest.should be_empty
        m1.bindings[:classname].name.should eql("B")

        seq2 = make_sequence("class A {}")
        m2 = p2.match(seq2)
        m2.should_not be_success
    end

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

    it "should match a pattern with a binding in a block" do
        pat = described_class.build do
            term_id('class')
            bind_id(:classname)
            term_block do
                bind_id(:inside)
            end
        end

        seq = make_sequence("class A { B }")
        match = pat.match(seq)

        match.should be_success
        match.rest.should be_empty
        match.bindings[:classname].name.should eql('A')
        match.bindings[:inside].name.should eql('B')
    end

    it "should match a repeated pattern" do
        pat = described_class.build do
            repeatedly do
                bind_id(:type)
                bind_id(:varname)
                term_delimit(';')
            end
        end

        seq = make_sequence('String s; Integer i; Float f;')
        match = pat.match(seq)
        match.should be_success
        match.rest.should be_empty

        match.bindings[:type].collect {|x| x.name }.should eql(['String', 'Integer', 'Float'])
        match.bindings[:varname].collect {|x| x.name }.should eql(['s', 'i', 'f'])
    end

end

