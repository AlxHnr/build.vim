if exists('g:loaded_build')
  finish
endif
let g:loaded_build = 1

command! -nargs=? -complete=file Build call build#target(<f-args>)
