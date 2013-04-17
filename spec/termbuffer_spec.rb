
require 'ding'

include Ding::Terms

describe Ding::Terms::TermBuffer do
    it "should access terms in cache by index" do
        tb = described_class.new([:a, :b, :c], EmptyTermStream.instance)
        tb[0].should eql(:a)
        tb[1].should eql(:b)
        tb[2].should eql(:c)
    end

    it "should report at_end? when stream is exhausted (w/ EmptyTermStream)" do
        tb = described_class.new([:a, :b, :c], EmptyTermStream.instance)
        tb.should be_at_end
    end

    it "should report at_end? when stream is exhausted (w/ Reader)" do
        tb = described_class.new([:a, :b, :c], Ding::Reader.from_string(""))
        tb.should be_at_end
    end

    it "should take items from stream to satisfy indexed request" do
        reader = Ding::Reader.from_string("a b c")
        tb = described_class.new([], reader)
        tb[2].should be_id_term
        tb[2].name.should eql "c"

        tb[1].should be_id_term
        tb[1].name.should eql "b"

        tb[0].should be_id_term
        tb[0].name.should eql "a"
    end

    it "should raise an error for out of bounds requests" do
        tb = described_class.new([], EmptyTermStream.instance)
        expect { tb[0] }.to raise_error(OutOfBounds)
    end
end

