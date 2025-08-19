import pynvim

from . import paths
from .errors import err_notify


class Commands:
    nvim: pynvim.Nvim # declare pynvim.Nvim as type of nvim

    def __init__(self, nvim: pynvim.Nvim):
        self.nvim = nvim

    def jump_to_line(self, texname: str, line: int):
        try:
            buffers = self.nvim.buffers
            texname = paths.path_normalize(texname)

            # get target buffer object
            target_buf = None
            for buf in buffers:
                try:
                    if buf.name == texname:
                        target_buf = buf
                        break
                except Exception:
                    continue # skip invalid buffer name

            # open buffer
            if target_buf is None:
                self.nvim.command(f"edit {texname}")
                target_buf = self.nvim.current.buffer
            else:
                self.nvim.current.buffer = target_buf
                target_buf.options['buflisted'] = True

            # move cursor
            self.nvim.current.window.cursor = (line, 0) # move to line number
            self.nvim.command('normal! zz') # move screen to center cursor
            self.nvim.command('redraw') # focus

        except Exception as e:
            err_notify('Failed to jumping to line')
            self.nvim.err_write(f"Error jumping to line {e}\n")
