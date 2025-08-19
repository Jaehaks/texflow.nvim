import json
import os
import re  # match string with regex
import sys
from pathlib import Path  # supports expandvars automatically
from typing import cast

import pynvim

from .errors import err_notify

# get config file to save mapping data
xdg_data_home = os.getenv('XDG_DATA_HOME')
server_file:Path
if xdg_data_home is None:
    server_file = Path.home() / '.local' / 'share' / 'nvim-data' / 'texflow' / 'texflow_server.json'
else:
    if sys.platform == 'win32':
        server_file = Path(xdg_data_home) / 'nvim-data' / 'texflow' / 'texflow_server.json'
    else:
        server_file = Path(xdg_data_home) / 'nvim' / 'texflow' / 'texflow_server.json'

@pynvim.plugin
class ServerManager:
    server_file:    Path
    mapping_result: dict[str, str]
    nvim:           pynvim.Nvim # declare pynvim.Nvim as type of nvim
    servername:     str

    # def __init__(self, nvim:pynvim.Nvim, alias:str='', server_file:Path=server_file):
    def __init__(self, nvim:pynvim.Nvim|None=None, alias:str=''):
        """ initialize variable at creation"""
        self.server_file = server_file
        self.mapping_result = self.load_server_mapping()
        if nvim is not None:
            self.nvim = nvim # for python integration in neovim lua
        else:
            self.nvim = self.get_server(alias) # for external command
        self.servername = self.nvim.vvars['servername']

    # @pynvim.function : args will be empty list if args is nil in lua.
    # @pynvim.function : Function name must start with uppercase or neovim cannot recognize this function
    @pynvim.function('Texflow_save_server_mapping', sync=True)
    def save_server_mapping(self, args: list[str]|None = None):
        """
        save server mapping data to json file
        Args:
            args(list[str]) : only one string is required if you call it from lua.
                              It will be a key in mapping_result dictionary
                              and the value is servername of current neovim instance
        """
        if args:
            self.mapping_result[args[0]] = self.nvim.vvars['servername']
        try:
            self.server_file.parent.mkdir(parents=True, exist_ok=True) # mkdir if not exists
            with open(self.server_file, 'w', encoding='utf-8') as f:
                json.dump(self.mapping_result, f, indent=4) # write dictionary data to json file with json format
        except IOError as e:
            err_notify('cannot open config file to save data', str(e))

        # self.nvim.vars[] = get 'vim.g' variable
        # self.nvim.vvars[] = get 'vim.v' variable

        # you need to distinguish options category strictly
        # self.nvim.current.buffer.options[] = get 'vim.bo' option
        # self.nvim.current.window.options[] = get 'vim.wo' option
        # self.nvim.options[] = get 'vim.go' option

    @pynvim.function('Texflow_load_server_mapping', sync=True)
    def load_server_mapping(self, args: list[str]|None=None) -> dict[str, str]:
        """ load server mapping data from json file """
        if self.server_file.exists():
            try:
                with open(self.server_file, 'r') as f:
                    return cast(dict[str, str], json.load(f)) # read json file
            except (json.JSONDecodeError, IOError) as e:
                err_notify('cannot open config file to load data', str(e))
                return {}
        return {}

    @pynvim.function('Texflow_prune_server_mapping', sync=True)
    def prune_server_mapping(self, args: list[str]|None=None) -> None:
        """ prune dead server mapping data from json file """
        temp_dict = self.mapping_result.copy() # avoid runtime error from editing dict while for loop
        for alias, servername in temp_dict.items():
            try:
                _ = pynvim.attach('socket', path=servername)
            except Exception:
                del self.mapping_result[alias]

        self.save_server_mapping()


    def is_fullservername(self, alias:str) -> bool:
        r"""
        check the servername is full name.
        It the servername is absolute format, return true
        On Windows, \\.\pipe\<alias>.19245.0
        On Unix, /tmp/<username>/<did>/nvim.1929.0
        """
        if sys.platform == 'win32':
            pattern = r'\\\\\.\\pipe\\.*\.\d+\.\d+$'
        else:
            if not Path(alias).exists(): # if the socket file is not existed
                return False
            pattern = r'^/.*nvim\.\d+\.\d+$'
            alias = Path(alias).name

        return re.match(pattern, alias) is not None


    def get_server(self, alias:str=''):
        r"""
        find server using alias/absolute format and get the server handle
        if you access to server with <alias>, it a corresponding full server name like '\\.\pipe\<alias>.19234.0'
        """

        if not alias:
            alias = 'recent'

        if self.is_fullservername(alias):
            servername = alias # if full server name is entered, use literally
        else:
            servername = self.mapping_result.get(alias) # if it is alias, check mapping server
            if not servername:
                servername = self.mapping_result['recent'] # if there are no mapping

        try:
            nvim = pynvim.attach('socket', path=servername) # check this server is alive
            return nvim
        except Exception as e:
            if alias != 'recent':
                if alias in self.mapping_result:
                    del self.mapping_result[alias] # if the server is dead, remove mapping
                    self.save_server_mapping()

                try:
                    servername = self.mapping_result['recent']
                    nvim = pynvim.attach('socket', path=servername)
                    return nvim
                except Exception as f:
                    err_notify('There are no opened neovim instance to connect', str(f))
                    sys.exit(201)
            else:
                err_notify('There are no opened neovim instance to connect', str(e))
                sys.exit(202)



def main():
    mg = ServerManager()
    print(mg.servername)

if __name__ == '__main__':
    main()



