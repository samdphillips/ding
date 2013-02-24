
class Term:
    def is_eof_term(self):
        return False

class _EofTerm(Term):
    def is_eof_term(self):
        return True

eof_term = _EofTerm()

class ReaderError(Exception):
    def __init__(self, actual, expected):
        self.actual = actual
        self.expected = expected

    def __str__(self):
        return "Expected {}, got {}".format(self.expected, self.actual)

class Reader:
    def __init__(self, io):
        self.io = io

    def eof_error(self, expected):
        raise ReaderError('eof', expected)

    def skip_space(self):
        while True:
            c = self.io.peek(1)
            if c.isspace():
                self.io.read(1)
            elif c == '/':
                s = self.io.peek(2)
                if s == '//':
                    self.skip_line_comment()
                elif s == '/*':
                    self.skip_block_comment()
                else:
                    break
            else:
                break

    def skip_line_comment(self):
        self.io.read(2)

        if self.io.at_end():
            return

        c = self.io.peek(1)
        while c != '\n':
            self.io.read(1)
            if self.io.at_end():
                return
            c = self.io.peek(1)

    def skip_block_comment(self):
        self.io.read(2)

        if self.io.at_end():
            ## XXX testme
            self.eof_error('comment end "*/"')

        while True:
            s = self.io.peek(2)

            if s == '*/':
                self.io.read(2)
                return
            elif s[1] == '*':
                self.io.read(1)
            else:
                self.io.read(2)

            if self.io.at_end():
                self.eof_error('comment end "*/"')


    def next_term(self):
        self.skip_space()
        
        if self.io.at_end():
            return eof_term


from io import StringIO
import unittest
import ding.io

class TestReader(unittest.TestCase):
    def setup_reader(self, s):
        sio = StringIO(s)
        io = ding.io.BufferedText(sio)
        return Reader(io)

    def assert_next_eof(self, r):
        t = r.next_term()
        self.assertTrue(t.is_eof_term())

    def assert_next_error(self, r):
        thrown = False
        try:
            r.next_term()
        except ReaderError:
            thrown = True
        self.assertTrue(thrown)

    def test_read_empty(self):
        r = self.setup_reader('     ')
        self.assert_next_eof(r)

    def test_read_line_comment(self):
        r = self.setup_reader('  // this is a test \n')
        self.assert_next_eof(r)

    def test_read_line_comment_eof(self):
        r = self.setup_reader('  // this is a test')
        self.assert_next_eof(r)

    def test_read_block_comment_eof(self):
        r = self.setup_reader('  /* this is a test */  ')
        self.assert_next_eof(r)

    def test_read_block_comment_pad_eof(self):
        r = self.setup_reader('  /* this is a  test */  ')
        self.assert_next_eof(r)

    def test_read_block_comment_multiline(self):
        r = self.setup_reader('  /* this is a\n\n\ntest */  ')
        self.assert_next_eof(r)

    def test_read_block_comment_stars_eof(self):
        r = self.setup_reader('  /* this is a ***  test */  ')
        self.assert_next_eof(r)

    def test_read_block_comment_error1(self):
        r = self.setup_reader('  /*')
        self.assert_next_error(r)

    def test_read_block_comment_error2(self):
        r = self.setup_reader('  /*  ')
        self.assert_next_error(r)
