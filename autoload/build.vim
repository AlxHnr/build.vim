" Copyright (c) 2015 Alexander Heinrich {{{
"
" This software is provided 'as-is', without any express or implied
" warranty. In no event will the authors be held liable for any damages
" arising from the use of this software.
"
" Permission is granted to anyone to use this software for any purpose,
" including commercial applications, and to alter it and redistribute it
" freely, subject to the following restrictions:
"
"    1. The origin of this software must not be misrepresented; you must
"       not claim that you wrote the original software. If you use this
"       software in a product, an acknowledgment in the product
"       documentation would be appreciated but is not required.
"
"    2. Altered source versions must be plainly marked as such, and must
"       not be misrepresented as being the original software.
"
"    3. This notice may not be removed or altered from any source
"       distribution.
" }}}

if executable('nproc')
  let s:jobs = systemlist('nproc')[0]
else
  let s:jobs = 1
endif

" Informations about various builds systems. {{{
let s:build_systems =
  \ {
  \   'Autotools':
  \   {
  \     'file'    : 'configure',
  \     'init'    : './configure',
  \     'command' : 'make --jobs=' . s:jobs,
  \     'target-args':
  \     {
  \       'build' : 'all',
  \     },
  \   },
  \   'Cargo':
  \   {
  \     'file'    : 'Cargo.toml',
  \     'command' : 'cargo',
  \   },
  \   'CMake':
  \   {
  \     'file'    : 'CMakeLists.txt',
  \     'init'    : 'mkdir -p build/ && cd build/ && cmake ../',
  \     'command' : 'cmake --build ./build/ -- -j ' . s:jobs,
  \     'target-args':
  \     {
  \       'build' : 'all',
  \     },
  \   },
  \   'DUB':
  \   {
  \     'file'    : 'dub.json',
  \     'command' : 'dub',
  \   },
  \   'Make':
  \   {
  \     'file'    : 'Makefile,makefile',
  \     'command' : 'make --jobs=' . s:jobs,
  \     'target-args':
  \     {
  \       'build' : 'all',
  \     },
  \   },
  \ }
" }}}

" Build commands for some languages. {{{
let s:language_cmds =
  \ {
  \   'c':
  \   {
  \     'clean' : 'rm "%HEAD%"',
  \     'build' : 'gcc -std=c11 -Wall -Wextra "%NAME%" -o "%HEAD%"',
  \     'run'   : './"%HEAD%"',
  \   },
  \   'cpp':
  \   {
  \     'clean' : 'rm "%HEAD%"',
  \     'build' : 'g++ -std=c++11 -Wall -Wextra "%NAME%" -o "%HEAD%"',
  \     'run'   : './"%HEAD%"',
  \   },
  \   'd':
  \   {
  \     'clean' : 'rm "%HEAD%" "%HEAD%.o"',
  \     'build' : 'dmd "%NAME%"',
  \     'run'   : './"%HEAD%"',
  \   },
  \   'haskell':
  \   {
  \     'clean' : 'rm "%HEAD%"{,.hi,.o}',
  \     'build' : 'ghc "%NAME%"',
  \     'run'   : './"%HEAD%"',
  \   },
  \   'java':
  \   {
  \     'clean'  : 'rm "%HEAD%.class"',
  \     'build'  : 'javac -Xlint "%NAME%"',
  \     'run'    : 'java "%HEAD%"',
  \   },
  \   'nim':
  \   {
  \     'clean' : 'rm -rf nimcache "%HEAD%"',
  \     'build' : 'nim compile "%NAME%"',
  \     'run'   : './"%HEAD%"',
  \   },
  \   'ocaml':
  \   {
  \     'run' : 'ocaml "%NAME%"',
  \   },
  \   'racket':
  \   {
  \     'run'   : 'racket "%NAME%"',
  \     'build' : 'raco make -v "%NAME%"',
  \     'clean' : 'rm compiled/*_rkt.{dep,zo}; rm -rf compiled/drracket; rmdir compiled',
  \   },
  \   'rust':
  \   {
  \     'clean' : 'rm "%HEAD%"',
  \     'build' : 'rustc "%NAME%"',
  \     'run'   : './"%HEAD%"',
  \   },
  \   'scala':
  \   {
  \     'clean'  : 'rm "%HEAD%"*.class',
  \     'build'  : 'scalac "%NAME%"',
  \     'run'    : 'scala "%HEAD%"',
  \   },
  \   'tex':
  \   {
  \     'clean'  : 'rm "%HEAD%".{aux,log,nav,out,pdf,snm,toc}',
  \     'build'  : 'pdflatex -file-line-error -halt-on-error "%NAME%"',
  \     'run'    : 'xdg-open "%HEAD%.pdf"',
  \   },
  \ }

