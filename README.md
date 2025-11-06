# texflow.nvim
Make Build and search workflow with `texlab` lsp

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

> [!NOTE]
> Development will be continue until I satisfied even though the period is loose.








# Requirements

- [Neovim v0.11.0+](https://github.com/neovim/neovim/releases)
- [fidget.nvim](https://github.com/j-hui/fidget.nvim) : (optional) To notify process messages.
- [texlab](https://github.com/latex-lsp/texlab) : (optional) To highlight grammar and use diagnostics which `texflow.nvim` cannot detect.
- `latex engine` : (required) To compile latex, I prefer `latexmk` from [MikTex](https://miktex.org/).
- `viewer engine` : (required) To forward/inverse search, I prefer [sioyek](https://github.com/ahrm/sioyek).
- `python3` : (required) To forward/inverse search
	- `pynvim` : (required) To forward/inverse search

It may not work well in UNIX environments because it needs to deal error management.







# Installation

First, Set `XDG_DATA_HOME` environment variable. \
Server file which saves servername of opened neovim instance will be created using this variable. \
If `XDG_DATA_HOME` doesn't be set, `%HOME%/.local/share/nvim-data/texflow/texflow_server.json` will be created. \
If `XDG_DATA_HOME` is set, `%XDG_DATA_HOME%/nvim-data/texflow/texflow_server.json` will be created in Windows. \
In Linux, `$XDG_DATA_HOME/nvim/texflow/texflow_server.json` will be created.


Second, Install `pynvim` using package manager.
If you want to use `python` in virtual environment, install `pynvim` in virtual environment.
And use `python` in virtual environment

```powershell
pip install pynvim
```

Third, Set `vim.g.python3_host_prog` in neovim configuration file to set python provider.
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
	  -- If you use 'outdir' or 'auxdir' in args, don't use @token. use only plain string.
	  -- don't add '-pvc' in latexmk or '-X watch' in tectonic engine
      '-pdf',
      '-interaction=nonstopmode',
      '-synctex=1',
      '-silent',
      '@maintex',
    },
	-- It you use 'latexmk', `latexmk -c` is called when cleanup_auxfiles() executes.
	-- It will remove aux files except of result files like `.bbl, .synctex.gz, .pdf`.
	-- If you want to remove additional files in result directory, set them in clear_ext.
	-- If you use other latex engine which doesn't support command to clear auxiliary files,
	-- you need to write all aux file extension patterns to remove.
	clear_ext = {
		'%.bbl$',
		'%.synctex%.gz$',
		'%.aux$', -- for aux file of sub tex files
	},
	-- boolean : open viewer automatically after compile
	-- If true, viewer will opens after every compile, if you set forward search in viewer.args, It does forward-search.
	-- you can use forward search manually with setting this value false.
	openAfter = false,
	-- string : which method uses to automatically compile every file save in project
	-- nil : don't compile automatically after file save
	-- 'inherit' : If latex engine supports consecutive compile mode, use the mode.
	-- 			   'latexmk' and 'tectonic' are recognized until now.
	-- 'plugin' : If latex engine doesn't supports consecutive compile mode, use it.
	-- 			  It simulates 'inherit' mode in texflow.nvim itself.
	onSave = nil,
  },
  viewer = {
    shell = vim.api.nvim_get_option_value('shell', {scope = 'global'}),
    shellcmdflag = vim.api.nvim_get_option_value('shellcmdflag', {scope = 'global'}),
    engine = 'sioyek',
    args = {
      '--reuse-window',
      '--nofocus',
      '--inverse-search "' .. vim.g.python3_host_prog .. ' @InverseSearch %1 %2"',
      '--forward-search-file @curtex',
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
local root_dir_texlab = function (bufnr, cb)
  local root = vim.fs.root(bufnr, {
    '.latexmkrc',
    'latexmkrc',
    '.texlabroot',
    'texlabroot',
  }) or vim.fn.expand('%:p:h')
  cb(root)
end

-- texlab supports two diagnostics source (texlab / latex)
-- `texlab` source shows results independent of the compile engine.
-- `latex` source read log file and show the result of parsing which is duplicated with diagnostic result of texflow.nvim
-- To prevent annoying diagnostics, filter diagnostic of `latex` source.
local function filter_diagnostics(diagnostics, unwanted_source)
  local filtered = {}
  for _, diag in ipairs(diagnostics) do
    if diag.source ~= unwanted_source then
      table.insert(filtered, diag)
    end
  end
  return filtered
end
local function publishDiagnostics_texlab(err, result, ctx)
  local unwanted_source = 'latex'
  result.diagnostics = filter_diagnostics(result.diagnostics, unwanted_source)
  return vim.lsp.handlers['textDocument/publishDiagnostics'](err, result, ctx)
end

vim.lsp.config('texlab', {
  cmd = {'texlab'},
  root_dir = root_dir_texlab,
  filetypes = {'tex', 'plaintex', 'bib'},
  settings = { -- see https://github.com/latex-lsp/texlab/wiki/Configuration
    texlab = {
      build = {
        onSave = false,                 -- build on save (it makes texlab do continuous compile mode
										-- but it cannot be turned off by user. use 'texflow.nvim' instead of it.
        forwardSearchAfter = false,     -- perform forward search after build
      },
      -- forward / inverse search will be done by texflow.nvim
      handlers = {
        -- disable 'latex' source diagnostics
        ['textDocument/publishDiagnostics'] = publishDiagnostics_texlab,
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
| `@texname`       | file name without extension of current tex file                    |
| `@curtex`        | file name with extension of current tex file (error it not)        |
| `@maintex`       | file name with extension of main tex file in project               |
| `@line`          | line number under cursor                                           |
| `@pdf`           | file path of pdf file which is corresponding with current tex file |
| `@InverseSearch` | file path of python file to inverse-search                         |
| `@servername`    | servername of current neovim instance                              |



<details>
	<summary> My User configuration </summary>

<br>

I am using this keymaps using `lazy.nvim`

```lua
config = function (_, opts)
  local texflow = require('texflow')
  texflow.setup(opts)

  local TexFlowMaps = vim.api.nvim_create_augroup('TexFlowMaps', {clear = true})
  vim.api.nvim_create_autocmd('FileType', {
    group = TexFlowMaps,
    pattern = {'tex', 'latex', 'plaintex'},
    callback = function ()
      vim.keymap.set('n', '<leader>ll', function () texflow.compile({ latex = { onSave = true, } })
      end, { buffer = true, desc = '[TexFlow] compile tex file and open pdf', silent = true })

      vim.keymap.set('n', '<leader>lf', function () texflow.compile({ latex = { openAfter = false, onSave = false, } })
      end, { buffer = true, desc = '[TexFlow] compile tex file and open pdf', silent = true })

      vim.keymap.set('n', '<leader>lv', function () texflow.view() end
      , { buffer = true, desc = '[TexFlow] view pdf file', silent = true })

      vim.keymap.set('n', '<leader>lc', function () texflow.cleanup_auxfiles() end
      , { buffer = true, desc = '[TexFlow] clean up auxiliary files', silent = true })
    end
  })
end
```

</details>










# Features / API

## `Compile(opts)`

https://github.com/user-attachments/assets/dfbac567-4a42-478c-81f5-96b0c5767534

You can overwrite configuration to each command. If `opts` is `nil`, it is applied by your configuration by `setup()`.


```lua
-- Compile tex file in current buffer once only
require('texflow').compile()

-- Compile current buffer once, and open viewer automatically if compile is completed
require('texflow').compile({
  latex = {
    openAfter = true,
  }
})

-- If onSave is set as 'inherit' or 'plugin', compile() does toggle behavior.
-- It turns on continuous mode after first execution,
-- 'latex.engine' will compile automaticlally when it set 'inherit', 'texflow.nvim' will compile automatically when it set 'plugin'.
-- When you call this function again, It turns off continuous mode without compilation.
require('texflow').compile({
  latex = {
    openAfter = true,
    onSave = 'inherit',
  }
})
```

> [!NOTE]
> If you use `MikTeX`, packages which is called in `\usepackages` are installed automatically when compile starts if the packages are not installed.

> [!BUG]
> When you set `-outdir` to push output or auxiliary files one side and use bib file,
> You need to write `\bibliography{../test.bib}` to recognize the bib file.
> Plus, you need to move `test.bib` file to parent directory of main tex file which declare this command.
> It is bug of `latexmk` so It doesn't recommend to use `-outdir`.
> The solution must be required.

### `Compile:options`

#### **❓ How is the working directory determined during compilation?**

The working directory for the `latex engine`'s execution is influenced by the `@curtex` and `@maintex` tokens
passed as an argument to `latex.args`.

If you want to compile current tex file which is focused, use `@curtex`.
It would be useful when you want to <u>compile sub-tex file independently</u>.
Plugin checks current buffer is *.tex file and output will be created in directory where `@curtex` is.

If you want to compile main tex file in project, use `@maintex`.
<u>You can call `compile()` or `view()` function regardless of which file is focused</u>.
So you can run `compile()` for main file directly right after modifying non-tex file like `.bib`.
`texflow.nvim` checks which is main file from project root automatically.

#### **❓ How to recognize main file?**
Plugin detects main file through several ways, the sequence are done in the following order: \
It would be useful If you have multiple sub-tex file in latex project

1) Check `@default_files=(<main filename>)` value is set in `.latexmkrc`
2) Check `!TEX root = <main filename>` is declared at top of current tex file.
3) Check `\documentclass{}` is declared in current tex file.
4) Check `\documentclass{}` is declared in other tex file from the project root

The project root can be determined by this sequence.
1) Check `rootdir` of `texlab lsp`.
2) Check current or parent directory has one of `{.latexmkrc, latexmkrc, Tectonic.toml}` recursively.
3) If not, set directory where current buffer file is.


### `Compile:Diagnostics`

https://github.com/user-attachments/assets/10162630-4d23-4496-8b10-af53cea4a7e5

`Texflow.nvim` supports showing diagnostics in statuscolumn like lsp. \
These diagnostics are from `*.log` file after `*.tex` file is compiled. `Texflow.nvim` parses the error messages
and show at proper line number which is related with error or warning. \
It detects error format starts with both `!` and `<filename>:<line>`,
You don't need to include `--file-line-error` argument necessarily in your latex engine configuration.

<u>There are some limitations to show diagnostics.</u>
1) All error/warning in log file doesn't mentioned column number. All diagnostics from `Texflow` will show at column 2.
2) Not all warning in log file have line number. These warning will be shown at first line of each `*.tex` file.

> [!CAUTION]
> To achieve proper log parser operation,
> you need to extend `max_print_line` setting of `MikTeX` or `TexLive` distribution so that log files should not be wrapped.
> If not, some files which has long directory cannot show diagnostics properly.
>
> If you are using `MikTeX`, you don't need to consider it. \
> `texflow.nvim` will check `max_print_line` is enough high value and set for basic latex engines
> such as `pdflatex.ini`, `xelatex.ini`, `lualatex.ini`, `latex.ini`
> `--max-print-line` option of latex engine works also, but It doesn't work in `lualatex`.
> So setting `max_print_line` is more reliable solution.
>
> If you are using `TexLive`, you can use `texmf.cnf`. \
> You need to set `max_print_line` to high value (>5000) in `texmf.cnf` manually.

> [!MISSING]
> `texflow.nvim` cannot support parsing `tectonic`'s log file yet. It supports `latexmk` only.

#### 💡 Diagnostics on project

Diagnostics of sub files are supported. \
When you have multiple sub-files used in main file and there are some errors or warning for each files,
Diagnostics of each files will be displayed according to each files which is loaded in neovim.
Diagnostics are automatically displayed when you open the file, even if it was not loaded at compile time.


## `cleanup_auxfiles(opts, cb)`

https://github.com/user-attachments/assets/67f7f947-c6cc-4ee6-bf1b-40276384b932

```lua
-- clean up auxiliary files resulting from compilation
---@param opts texflow.config
---@param cb fun(opts: texflow.config)?
require('texflow').cleanup_auxfiles(opts, cb)
```

### philosophy
Sometimes, errors occur after compile even though tex file grammar is perfect If the previous compile result has several error. \
To achieve more exact compile process, cleaning up auxiliary files which are created previous compile process could be needed.

This process is implemented automatically when some conditions are met like below quotes at 9e19622.
> `Texflow.nvim` clean up the aux files in result directory before compile automatically
> if a log file resulting from compile and the previous result of compile has error.

But It could be annoying because someone doesn't want this process because it make compile time longer. \
So `cleanup_auxfiles()` function is separated independently from `compile()`, The deletion operation was performed asynchronously. \
You can add any function like `compile()` in `cb` argument.

### Usage
This function runs first `latexmk -c` if the latex engine is set to `latexmk`.
After that, It manually deletes files matching the patterns specified in `clear_ext`.
So If you don't use `latexmk`, add all extensions of aux files what you want to remove in `clear_ext`.

Because `latexmk -c` will leave output file like `.bbl`, `.pdf`, `.synctex.gz`.
When you work with multiple sub tex files in sub-directory, `latexmk -c` cannot remove `.aux` files of sub tex file automatically.
You can add file extension list using lua pattern to `clear_ext` field on config manually to remove these files.
Default value of `clear_ext` removes `.bbl`, `.synctex.gz`, `.aux`.
If you use other latex engine which doesn't support cleaning command, add all file extensions what you need.

> [!NOTE]
> Files matched with `clear_ext` pattern will be removed recursively from directory where compile executes.
> So you must compile at once before clean up them.



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

For example, for `sioyek`, you can add [[#sioyekhttpsgithubcomahrmsioyektreedevelopment|Viewer Examples > sioyek]] this configuration in `setup()` (It is default)




### case2) CLI option such as `--inverse-search` is `not` supported in viewer.

Set the command in inverse-search setting of viewer.

For example, for `sioyek`, you can edit `prefs_user.config` like this.
```powershell
inverse_search_command python <installpath>\texflow.nvim\rplugin\python3\InverseSearch.py "%1" %2
```













# Viewer Examples

## [sioyek](https://github.com/ahrm/sioyek/tree/development)

It is recommended that you use the development branch. \
<u>`--inverse-search` option accepts only one parameter. So you must enclose the command with quotes("").</u> \
`--nofocus` option doesn't work yet.

```lua
engine = 'sioyek',
args = {
  '--reuse-window',
  '--nofocus',
  '--inverse-search "' .. vim.g.python3_host_prog .. ' @InverseSearch %1 %2"',
  '--forward-search-file @curtex',
  '--forward-search-line @line',
  '@pdf',
},
```





# Acknowledgements

This plugin is inspired by [vimtex](https://github.com/lervag/vimtex)
