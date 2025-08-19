# ChnageLog

## 2025-08-19

### Features
- Implement `Inverse Search` using `pynvim` [5afce70](https://github.com/Jaehaks/texflow.nvim/commit/5afce70821e145114dfef71cbc08ad6cbecd8fe6)
	- ✔️ Inverse Searching using cli option of viewer is confirmed.
	- ❓Inverse Searching using setting of viewer is considered to implement. But it needs to check.
- replace `sep_change()` with `sep_unify()` [a88c9dd](https://github.com/Jaehaks/texflow.nvim/commit/a88c9dd9905c7a6c956fdbff976864eb0f0bd773)

### Bug fixed
- Prevent error if viewer is closed first before tex file is closed [ff5917f](https://github.com/Jaehaks/texflow.nvim/commit/ff5917f3decb0194b15c8f60ef4d4040291e3f0c)
- Add distinguishable command separator for `replace_cmd_token()` [cd31930](https://github.com/Jaehaks/texflow.nvim/commit/cd3193063c0c1cd0af8cb8dbb19f08ba847aa849)

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
