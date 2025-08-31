# ChnageLog

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
