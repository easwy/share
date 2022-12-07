# -*- coding: utf-8    # This file contains Unicode characters.

from textwrap import dedent

import pytest

from parso._compatibility import py_version
from parso.utils import split_lines, parse_version_string
from parso.python.token import PythonTokenTypes
from parso.python import tokenize
from parso import parse
from parso.python.tokenize import PythonToken


# To make it easier to access some of the token types, just put them here.
NAME = PythonTokenTypes.NAME
NEWLINE = PythonTokenTypes.NEWLINE
STRING = PythonTokenTypes.STRING
INDENT = PythonTokenTypes.INDENT
DEDENT = PythonTokenTypes.DEDENT
ERRORTOKEN = PythonTokenTypes.ERRORTOKEN
OP = PythonTokenTypes.OP
ENDMARKER = PythonTokenTypes.ENDMARKER
ERROR_DEDENT = PythonTokenTypes.ERROR_DEDENT
FSTRING_START = PythonTokenTypes.FSTRING_START


def _get_token_list(string):
    # Load the current version.
    version_info = parse_version_string()
    return list(tokenize.tokenize(string, version_info))


def test_end_pos_one_line():
    parsed = parse(dedent('''
    def testit():
        a = "huhu"
    '''))
    simple_stmt = next(parsed.iter_funcdefs()).get_suite().children[-1]
    string = simple_stmt.children[0].get_rhs()
    assert string.end_pos == (3, 14)


def test_end_pos_multi_line():
    parsed = parse(dedent('''
    def testit():
        a = """huhu
    asdfasdf""" + "h"
    '''))
    expr_stmt = next(parsed.iter_funcdefs()).get_suite().children[1].children[0]
    string_leaf = expr_stmt.get_rhs().children[0]
    assert string_leaf.end_pos == (4, 11)


def test_simple_no_whitespace():
    # Test a simple one line string, no preceding whitespace
    simple_docstring = '"""simple one line docstring"""'
    token_list = _get_token_list(simple_docstring)
    _, value, _, prefix = token_list[0]
    assert prefix == ''
    assert value == '"""simple one line docstring"""'


def test_simple_with_whitespace():
    # Test a simple one line string with preceding whitespace and newline
    simple_docstring = '  """simple one line docstring""" \r\n'
    token_list = _get_token_list(simple_docstring)
    assert token_list[0][0] == INDENT
    typ, value, start_pos, prefix = token_list[1]
    assert prefix == '  '
    assert value == '"""simple one line docstring"""'
    assert typ == STRING
    typ, value, start_pos, prefix = token_list[2]
    assert prefix == ' '
    assert typ == NEWLINE


def test_function_whitespace():
    # Test function definition whitespace identification
    fundef = dedent('''
    def test_whitespace(*args, **kwargs):
        x = 1
        if x > 0:
            print(True)
    ''')
    token_list = _get_token_list(fundef)
    for _, value, _, prefix in token_list:
        if value == 'test_whitespace':
            assert prefix == ' '
        if value == '(':
            assert prefix == ''
        if value == '*':
            assert prefix == ''
        if value == '**':
            assert prefix == ' '
        if value == 'print':
            assert prefix == '        '
        if value == 'if':
            assert prefix == '    '


def test_tokenize_multiline_I():
    # Make sure multiline string having newlines have the end marker on the
    # next line
    fundef = '''""""\n'''
    token_list = _get_token_list(fundef)
    assert token_list == [PythonToken(ERRORTOKEN, '""""\n', (1, 0), ''),
                          PythonToken(ENDMARKER ,       '', (2, 0), '')]


def test_tokenize_multiline_II():
    # Make sure multiline string having no newlines have the end marker on
    # same line
    fundef = '''""""'''
    token_list = _get_token_list(fundef)
    assert token_list == [PythonToken(ERRORTOKEN, '""""', (1, 0), ''),
                          PythonToken(ENDMARKER,      '', (1, 4), '')]


