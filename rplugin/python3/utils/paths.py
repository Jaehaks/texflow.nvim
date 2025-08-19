import os


def sep_change(path: str, sep_to:str|None=None):
    """
    Change path separator with '/'
    pynvim.nvim.buffers return with '/'
    """
    sep_to = sep_to or os.sep
    sep_from = '/' if sep_to == '\\' else '\\'
    return path.replace(sep_from,sep_to)


def path_normalize(filepath: str):
    """
    Unify path form

    Args:
        path (str) : absolute path

    Returns:
        str : absolute path with expanded and uppercase drive character
    """

    npath = os.path.expanduser(filepath) # expand environment variable
    npath = sep_change(npath)        # unify separator by OS

    # make drive character uppercase
    drive, rest = os.path.splitdrive(npath)
    if drive:
        drive = drive.upper()
    return os.path.join(drive, rest)


