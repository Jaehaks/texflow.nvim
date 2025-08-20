#!/usr/bin/env python3
"""
SyncTeX Inverse Search Script for Neovim
Usage: python inverse_search.py <server_name> <tex_file> <line_number>
"""
import sys

from utils.commands import Commands
from utils.errors import err_notify
from utils.server import ServerManager


def main():
    """
    Inverse search from pdf file to tex file

    Args:
        filepath (str) : absolute path of tex file corresponding to pdf file
        line (int) : line number to go in tex file through inverse search
        alias (str, optional) : server name of neovim instance to access to open tex file
            It detects real v:servername of neovim from matched alias in server config file (textflow_server.json)
            The alias would be one of 3 cases.
            1) 'recent': It matched with the most recently opened neovim servername from server config file
            2) <servername> : If you know fullname of neovim server, you can use this directly.
            3) <filepath> : It matched with neovim server which opens some tex file.
                            If alias is empty, <filepath> will be chosen.

    Returns:
        None
    """
    # check argument is valid
    len_args = len(sys.argv)
    if len_args <= 2 or len_args >= 5:
        err_notify('The number of parameters not enough')
        sys.exit(1)

    filename = sys.argv[1]
    try:
        line = int(sys.argv[2])
    except ValueError as e:
        err_notify('A non-numeric argument was entered in place of the line number.', str(e))
        sys.exit(1)

    # set filename as servername if argument is void
    alias = sys.argv[3] if len_args == 4 else filename

    # connect to nvim instance and jump to line
    mg = ServerManager(None, alias) # get server instance
    cmd = Commands(mg.nvim)
    cmd.jump_to_line(filename, line)


if __name__ == "__main__":
    main()



"""
nvim = pynvim.attach() : pynvim.api.nvim.Nvim (Nvim class)
nvim.current.buffer : pynvim.api.buffer.Buffer(Buffer class) : get focused buffer handle (bufnr)
nvim.current.buffer.api : pynvim.api.common.RemoteApi : use neovim api about current buffer
    if buf = nvim.current.buffer
    dir(buf.api) doesn't show any function to use. It needs to find in vimdoc
    nvim_buf_is_valid(buffer) = buf.api.is_valid()  => `buf` will be used as argument
    nvim_buf_line_count(buffer) = buf.api.line_count()  => `buf` will be used as argument
nvim.command('echo "test"') : send command to nvim server instance, the output will be printed in neovim
nvim.command_output('echo "test"') : same with command() but the output will be printed in python not neovim
nvim.buffers : all buffer list from ls!, it is callable and can be used in for statement



"""
