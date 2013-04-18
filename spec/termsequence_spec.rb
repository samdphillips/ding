
require 'ding'

describe Ding::Terms::TermSequence do
    it "should respond true to empty when it contains nothing" do
        buf =  TermBuffer.new([], EmptyTermStream.instance)
        seq = described_class.new(0, buf)
        seq.should be_empty
    end

    it "should respond true to empty when it has exhausted terms" do
        buf = TermBuffer.new([:a,:b,:c], EmptyTermStream.instance)
        seq = described_class.new(3, buf)
        seq.should be_empty
    end

    it "should reference the first item" do
        buf = TermBuffer.new([:a,:b,:c], EmptyTermStream.instance)
        seq = described_class.new(0, buf)
        seq.should_not be_empty
        seq.first.should eql(:a)
    end

    it "should return a new sequence for rest" do
        buf = TermBuffer.new([:a,:b,:c], EmptyTermStream.instance)
        seq1 = described_class.new(0, buf)
        seq1.should_not be_empty

        seq2 = seq1.rest
        seq2.first.should eql(:b)
        seq2.should_not be_empty
    end

    it "should return an empty sequence for rest when terms are exhausted" do
        buf = TermBuffer.new([:a,:b], EmptyTermStream.instance)
        seq1 = described_class.new(0, buf)
        seq1.should_not be_empty

        seq2 = seq1.rest
        seq2.first.should eql(:b)
        seq2.should_not be_empty

        seq2.rest.should be_empty
    end

    it "should raise an exception on getting the first of an empty sequence" do
        buf = TermBuffer.new([], EmptyTermStream.instance)
        seq = described_class.new(0, buf)
        seq.should be_empty
        expect { seq.first }.to raise_error
    end

    it "should raise an exception on getting the rest of an empty sequence" do
        buf = TermBuffer.new([], EmptyTermStream.instance)
        seq = described_class.new(0, buf)
        seq.should be_empty
        expect { seq.rest }.to raise_error(TermSequenceEmpty)
    end

end

