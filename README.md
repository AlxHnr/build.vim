# Build.vim

This plugin builds and runs single source files or even entire projects
with the correct build tools. It searches for known build files from the
current buffers path upwards.

## Configuration

This plugin does not map any keys by default. Here are some example
mappings, which build a specific target after saving all files:

```vim
nnoremap <silent> <F2> :wall<CR>:call build#target('clean')<CR>
nnoremap <silent> <F3> :wall<CR>:call build#target('build')<CR>
nnoremap <silent> <F4> :wall<CR>:call build#target('run')<CR>
nnoremap <silent> <F9> :wall<CR>:call build#target('test')<CR>
```

### g:build#autochdir

If this variable is set and equals to 1, the working directory path of the
current buffer will be changed to the path of the build file.

## Provided functions

Build.vim provides the following functions:

### build#setup()

This function will search for build files from the current files directory
and setup some variables. Usually you don't need to call this manually. It
will change the current buffers working directory path, if
[g:build#autochdir](#g-build-autochdir) is set.

### build#target()

Builds the given target. Takes exactly one string.

## License

Released under the zlib license.
