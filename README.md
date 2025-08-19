# texflow.nvim
Make Build and search workflow using `texlab` lsp

## Why?

I've been using [vimtex](https://github.com/lervag/vimtex) and it is cool plugin for managing latex.
But it has some inconvenient thing to use as I think because I am not good at programming.

I try to use [texlab](https://github.com/latex-lsp/texlab) as latex lsp.
I found that `texlab` has features like compile and forward/inverse searching also,
But it doesn't work as I expect.

I want to find some alternatives which meets my purpose but I can't find it until now.
This is why I am editing it.

1) Easy configuration and generalization to understand what it does

    I am failed to set inverse search at any plugins.
	`vimtex` use vim script but I want to configure using lua because it is easy to use and understand.
	If I were an expert, this part would have been different.

2) Use lsp / treesitter

	`vimtex` has inherit highlight so I cannot use latex lsp.
    The advantage of lsp is that diagnostics can be shown in statuscolumn and it is more faster to check latex grammar.

	I want to use colorized parentheses plugins but it doesn't work in `vimtex` perfectly.
	`vimtex` supports partially in some region of document.


3) Learn about latex workflow and how to set environment to use latex compile / search etc..

4) Show installed latex packages list

5) Easy Diagnostics display After latex compile error

> [!NOTE] Note:
> Development will be continue until I satisfied even though the period is loose.

## Requirements

- [Neovim v0.11.0+](https://github.com/neovim/neovim/releases)
- [fidget.nvim](https://github.com/j-hui/fidget.nvim) : (optional) To notify process messages.
- [texlab](https://github.com/latex-lsp/texlab) : (optional) To highlight grammar and use diagnostics.
- `latex engine` : (required) To compile latex, I prefer `latexmk` from [MikTex](https://miktex.org/).
- `viewer engine` : (required) To forward/inverse search, I prefer [sioyek](https://github.com/ahrm/sioyek).
- `python3` : (required) To forward/inverse search
	- `pynvim` : (required) To forward/inverse search


## Installation

Set `XDG_DATA_HOME` environment variable.
Server file will be created using this variable.


Install `pynvim` using package manager.
If you want to use `python` in virtual environment, install `pynvim` in virtual environment.
And use `python` in virtual environment

```powershell
	pip install pynvim
```



Set `vim.g.python3_host_prog` to set python provider.
```lua
	vim.g.python3_host_prog = '<python path>/python'
```



If you are using `lazy.nvim`.
You can use lazy load If you want.

```lua
{
	'Jaehaks/texflow.nvim',
	build = ':UpdateRemotePlugins',
	dependencies = {
		'j-hui/fidget.nvim',
	},
	ft = {'tex', 'latex', 'plaintex'},
}
```

After Installation, check `vim.fn.stdpath('data')/rplugin.vim` is created.
The contents will be like this

```vim
" python3 plugins
call remote#host#RegisterPlugin('python3', '<xdg_data_home>/nvim-data/lazy/texflow.nvim/rplugin/python3/InverseSearch.py', [
      \ {'sync': v:true, 'name': 'Texflow_load_server_mapping', 'type': 'function', 'opts': {}},
      \ {'sync': v:true, 'name': 'Texflow_prune_server_mapping', 'type': 'function', 'opts': {}},
      \ {'sync': v:true, 'name': 'Texflow_save_server_mapping', 'type': 'function', 'opts': {}},
     \ ])
```






