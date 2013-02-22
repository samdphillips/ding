
class BufferedText:
    def __init__(self, io, bufsize=256):
        self.io = io
        self.bufpos = 0
        self.bufsize = bufsize
        self.buffers = []

    def chars_avail(self):
        return sum([len(s) for s in self.buffers]) - self.bufpos

    def fill(self, n):
        while n > self.chars_avail():
            buf = self.io.read(self.bufsize)
            self.buffers.append(buf)
            if buf == '':
                break

    def init_buffer_finished(self):
        return self.bufpos >= len(self.buffers[0])

    def cleanup(self):
        if self.init_buffer_finished():
            self.bufpos = self.bufpos - len(self.buffers[0])
            self.buffers = self.buffers[1:]

    def at_end(self):
        return self.read_peek(1, False) == ''

    def build_string(self, n):
        p = self.bufpos
        s = ''
        for buf in self.buffers:
            if p + n < len(buf):
                s += buf[p:p+n]
                break
            else:
                b = buf[p:]
                s += b
                n -= len(b)
                p = 0
        return s

    def read_peek(self, n, commit):
        self.fill(n)
        self.cleanup()
        s = self.build_string(n)
        if commit:
            self.bufpos = self.bufpos + len(s)
            self.cleanup()
        return s
        
    def read(self, n):
        return self.read_peek(n, True)

    def peek(self, n):
        return self.read_peek(n, False)

import io
import unittest
class TestBufferedText(unittest.TestCase):
    def setUp(self):
        s = "abcdefghijklmnopqrstuvwxyz" * 20
        self.buf = BufferedText(io.StringIO(s))

    def assert_read_chars(self, chars):
        self.assertEqual(self.buf.read(len(chars)), chars)

    def assert_peek_chars(self, chars):
        self.assertEqual(self.buf.peek(len(chars)), chars)

    def test_read_small(self):
        self.assert_read_chars("abcd")
        self.assert_read_chars("efgh")
        self.assert_read_chars("ijkl")
        self.assert_read_chars("mnop")

    def test_peek_small(self):
        self.assert_peek_chars("abcd")
        self.assert_read_chars("abcd")

        self.assert_peek_chars("efgh")
        self.assert_read_chars("efgh")

        self.assert_peek_chars("ijkl")
        self.assert_read_chars("ijkl")

        self.assert_peek_chars("mnop")
        self.assert_read_chars("mnop")

    def test_read_before_boundary(self):
        self.buf.read(250)
        self.assert_read_chars('qrstuv')

    def test_read_after_boundary(self):
        self.buf.read(256)
        self.assert_read_chars('wxyzab')

    def test_read_across_boundary(self):
        self.buf.read(250)
        self.assert_read_chars('qrstuvwxyzab')

    def test_peek_before_boundary(self):
        self.buf.read(250)
        self.assert_peek_chars('qrstuv')
        self.assert_read_chars('qrstuv')

    def test_peek_after_boundary(self):
        self.buf.read(256)
        self.assert_peek_chars('wxyzab')
        self.assert_read_chars('wxyzab')

    def test_peek_across_boundary(self):
        self.buf.read(250)
        self.assert_peek_chars('qrstuvwxyzab')
        self.assert_read_chars('qrstuvwxyzab')

    def test_big_read(self):
        self.buf.read(260)
        self.assert_read_chars('abcd')

    def test_read_at_end(self):
        self.buf.read(26 * 20 - 13)
        self.assert_read_chars('nopqrstuvwxyz')
        self.assertTrue(self.buf.at_end())


