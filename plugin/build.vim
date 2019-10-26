if exists('g:loaded_build')
  finish
endif
let g:loaded_build = 1

command! -nargs=* Build call build#target(<f-args>)
command! -nargs=* BuildInit call build#init(<f-args>)
command! BuildInfo call build#info()
