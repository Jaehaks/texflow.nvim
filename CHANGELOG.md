# ChnageLog

## 2025-10-24

### Bug fixed
- Check `nil` msg to add diagnostics to ignore them. [c255272](https://github.com/Jaehaks/texflow.nvim/commit/c2552728add8cca4ae342fcfd125f276b602daeb)
- ~~Add current file path to detect in `get_filepath()`~~. [8bf2c86](https://github.com/Jaehaks/texflow.nvim/commit/8bf2c865b50674073fd6f68ee2c2be175485eeba)
	- But it is weird because `/**/` must include current directory.
	- This function will not removed.
- Check `pdf` file is existed first before `view()` starts. [734e704](https://github.com/Jaehaks/texflow.nvim/commit/734e7040ea61af46395e2e9ab98232b518efddb6)
	- It will prevent to open empty file.
- Unify drive character also for Windows in `sep_unify()`. [77e0ef3](https://github.com/Jaehaks/texflow.nvim/commit/77e0ef34da991b6238d74eb34ba13db17b4b8c77)
- Use `texflow.io` to initiate serverdata at plugin startup instead of python script. [c5c7826](https://github.com/Jaehaks/texflow.nvim/commit/c5c78265737009b5a7809c8d21cd7406b162afb4)
	- It Will cause fast plugin loading times.

### ReFactoring
- Push commands to one side in commands.lua for lazy loading functions. [24236f6](https://github.com/Jaehaks/texflow.nvim/commit/24236f65f7d4107427f37484d56a3f77a82b07ca)
- Separate progress/notifying function to `notify.lua`. [3cd4e6c](https://github.com/Jaehaks/texflow.nvim/commit/3cd4e6ceeaee9c23067bd7e12198fe5438208e75)

### Features
- Show progress message dynamically when compiling. [786ab31](https://github.com/Jaehaks/texflow.nvim/commit/786ab319d9f5ad94ab023a886834821a35c69cfb)
	- Required `fidget.nvim`. If not, notification use `vim.notify()`
- Clean up auxiliary files process is added before `compile_core()` using `compile_safe()`. [88380fb](https://github.com/Jaehaks/texflow.nvim/commit/88380fb0712c457e8a3aeba86e418631032bce5e)
- Add `pdfTeX warning` message pattern for warning diagnostics. [0b735e6](https://github.com/Jaehaks/texflow.nvim/commit/0b735e6d428af17c08b30e01fae7857a0d0541a1)
	- Add `Package <package name> Warning ~` pattern at [9e19622]()
	- Add `warning ~ ` pattern [9e19622]()
- 🔨 **_Breaking changes_** : Now `texview.nvim` supports for multiple file project directory. [9e19622](https://github.com/Jaehaks/texflow.nvim/commit/9e19622c1fa3f5c321c9bf9ea658886fd8b975ac)
	1) Check diagnostics for multiple files and show them whenever the file which has error is loaded.
	2) Support `@maintex` and `@curtex` tokens.
		- The existing `@tex` is changed to `@curtex` to distinguish.
		- `@maintex` will detect main file in project by some sequence.
		  but there are limitations that only one file allows to `@default_files` in case of setting by `.latexmkrc`.
	3) Getting `filedata` will be fast. Remove dependency from argument.
	4) Reconstruct `parser.py`, It dedicates to process whole file without slicing for multiprocessing.
	5) Add `check_max_print_line()` to adjust maximum column of log file
		- It aids to proper parsing file path in log file.
		- It only supports for MikTeX. TeXLive users must adjust them in `texmf.cnf` manually.

## 2025-09-01

### Bug fixed
- Add error pattern starts with `!` [d8f399e](https://github.com/Jaehaks/texflow.nvim/commit/d8f399e07013b69f75451b0f964557dfb27adaed)
	- now `-file-line-error` of `latexmk` doesn't be necessary option.
	- Some errors are not converted to format of `<filename>:<line>:<msg>` with `-file-line-error`
- Fix bug that invoke error when *.tex buffer is deleted after viewer is closed first. [478f092](https://github.com/Jaehaks/texflow.nvim/commit/478f092fa81c698b95820e589d9be5ea175c5cd9)

## 2025-08-30

### Bug fixed
- Fix for bug that diagnostics don't be reset after compile success [0fa31f2](https://github.com/Jaehaks/texflow.nvim/commit/0fa31f29919943e960c86985367cc92303e53a9e)

## 2025-08-27

### Features
- Add `Diagnostics` feature after compile to show diagnostic result in statuscolumn [a775c44](https://github.com/Jaehaks/texflow.nvim/commit/a775c4431c6baa3adecf2bbdf153e74b8b4f6446)
	- Source name of diagnostics is `texflow`

## 2025-08-24

### Features
- Add `onSave` config to implement continuous compile [74ddd42](https://github.com/Jaehaks/texflow.nvim/commit/74ddd4246c1774d18ded08d71fcbd98c0ff22040)

### Bug fixed
- `openAfter` config is belong to `texflow.config.latex` configuration [29fcf7a](https://github.com/Jaehaks/texflow.nvim/commit/29fcf7a9c257464a8022d72b2accdb88448eda9d)

## 2025-08-23

### Bug fixed
- Fix for autocmd to close pdf viewer when tex file is closed [8602a65](https://github.com/Jaehaks/texflow.nvim/commit/8602a65d267cb85a2e14a6971980f349f7166ce3)
	- Original behavior is from [b9cfcc0](https://github.com/Jaehaks/texflow.nvim/commit/b9cfcc01a219e7c82d6f3e5eafef331e726eb7b2)

## 2025-08-22

### Style
- Reconstruct `build.lua` to separate and make simpler. [ab57e14](https://github.com/Jaehaks/texflow.nvim/commit/ab57e148175b9e879a6abec09d19e4c3d493477d)

### Doc
- Add Usage / Features [ca5aa9b](https://github.com/Jaehaks/texflow.nvim/commit/ca5aa9bf02d075915d50a633a14f5384b5851ff3)

## 2025-08-12

### Features
- Add python library to implement Inverse Search
	- ✔️ Inverse Searching using cli option of viewer is confirmed

### Bug fixed
- Add `pcall()` to `jobstop` to deal with nil job id

## 2025-08-12

### Features
- Add `view()` function to open pdf file corresponding with tex file [b9cfcc0](https://github.com/Jaehaks/texflow.nvim/commit/b9cfcc01a219e7c82d6f3e5eafef331e726eb7b2)
	- ✔️ Forward Searching using cli option of viewer is confirmed.
	- Opened viewer is closed also when the matched tex file is closed.
- Add `OpenAfter` option for `compile()` function to open viewer after compile automatically [410bfb8](https://github.com/Jaehaks/texflow.nvim/commit/410bfb876138c78bacb2d2b23c4c5cf849fcb014)
- `compile()` function does in tex file location regardless with current work directory.


## 2025-08-09

### Features
- Add progress message while compiling latex using fidget.nvim [f004708](https://github.com/Jaehaks/texflow.nvim/commit/f0047087d8fde11554a876edcb8455a5b50935b6)
