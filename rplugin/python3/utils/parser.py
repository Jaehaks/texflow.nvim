from __future__ import annotations

import multiprocessing as mp
import os
import re  # match string with regex
from collections.abc import Iterator

from .errors import err_notify

enc_candidate = ['utf-8', 'euc-kr', 'cp949', 'latin-1']

class Parser:
    file:str
    pattern:re.Pattern[str]
    num_cores:int
    encoding:str|None
    chunks:list[str]

    def __init__(self, file:str, pattern:re.Pattern[str]):
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
        self.pattern = pattern
        self.num_cores = mp.cpu_count()              # Automatically detects the number of system CPU cores
        self.encoding = self.check_encoding()
        self.chunks = self.get_file_chunks()

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

    def get_file_chunks(self) -> list[str]:
        """Splits the file into chunks according to the number of cpu cores and returns a list of chunks."""
        with open(self.file, 'rb') as f:         # read file using bytecode for speed
            file_size = os.fstat(f.fileno()).st_size # file size [bytes]
            chunk_size:int = file_size // self.num_cores
            chunks: list[str] = []

            for i in range(self.num_cores):
                start = i * chunk_size                  # set chuck boundary
                end = start + chunk_size if i < self.num_cores - 1 else file_size

                _ = f.seek(start)                       # Move focus to the start of the chunk
                contents = f.read(end - start)          # read chunks
                if i < self.num_cores - 1:
                    contents += f.readline()            # read residue of the last line

                chunks.append(contents.decode(self.encoding or 'utf-8')) # decode byte buffer to text
        return chunks

    def get_matches_chunk(self, chunk:str) -> list[str]:
        """
        get pattern from chunk

        Args:
            chunk(str) : part of file contents
        """
        result:list[str] = []

        # Scan the entire chunk once with a err_regex, show match all at once
        matcher: Iterator[re.Match[str]] = self.pattern.finditer(chunk)
        for match in matcher:
            msg = match.group().rstrip('\n') # remove \n at end of line
            msg = msg.replace('\n', '') # remove \n in the middle of message to make multi line to one line
            result.append(msg)
            # group(0) : all word of matched with pattern that includes out of () (default)
            # group(1) : only included word in () at first time, next is group(2)

        return result

    def get_matches_all(self):
        """ get matches of pattern from all chunks """
        # Creating a parallel pool and assigning tasks
        with mp.Pool(processes=self.num_cores) as pool:
            results_all = pool.map(self.get_matches_chunk, self.chunks) # nested list is return

        # Merge all chunk results into one list
        result = [item for sublist in results_all for item in sublist]
        return result

