from __future__ import annotations

import multiprocessing as mp
import os
import re  # match string with regex
from collections.abc import Iterator

from .errors import err_notify

enc_candidate = ['utf-8', 'euc-kr', 'cp949', 'latin-1']

class Parser:
    file:str
    patterns:re.Pattern[str]
    encoding:str|None
    contents:str

    def __init__(self, file:str, patterns:re.Pattern[str]):
        r"""
        initialize variable at creation

        Args:
            file(str) : absolute file path to parse contents of it.
            pattern(re.Pattern) : regex pattern to parse contents
                                  If you want to parse multiple patterns,
                                  concatenate patterns with | to make one string.
                                  This pattern accept the result of re.compile()

        Caution:
            use pattern which captures one line until it meets \n.
            I thought that the overhead would be too high to send the structure like json which splits field by label
            in Python, so I decided to send a bunch of single line of raw data that means up to \n.
        """
        self.file = file
        self.patterns = patterns
        self.encoding = self.check_encoding()
        self.contents = self.get_file_contents() # don't slicing chunk

    def check_encoding(self, encodings:list[str]=enc_candidate) -> str|None:
        """ detect file encoding """
        if not os.path.exists(self.file):
            err_notify('There is no file : ' + self.file)
            return None

        with open(self.file, 'rb') as f:
            data = f.read(256) # about one line byte
            for enc in encodings:
                try:
                    # return data.decode(enc)
                    if data.decode(enc):
                        return enc
                except UnicodeEncodeError:
                    continue
        err_notify('This file encoding is not included in enc_candidate, Modify `enc_candidate` in ' + __file__ )
        return None

    def get_file_contents(self) -> str:
        """ get all contents of file """
        with open(self.file, 'r', encoding=(self.encoding or 'utf-8')) as f:
            contents = f.read()
        return contents

    def get_matches_chunk(self, chunk:str) -> list[str]:
        """
        get pattern from chunk

        Args:
            chunk(str) : part of file contents

        Return:
            result(list[str]]) : matched sentence
        """
        result:list[str] = []

        # Scan the entire chunk once with a err_regex, show match all at once
        # see repr() to confirm what escape character is included
        matcher: Iterator[re.Match[str]] = self.patterns.finditer(chunk)
        i = 0
        for match in matcher:

            msg = match.group().rstrip('\n') # remove \n at end of line
            msg = msg.replace('\n', '') # remove \n in the middle of message to make multi line to one line

            if match.lastgroup and (match.lastgroup.startswith('error')
                                    or match.lastgroup.startswith('warn_pdftex')):
                i+=1
            elif match.lastgroup and match.lastgroup.startswith('line'):
                for n in range(i):
                    if result[-1-n].startswith('!'): # ! l.xx ~
                        result[-1-n] = result[-1-n][:2] + msg + result[-1-n][1:]
                    elif result[-1-n].startswith('pdfTeX warning'): # pdfTex warning l.xx (ext4) ~
                        result[-1-n] = result[-1-n][:15] + msg + result[-1-n][14:]
                i = 0
                continue
            else: # warn
                pass

            result.append(msg)
            # group(0) : all word of matched with pattern that includes out of () (default)
            # group(1) : only included word in () at first time, next is group(2)

        return result

    def get_matches_all(self):
        """ get matches of pattern from all chunks """
        file_stack:list[str] = [] # stack to save file path which matcher meets.
        result:list[str] = [] # final result of error/warning pattern
        i = 0

        matcher: Iterator[re.Match[str]] = self.patterns.finditer(self.contents)
        for match in matcher:
            if match.lastgroup:
                # use group name to get captured word to remove \r\n from result automatically.
                msg = match.group(match.lastgroup)

                # push to last index of file stack
                if match.lastgroup.startswith('filestart'):
                    # default max_print_line is 79 on latex . It will make some paths Split into two lines.
                    # It prevent exact parsing of file. so you need to change this value upto 10000
                    # max length of Windows is 260, and it is 4096 in Linux
                    file_stack.append(msg) # stack all filestart. Error will belong to file unclosed parenthesis
                    continue
                # pop from last index of file stack
                elif match.lastgroup.startswith('fileend'):
                    if file_stack:
                        _ = file_stack.pop()
                    continue
                # error/warning post-process
                else:
                    if match.lastgroup.startswith('error') or match.lastgroup.startswith('warn_pdftex'):
                        i+=1
                    elif match.lastgroup.startswith('line'):
                        for n in range(i):
                            if result[-1-n].startswith('!'): # ! l.xx ~
                                result[-1-n] = result[-1-n][:2] + msg + result[-1-n][1:]
                            elif result[-1-n].startswith('pdfTeX warning'): # pdfTex warning l.xx (ext4) ~
                                result[-1-n] = result[-1-n][:15] + msg + result[-1-n][14:]
                        i = 0
                        continue
                    else: # warn
                        pass

                if file_stack:
                    result.append(file_stack[-1])
                result.append(msg)
        return result






