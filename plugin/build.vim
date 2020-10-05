if exists('g:loaded_build')
  finish
endif
let g:loaded_build = 1

command! -nargs=? -complete=file Build call build#target(<f-args>)
command! -nargs=? -complete=file BuildInit call build#init(<f-args>)
command! BuildInfo call build#info()
command! BuildRefresh call build#get_current_build_system(v:true)
