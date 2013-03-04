
require 'ding'
require 'stringio'

describe Ding::BufIo do
    before :each do
        @s = 'abcd' * 8
        sio = StringIO.new(@s)
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

    it "should be able to peek chars before the buffer boundary" do
        @bufio.read(12)
        @bufio.peek(4).should == 'abcd'
    end

    it "should be able to peek chars after the buffer boundary" do
        @bufio.read(16)
        @bufio.peek(4).should == 'abcd'
    end

    (0..15).each do | off |
        len = (16 - off) * 2
        it "should be able to peek #{len} chars across the buffer boundary" do
            @bufio.read(off)
            @bufio.peek(len).should == @s[off,len]
            @bufio.peek(len).should == @s[off,len]
        end
    end

    (0..15).each do | off |
        len = (16 - off) * 2
        it "should be able to read #{len} chars across the buffer boundary" do
            @bufio.read(off)
            @bufio.read(len).should == @s[off,len]
            @bufio.read(1).should   == @s[off+len,1]
        end
    end

    it "should flag that it is at the end of the stream"
end

