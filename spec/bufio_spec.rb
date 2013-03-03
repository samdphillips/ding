
require 'ding'
require 'stringio'

describe Ding::BufIo do
    before :each do
        sio = StringIO.new('abcd' * 8)
        @bufio = Ding::BufIo.new(sio)
    end

    it "should be able to read input chars normally" do
        @bufio.read(3).should == 'abc'
        @bufio.read(3).should == 'dab'
        @bufio.read(3).should == 'cda'
        @bufio.read(3).should == 'bcd'
    end

    it "should be able to peek chars without consuming them" do
        @bufio.peek(3).should == 'abc'
        @bufio.read(3).should == 'abc'

        @bufio.peek(3).should == 'dab'
        @bufio.read(3).should == 'dab'

        @bufio.peek(3).should == 'cda'
        @bufio.read(3).should == 'cda'

        @bufio.peek(3).should == 'bcd'
        @bufio.read(3).should == 'bcd'
    end

    it "should be able to peek chars before the buffer boundary"

    it "should be able to peek chars after the buffer boundary"

    it "should be able to peek chars across the buffer boundary"

    it "should be able to read across the buffer boundary"

    it "should flag that it is at the end of the stream"
end

