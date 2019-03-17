if exists('g:loaded_build')
  finish
endif
let g:loaded_build = 1

if !exists('g:build#make_cmd')
  let g:build#make_cmd = 'call build#run_makeprg()'
endif

command! -nargs=* Build call build#target(<f-args>)
command! -nargs=* BuildInit call build#init(<f-args>)

augroup build
  autocmd!
  autocmd BufNewFile,BufRead * call build#setup()
augroup END
