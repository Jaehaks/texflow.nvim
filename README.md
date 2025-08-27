# texflow.nvim
Make Build and search workflow using `texlab` lsp

# Why?

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








# Requirements

- [Neovim v0.11.0+](https://github.com/neovim/neovim/releases)
- [fidget.nvim](https://github.com/j-hui/fidget.nvim) : (optional) To notify process messages.
- [texlab](https://github.com/latex-lsp/texlab) : (optional) To highlight grammar and use diagnostics.
- `latex engine` : (required) To compile latex, I prefer `latexmk` from [MikTex](https://miktex.org/).
- `viewer engine` : (required) To forward/inverse search, I prefer [sioyek](https://github.com/ahrm/sioyek).
- `python3` : (required) To forward/inverse search
	- `pynvim` : (required) To forward/inverse search

It may not work well in UNIX environments because it needs to deal error management.







# Installation

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

After Installation, check `vim.fn.stdpath('data')/rplugin.vim` is created properly.
The contents will be like this

```vim
" python3 plugins
call remote#host#RegisterPlugin('python3', '<xdg_data_home>/nvim-data/lazy/texflow.nvim/rplugin/python3/InverseSearch.py', [
      \ {'sync': v:true, 'name': 'Texflow_load_server_mapping', 'type': 'function', 'opts': {}},
      \ {'sync': v:true, 'name': 'Texflow_prune_server_mapping', 'type': 'function', 'opts': {}},
      \ {'sync': v:true, 'name': 'Texflow_save_server_mapping', 'type': 'function', 'opts': {}},
     \ ])
```







# Configuration
<details>
	<summary> Default configuration </summary>

<br>

Default configuration is below.
You don't needs to add this if you use `latexmk` and `sioyek` as engine.


```lua
require('texflow').setup({
  latex = {
    shell = vim.api.nvim_get_option_value('shell', {scope = 'global'}),
    shellcmdflag = vim.api.nvim_get_option_value('shellcmdflag', {scope = 'global'}),
    engine = 'latexmk',
    args = {
      '-pdf',
      '-interaction=nonstopmode',
      '-synctex=1',
      '-verbose',
      '-file-line-error',
      '@tex',
    },
	openAfter = false,	-- open viewer after compile automatically
						-- If you set forward-search in viewer configuration, forward search is executed
	onSave = false,		-- compile *.tex automatically after buffer is saved
  },
  viewer = {
    shell = vim.api.nvim_get_option_value('shell', {scope = 'global'}),
    shellcmdflag = vim.api.nvim_get_option_value('shellcmdflag', {scope = 'global'}),
    engine = 'sioyek',
    args = {
      '--reuse-window',
      '--nofocus',
      '--inverse-search "' .. vim.g.python3_host_prog .. ' @InverseSearch %1 %2"',
      '--forward-search-file @tex',
      '--forward-search-line @line',
      '@pdf',
    },
  }
})
```

</details>










# Usages

You can change you `texlab` configuration what you want. \
Default latex engine is `tectonic` but We modified it to match engine which We use to compile.

<details>
	<summary> My Texlab Configuration </summary>

<br>

```lua
vim.lsp.config('texlab', {
  cmd = {'texlab'},
  filetypes = {'tex', 'plaintex', 'bib'},
  settings = { -- see https://github.com/latex-lsp/texlab/wiki/Configuration
    texlab = {
      build = {
        executable = 'latexmk',
        args = {
          '-interaction=nonstopmode',   -- continuous mode compilation
          '%f',                         -- current file
        },
        onSave = false,                 -- build on save (it works when :w but not autocmd save)
        forwardSearchAfter = false,     -- perform forward search after build
      },
      latexFormatter = 'latexindent',
      latexindent = {
        modifyLineBreaks = false,
      }
    },
  },
})
```

</details>


## _How to use construct command arguments?_

If you want to change your latex or viewer command, you can use @token as alias of filename. \
These @token is supported. They will be replaced with real value before job starts.

| @token         | Description                                                        |
| -------------- | ------------------------------------------------------------------ |
| @texname       | file name without extension of current tex file                    |
| @tex           | file name with extension of current tex file                       |
| @line          | line number under cursor                                           |
| @pdf           | file path of pdf file which is corresponding with current tex file |
| @InverseSearch | file path of python file to inverse-search                         |
| @servername    | servername of current neovim instance                              |

<details>
	<summary> My User configuration </summary>

<br>

I am using this configuration using `lazy.nvim`

```lua
opts = {
  latex = {
    engine = 'latexmk',
    args = {
      '-pdf',
      '-outdir=@texname',
      '-interaction=nonstopmode',
      '-synctex=1',
	  '-file-line-error',
      '@tex',
    },
	openAfter = true,
  },
},
config = function (_, opts)
  local texflow = require('texflow')
  texflow.setup(opts)

  local TexFlowMaps = vim.api.nvim_create_augroup('TexFlowMaps', {clear = true})
  vim.api.nvim_create_autocmd('FileType', {
    group = TexFlowMaps,
    pattern = {'tex', 'latex', 'plaintex'},
    callback = function ()
		-- keymap what you want
    end
  })
end
```

</details>










# Features / API

## `Compile`

![texflow_compile_onSave](https://github.com/user-attachments/assets/48afb998-f5c2-440b-ba13-625c7db418db)


```lua
-- You can insert your custom config table as a first argument or leave with '_' if you use your setup.
-- Compile current buffer once, and open viewer automatically if compile is completed
require('texflow').compile({
  latex = {
    openAfter = true,
  })

-- If onSave is true, compile() does toggle behavior.
-- It turns on continuous mode after first compilation, then texflow compiles whenever you save file.
-- If you call this function again, It turns off continuous mode without compilation
require('texflow').compile({
  latex = {
    openAfter = true,
    onSave = true,
  })
-- Compile current buffer once only
require('texflow').compile()
```



### `Compile:Diagnostics`

![texflow_diagnostic](https://github.com/user-attachments/assets/6146979a-b41b-49ee-ac08-20917dbb56d6)


`Texflow.nvim` supports showing diagnostics in statuscolumn like lsp. \
These diagnostics are from `*.log` file after `*.tex` file is compiled. `Texflow.nvim` parses the error messages
and show at proper line number which is related with error or warning. \
You must includes `--file-line-error` argument in your latex engine configuration to parse error.

<u>There are some limitations to show diagnostics.</u>
1) All error/warning in log file doesn't mentioned column number. All diagnostics from `Texflow` will show at column 0.
2) Not all warning in log file have line number. These warning will be shown at first line of each `*.tex` file.




## `Forward-Search`

![texflow_forward-search](https://github.com/user-attachments/assets/cc807734-16ac-41c5-a8ac-f0b3f2f43c74)


```lua
-- open viewer if there are pdf file which is compiled.
-- If there are arguments related with forward search in configuration, it will does forward-search
require('texflow').view()
```


## `Inverse-Search`

![texflow_inverse-search](https://github.com/user-attachments/assets/a048ae77-c5cc-4c41-8590-3274a77979e7)


### 1) How to Work?

If you compile `*.tex` file with `-synctex=1` option, it will generate `*.synctex.gz` in workspace.
This file is needed to implement inverse-search. \
When I click some line in viewer, the information about which line in which tex file.
The token such as `%l` and `%f` refers to line number and tex file name is different for each viewer. \
The command mapped to inverse-search is executed when you click somewhere in pdf viewer If you set. \
\
Python file in `texflow.nvim` will implement inverse-search without starting neovim instance like `nvim --headless`,
just detect which neovim instance is opened and open the tex file and move cursor to the line.

### 2) `@InverseSearch` python file

This token means `<installpath>\texflow.nvim\rplugin\python3\InverseSearch.py`. \
You can execute this file using python and the format is `python @InverseSearch %1 %2 [%3]`. \
File path of tex file which is associated with the current pdf file is located in `%1`. \
Line number of tex file which is associated with the current pdf file is located in `%2`. \
Servername of neovim instance which opens the tex file is located in `%3`. \
\
`%3` is optional and it can be an alias or the actual servername such as `\\.\pipe\nvim.<pid>.0` in Windows,
`/tmp/<username>/<uid>/nvim.<pid>.0` in Unix which is the same value of `vim.v.servername`. \
Possible alias is `'recent'` which means the last opened neovim instance where `texflow.nvim` is loaded. \
<u>`texflow.nvim` detects proper neovim instance if you remain `%3` as empty value.</u> \
\
There are two cases to implement inverse-search.

### case1) CLI option such as `--inverse-search` is supported in viewer.

You can override inverse-search setting by cli command option.
Pass `python @InverseSearch %1 %2` as an argument of the option like default configuration.
You can use python execution file in virtual environment instead of globally `python` execution file.

For example, for `sioyek`, you can add this configuration in `setup()` (It is default)

```lua
{
  engine = 'sioyek',
  args = {
    '--reuse-window',
    '--nofocus',
    '--inverse-search "python @InverseSearch %1 %2"',
    '--forward-search-file @tex',
    '--forward-search-line @line',
    '@pdf',
  },
}
```


### case2) CLI option such as `--inverse-search` is `not` supported in viewer.

Set the command in inverse-search setting of viewer.

For example, for `sioyek`, you can edit `prefs_user.config` like this.
```powershell
inverse_search_command python <installpath>\texflow.nvim\rplugin\python3\InverseSearch.py "%1" %2
```













# Viewer Examples

## [1) sioyek](https://github.com/ahrm/sioyek/tree/development)

It is recommended that you use the development branch. \
<u>`--inverse-search` option accepts only one parameter. So you must enclose the command with quotes("").</u> \
`--nofocus` option doesn't work yet.

```lua
engine = 'sioyek',
args = {
  '--reuse-window',
  '--nofocus',
  '--inverse-search "' .. vim.g.python3_host_prog .. ' @InverseSearch %1 %2"',
  '--forward-search-file @tex',
  '--forward-search-line @line',
  '@pdf',
},
```





# Acknowledgements

This plugin is inspired by [vimtex](https://github.com/lervag/vimtex)
