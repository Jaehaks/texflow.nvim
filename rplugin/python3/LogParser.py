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
    # add \.(?:\n|$) to detect multiline message
    patterns = {
        "error": r'^([^\n]*\.tex:\d+:.*?)\.(?:\n|$)', # test2.tex:42: LaTeX Error: Can be used only in preamble.
        "warn_latex": r'^(LaTeX Warning:.*?)\.(?:\n|$)', # LaTeX Warning: There were undefined references.
        "warn_over": r'^(Overfull|Underfull)(.*?)(?=\[)', # 'overfull|underfull' to before [  (group(0) needs)
        "warn_pkg": r'^(Package \w+ Warning:.*?)\.(?:\n|$)',
    }

    combined_patterns = r'|'.join(f"{pattern}" for pattern in patterns.values()) # combine patterns to string with '|',
    err_regex  = re.compile(combined_patterns, re.MULTILINE|re.DOTALL) # make compile command to re-usability

    p = Parser(file, err_regex)
    result = p.get_matches_all()
    result = '\n'.join(result)
    print(result)


if __name__ == '__main__':
    main()