" Add support for some scripting languages.
let s:scripting_languages =
  \ 'sh,csh,tcsh,zsh,sed,awk,lua,python,ruby,perl,perl6,tcl,scheme'

for s:language in split(s:scripting_languages, ',')
  let s:language_cmds[s:language] =
    \ { 'run' : 'chmod +x "%NAME%" && ./"%NAME%"' }
endfor

unlet s:scripting_languages s:language
" }}}

function! s:has_buildsys_item(build_systems, bs_name, key) " {{{
  return has_key(a:build_systems, a:bs_name)
    \ && has_key(a:build_systems[a:bs_name], a:key)
endfunction " }}}

" Gets the value associated with 'key' for the given build system. It
" checks g:build#systems first, then searches the item in the fallback
" build system dict, which must contain the item.
function! s:get_buildsys_item(bs_name, key) " {{{
  if exists('g:build#systems')
    \ && s:has_buildsys_item(g:build#systems, a:bs_name, a:key)
    return g:build#systems[a:bs_name][a:key]
  else
    return s:build_systems[a:bs_name][a:key]
  endif
endfunction " }}}

" Returns true, if a target argument exists for the given target in the
" given build system dict.
function! s:has_target_args(build_systems, bs_name, target) " {{{
  return s:has_buildsys_item(a:build_systems, a:bs_name, 'target-args')
  \ && has_key(a:build_systems[a:bs_name]['target-args'], a:target)
endfunction " }}}

" Returns the arguments for the given target. If no args exist in
" g:build#systems and the fallback dict, it will return target itself.
function! s:get_target_args(target) " {{{
  if exists('g:build#systems')
    \ && s:has_target_args(g:build#systems, b:build_system_name, a:target)
    let l:build_info = g:build#systems[b:build_system_name]
    return l:build_info['target-args'][a:target]
  elseif s:has_target_args(s:build_systems, b:build_system_name, a:target)
    return s:build_systems[b:build_system_name]['target-args'][a:target]
  else
    return a:target
  endif
endfunction " }}}

" Return true, if the given dict contains the specified build target for
" the current file type.
function! s:has_lang_target(cmd_dict, target) " {{{
  return has_key(a:cmd_dict, &filetype)
    \ && has_key(a:cmd_dict[&filetype], a:target)
endfunction " }}}

" Setups makeprg, changes into the given dir and runs g:build#make_cmd
" inside it. It restores the previous makeprg and path afterwards.
function! s:run_in_env(dir, cmd) " {{{
  let l:old_makeprg = &l:makeprg
  let &l:makeprg = a:cmd
  execute 'lchdir! ' . escape(a:dir, '\ ')
  execute g:build#make_cmd
  lchdir! -
  let &l:makeprg = l:old_makeprg
endfunction " }}}

" Builds the target for the current file with rules from the given dict.
" This function expects a valid dict with all entries needed to build the
" current file. It takes an extra argument string for the build command.
function! s:build_lang_target(cmd_dict, target, extra_args) " {{{
  " Substitute all placeholders.
  let l:cmd = a:cmd_dict[&filetype][a:target]
  let l:cmd = substitute(l:cmd, '%PATH%', expand('%:p:h'), 'g')
  let l:cmd = substitute(l:cmd, '%NAME%', expand('%:t'),   'g')
  let l:cmd = substitute(l:cmd, '%HEAD%', expand('%:t:r'), 'g')

  call s:run_in_env(expand('%:p:h'), l:cmd . ' ' . a:extra_args)
endfunction " }}}

" Setups some variables and changes the current directory.
function! build#setup() " {{{
  let l:current_path = expand('%:p')
  if !strlen(l:current_path)
    return
  endif

  let l:known_systems = keys(s:build_systems)
  if exists('g:build#systems')
    " Only add build systems with existing build files and build commands.
    for l:bs_name in keys(g:build#systems)
      if has_key(s:build_systems, l:bs_name)
        continue
      elseif has_key(g:build#systems[l:bs_name], 'file')
        \ && has_key(g:build#systems[l:bs_name], 'command')
        call add(l:known_systems, l:bs_name)
      else
        echomsg "build.vim: the build system '" . l:bs_name
          \ . "' is incomplete"
        return
      endif
    endfor
  endif

  " Search all directories from the current files pwd upwards for known
  " build files.
  while l:current_path !~ '\v^(\/|\.)$'
    let l:current_path = fnamemodify(l:current_path, ':h')
    for l:build_name in l:known_systems
      for l:build_file in
        \ split(s:get_buildsys_item(l:build_name, 'file'), ',')
        if filereadable(l:current_path . '/' . l:build_file)
          let b:build_path = l:current_path
          let b:build_system_name = l:build_name
          return
        endif
      endfor
    endfor
  endwhile

  unlet! b:build_path
  unlet! b:build_system_name
endfunction " }}}

" Tries to initialize the current build system. Takes an arbitrary amount
" of arguments, which will be passed to the initialisation command.
function! build#init(...) " {{{
  if !exists('b:build_system_name')
    echo "The current file doesn't belong to a known build system"
  elseif exists('g:build#systems')
    \ && s:has_buildsys_item(g:build#systems, b:build_system_name, 'init')
    let l:init = g:build#systems[b:build_system_name].init
    call s:run_in_env(b:build_path, l:init . ' ' . join(a:000))
  elseif s:has_buildsys_item(s:build_systems, b:build_system_name, 'init')
    let l:init = s:build_systems[b:build_system_name].init
    call s:run_in_env(b:build_path, l:init . ' ' . join(a:000))
  else
    echo "'" . b:build_system_name . "' doesn't need to be initialized"
  endif
endfunction " }}}

" Builds the current project or file. The first argument is optional, but
" if specified, it must be a valid target name. If its omitted, it will
" fallback to 'build'. All other arguments will be passed directly to the
" build command.
function! build#target(...) " {{{
  " Handle optional arguments.
  if a:0
    let l:target = a:1
    let l:extra_args = join(a:000[1:])
  else
    let l:target = 'build'
    let l:extra_args = ''
  endif

  if exists('b:build_system_name')
    call s:run_in_env(b:build_path,
      \ s:get_buildsys_item(b:build_system_name, 'command')
      \ . ' ' . s:get_target_args(l:target) . ' ' . l:extra_args)
  elseif !strlen(expand('%:t'))
    echo 'build.vim: the current file has no name'
  elseif exists('g:build#languages')
    \ && s:has_lang_target(g:build#languages, l:target)
    call s:build_lang_target(g:build#languages, l:target, l:extra_args)
  elseif s:has_lang_target(s:language_cmds, l:target)
    call s:build_lang_target(s:language_cmds, l:target, l:extra_args)
  else
    echo 'Unable to ' . l:target . " '" . expand('%:t') . "'"
  endif
endfunction " }}}

" Runs 'makeprg'.
function! build#run_makeprg() " {{{
  if has('nvim')
    let l:cmd = &l:makeprg
    rightbelow new
    autocmd build BufWinLeave <buffer> wincmd p
    call termopen(l:cmd)
    startinsert
  else
    lmake!
  endif
endfunction " }}}
