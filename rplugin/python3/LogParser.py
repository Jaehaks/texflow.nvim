import os
import re
import sys

from utils.errors import err_notify
from utils.parser import Parser


def main():

    if len(sys.argv) != 2:
        err_notify('LogParser must have 1 argument : *.log file path')
        sys.exit(1)

    file = sys.argv[1]
    if not os.path.exists(file):
        err_notify('LogParse cannot find the log file : ' + file)
        sys.exit(1)


    # error/warning patterns of latex log file
    # use $ to get all sentence without \n
    # (?:a) includes a
    # (?=a) not includes a
    # add \.(?:\n|$) to detect multiline message, It detects dot is the last of sentence.
    # but some warning like 'pdfTeX warning', doesn't have a dot at end of sentence.
    patterns = {
        # "filestart": r'\((?P<filestart>[^\)\(\n]*)(?:\n|$)', it has problem.
        # 1) capture ends until (,),\n with [^\)\(\n]*
        # 2) and check the next character is ended with \n or $ with (?:\n|$).
        # if the text is (./some/path/file),  it captures until (./some/path/file, and next character is ), not \n|$.
        # so this whole matching line will be discard.

        # filestart : Capture from the opening parenthesis until the closing parenthesis ')' or \n appears.
        # start with '(' at anywhere, capture any word except of ')' and '\n'
        # [^\)\(*] means the capture will be end before (,), the (,) won't be included in capture group(0).
        # so the next match will starts from (,). it makes next match can capture <fileend>.
        # (?:\n|$) means the capture will be end before \n|$, but \n|$ are included in capture group(0).
        # the next match will starts from next character of \n|$.
        # "filestart": r'\((?P<filestart>[^\)\(\n]*)(?:\(|\)|\n|$)',
        "filestart": r'(?P<filestart>\([^\)\(\n]*)\n?',
        # "filestart": r'\((?P<filestart>[^\)\(\n]*)',
        "fileend": r'(?P<fileend>[\)])',                                 # fileend : capture all ')'
        "error1": r'^(?P<error1>[^\n]*\.tex:\d+:.*?\.)(?:\n|$)',         # test2.tex:42: LaTeX Error: ~
        # <error2> : ! LaTeX Error: message
        # It captures all strings from '!' to \n or $ after dot(.).
        # '.*?' means non-greedy capture '.*' + '?'. because '.*' means greedy capture which captures more than one line.
        "error2": r'^(?P<error2>! .*?\.)(?:\n|$)',                       # ! LaTeX Error: ~
        # <line> : l.21 \beigne~
        # capture <l.21> only, \b is added to distinguish word boundary.
        # If \b doesn't exist, \w word right after l.21 will be captured. the line number always add white space.
        "line": r'^(?P<line>l\.\d+)\b',                                  # l.21 ~
        "warn_latex": r'^(?P<warn_latex>LaTeX Warning:.*?\.)(?:\n|$)',   # LaTeX Warning: There were undefined references.
        # Package <name> Warning: messages,
        # It can be multiple sentences with starting '(name)', so the end condition must be \n\n
        "warn_pkg": r'^(?P<warn_pkg>Package \w+ Warning:.*?\.)(?:\n\n|\n$)',
        "warn_pdftex": r'^(?P<warn_pdftex>pdfTeX warning.*?)(?=\s{3,})', # pdfTex warning (ext4): ~ end with multiple white spaces
        # <warn_toc> : warning (pdf backend) : ~~ \n[1
        # it capture until \[ but excludes \n or $
        "warn_toc": r'^(?P<warn_toc>warning.*?)(?:\n|$)(?=\[)', # pdfTex warning (ext4): ~ end with multiple white spaces
        "warn_over": r'^(?P<warn_over>(Overfull|Underfull).*?)(?:\n|$)(?=\[)',   # 'overfull|underfull' to before ~ 59--60 []
    }

    combined_patterns = r'|'.join(f"{pattern}" for pattern in patterns.values()) # combine patterns to string with '|',
    err_regex  = re.compile(combined_patterns, re.MULTILINE|re.DOTALL) # make compile command to re-usability
    # re.MULTILINE makes '$' means end of line, not end of document, '\Z' means end of document.
    # If not re.MULTILINE, '$' means end of document.

    p = Parser(file, err_regex)
    result = p.get_matches_all()
    result = '\n'.join(result)
    print(result)


if __name__ == '__main__':
    main()
