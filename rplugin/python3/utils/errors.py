import subprocess
import sys


def err_notify(err_msg:str, e:str = '') -> None:
    """
    invoke new cmd window to notify error
    It is useful when the python code is running out of shell.

    Args:
        err_msg(str) : error message you want to notice at one line manually
        e(str) : error message from 'Exception as e'
    """
    start_cmd = 'start "" cmd /k'
    end_cmd = '&& echo. && pause && exit'
    if sys.platform == 'win32':
        _ = subprocess.run(f'{start_cmd} "echo {err_msg} & echo {e} {end_cmd}"', shell=True)
    else:
        print(err_msg)
