
module Ding
    class BufIo
        def initialize(io)
            @io = io
            @bufpos = 0
            @buffers = []
        end

        def chars_available
            (@buffers.reduce(0) { | sum, buf | sum + buf.size }) - @bufpos
        end

        def init_buffer_empty?
            @buffers.size > 0 and @bufpos > (@buffers[0].size - 1)
        end

        def fill(count)
            while chars_available < count do
                buf = @io.read(16)
                if buf.nil? then
                    break
                else
                    @buffers << buf
                end
            end
        end

        def cleanup
            if init_buffer_empty? then
                @bufpos -= @buffers[0].size
                @buffers.shift
            end
        end

        def build_string(count)
            pos = @bufpos
            s = ''
            @buffers.each do | buf |
                if pos + count < buf.size then
                    return s << buf[pos,count]
                else
                    len = buf.size - pos
                    s << buf[pos,len]
                    count -= len
                    pos = 0 
                end
            end
            s
        end

        def at_end?
            read_peek(1, false) == ''
        end

        def read_peek(count, commit)
            fill(count)
            cleanup
            s = build_string(count)
            if commit then
                @bufpos += s.size
                cleanup
            end
            s
        end

        def read(count)
            read_peek(count, true)
        end

        def peek(count)
            read_peek(count, false)
        end
    end
end