def test_tokenize_multiline_III():
    # Make sure multiline string having newlines have the end marker on the
    # next line even if several newline
    fundef = '''""""\n\n'''
    token_list = _get_token_list(fundef)
    assert token_list == [PythonToken(ERRORTOKEN, '""""\n\n', (1, 0), ''),
                          PythonToken(ENDMARKER,          '', (3, 0), '')]


def test_identifier_contains_unicode():
    fundef = dedent('''
    def 我あφ():
        pass
    ''')
    token_list = _get_token_list(fundef)
    unicode_token = token_list[1]
    if py_version >= 30:
        assert unicode_token[0] == NAME
    else:
        # Unicode tokens in Python 2 seem to be identified as operators.
        # They will be ignored in the parser, that's ok.
        assert unicode_token[0] == OP


def test_quoted_strings():
    string_tokens = [
        'u"test"',
        'u"""test"""',
        'U"""test"""',
        "u'''test'''",
        "U'''test'''",
    ]

    for s in string_tokens:
        module = parse('''a = %s\n''' % s)
        simple_stmt = module.children[0]
        expr_stmt = simple_stmt.children[0]
        assert len(expr_stmt.children) == 3
        string_tok = expr_stmt.children[2]
        assert string_tok.type == 'string'
        assert string_tok.value == s


def test_ur_literals():
    """
    Decided to parse `u''` literals regardless of Python version. This makes
    probably sense:

    - Python 3+ doesn't support it, but it doesn't hurt
      not be. While this is incorrect, it's just incorrect for one "old" and in
      the future not very important version.
    - All the other Python versions work very well with it.
    """
    def check(literal, is_literal=True):
        token_list = _get_token_list(literal)
        typ, result_literal, _, _ = token_list[0]
        if is_literal:
            if typ != FSTRING_START:
                assert typ == STRING
                assert result_literal == literal
        else:
            assert typ == NAME

    check('u""')
    check('ur""', is_literal=not py_version >= 30)
    check('Ur""', is_literal=not py_version >= 30)
    check('UR""', is_literal=not py_version >= 30)
    check('bR""')
    # Starting with Python 3.3 this ordering is also possible.
    if py_version >= 33:
        check('Rb""')

    # Starting with Python 3.6 format strings where introduced.
    check('fr""', is_literal=py_version >= 36)
    check('rF""', is_literal=py_version >= 36)
    check('f""', is_literal=py_version >= 36)
    check('F""', is_literal=py_version >= 36)


def test_error_literal():
    error_token, endmarker = _get_token_list('"\n')
    assert error_token.type == ERRORTOKEN
    assert error_token.string == '"'
    assert endmarker.type == ENDMARKER
    assert endmarker.prefix == '\n'

    bracket, error_token, endmarker = _get_token_list('( """')
    assert error_token.type == ERRORTOKEN
    assert error_token.prefix == ' '
    assert error_token.string == '"""'
    assert endmarker.type == ENDMARKER
    assert endmarker.prefix == ''


def test_endmarker_end_pos():
    def check(code):
        tokens = _get_token_list(code)
        lines = split_lines(code)
        assert tokens[-1].end_pos == (len(lines), len(lines[-1]))

    check('#c')
    check('#c\n')
    check('a\n')
    check('a')
    check(r'a\\n')
    check('a\\')


@pytest.mark.parametrize(
    ('code', 'types'), [
        (' foo', [INDENT, NAME, DEDENT]),
        ('  foo\n bar', [INDENT, NAME, NEWLINE, ERROR_DEDENT, NAME, DEDENT]),
        ('  foo\n bar \n baz', [INDENT, NAME, NEWLINE, ERROR_DEDENT, NAME,
                                NEWLINE, ERROR_DEDENT, NAME, DEDENT]),
        (' foo\nbar', [INDENT, NAME, NEWLINE, DEDENT, NAME]),
    ]
)
def test_indentation(code, types):
    actual_types = [t.type for t in _get_token_list(code)]
    assert actual_types == types + [ENDMARKER]


def test_error_string():
    t1, endmarker = _get_token_list(' "\n')
    assert t1.type == ERRORTOKEN
    assert t1.prefix == ' '
    assert t1.string == '"'
    assert endmarker.prefix == '\n'
    assert endmarker.string == ''
