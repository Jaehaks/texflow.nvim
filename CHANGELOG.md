# ChnageLog

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
