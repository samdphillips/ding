
require 'ding'

describe Ding::Terms::TermSequence do
    it "should respond true to empty when it contains nothing" do
        seq = described_class.from_array([])
        seq.should be_empty
    end

    it "should respond true to empty when it contains nothing" do
        seq = described_class.from_string('')
        seq.should be_empty
    end

    it "should return first from a completed state" do
        seq = described_class.from_array([:a, :b])
        seq.should_not be_empty
        seq.first.should eql(:a)
    end

    it "should return first from a pending state" do
        seq = described_class.from_string('a b')
        seq.should_not be_empty
        seq.first.name.should eql("a")
    end

    it "should return rest from a pending state" do
        seq = described_class.from_string('a b')
        seq.should_not be_empty
        seq.rest.first.name.should eql('b')
    end

    it "should return rest from a completed state" do
        seq = described_class.from_array([:a, :b])
        seq.should_not be_empty
        seq.rest.first.should eql(:b)
    end

    it "should raise an exception on getting the first of an empty sequence" do
        seq = described_class.from_array([])
        seq.should be_empty
        expect { seq.first }.to raise_error(Ding::Terms::TermSequenceEmpty)
    end

    it "should raise an exception on getting the rest of an empty sequence" do
        seq = described_class.from_array([])
        seq.should be_empty
        expect { seq.rest }.to raise_error(Ding::Terms::TermSequenceEmpty)
    end

    it "should raise an exception on getting the first of an empty pending sequence" do
        seq = described_class.from_string('')
        seq.should be_empty
        expect { seq.first }.to raise_error(Ding::Terms::TermSequenceEmpty)
    end

    it "should raise an exception on getting the rest of an empty pending sequence" do
        seq = described_class.from_string('')
        seq.should be_empty
        expect { seq.rest }.to raise_error(Ding::Terms::TermSequenceEmpty)
    end

end

