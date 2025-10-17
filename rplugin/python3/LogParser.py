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
        "error1": r'^(?P<error1>[^\n]*\.tex:\d+:.*?)\.(?:\n|$)',         # test2.tex:42: LaTeX Error: ~
        "error2": r'^! (?P<error2>.*?)\.(?:\n|$)',                       # ! LaTeX Error: ~
        "line": r'^l\.(?P<line>\d+)\b',                                  # l.21 ~
        "warn_latex": r'^(?P<warn_latex>LaTeX Warning:.*?)\.(?:\n|$)',   # LaTeX Warning: There were undefined references.
        "warn_over": r'^(Overfull|Underfull)(?P<warn_over>.*?)(?=\[)',   # 'overfull|underfull' to before ~ 59--60
        "warn_pkg": r'^(?P<warn_pkg>Package \w+ Warning:.*?)\.(?:\n|$)', # Package warning
        "warn_pdftex": r'^(?P<warn_pdftex>pdfTeX warning.*?)(?=\s{3,})', # pdfTex warning (ext4): ~ end with multiple white spaces
    }

    combined_patterns = r'|'.join(f"{pattern}" for pattern in patterns.values()) # combine patterns to string with '|',
    err_regex  = re.compile(combined_patterns, re.MULTILINE|re.DOTALL) # make compile command to re-usability

    p = Parser(file, err_regex)
    result = p.get_matches_all()
    result = '\n'.join(result)
    print(result)


if __name__ == '__main__':
    main()
