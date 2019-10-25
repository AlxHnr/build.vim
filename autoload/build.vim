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
  \   },
  \   'Cargo':
  \   {
  \     'file'    : 'Cargo.toml',
  \     'command' : 'cargo',
  \   },
  \   'CMake':
  \   {
  \     'file'    : 'CMakeLists.txt',
  \     'init'    : 'ln -sf build/compile_commands.json'
  \               . '&& mkdir -p build/'
  \               . '&& cd build/'
  \               . '&& cmake ../ -DCMAKE_EXPORT_COMPILE_COMMANDS=1',
  \     'command' : 'cmake --build ./build/ -- -j ' . s:jobs,
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
  \   },
  \   'Maven':
  \   {
  \     'file'    : 'pom.xml',
  \     'command' : 'mvn',
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

" Returns a dictionary containing informations about the current build
" system. If no build system could be found, an empty dictionary will be
" returned instead.
"
" Example: When run in a buffer containing /some/path/CMakeLists.txt
" Result:
" {
"   'name': 'CMake',
"   'path': '/some/path',
" }
function! s:detect_buildsystem() " {{{
  let l:current_path = expand('%:p')
  if !strlen(l:current_path)
    return {}
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
        return {}
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
          return {
            \ 'name': l:build_name,
            \ 'path': l:current_path,
            \ }
        endif
      endfor
    endfor
  endwhile
endfunction " }}}

" Convert the given string list to a single string to be appended to shell
" commands.
function! s:to_shellescaped_string(list) " {{{
  return join(map(copy(a:list), {index, value -> shellescape(value)}))
endfunction " }}}

" Tries to initialize the current build system. Takes an arbitrary amount
" of arguments, which will be passed to the initialisation command.
function! build#init(...) " {{{
  let l:build_system = s:detect_buildsystem()

  if empty(l:build_system)
    echo "The current file doesn't belong to a known build system"
  elseif exists('g:build#systems')
    \ && s:has_buildsys_item(g:build#systems, l:build_system.name, 'init')
    let l:init = g:build#systems[l:build_system.name].init
    call s:run_in_env(l:build_system.path, l:init
      \ . ' ' . s:to_shellescaped_string(a:000))
  elseif s:has_buildsys_item(s:build_systems, l:build_system.name, 'init')
    let l:init = s:build_systems[l:build_system.name].init
    call s:run_in_env(l:build_system.path, l:init
      \ . ' ' . s:to_shellescaped_string(a:000))
  else
    echo "'" . l:build_system.name . "' doesn't need to be initialized"
  endif
endfunction " }}}

" Build the current project or file. All optional arguments will be passed
" directly to the build command.
function! build#target(...) " {{{
  " Handle optional arguments.
  if a:0
    let l:target = shellescape(a:1)
    let l:extra_args = s:to_shellescaped_string(a:000[1:])
  else
    let l:target = ''
    let l:extra_args = ''
  endif

  let l:build_system = s:detect_buildsystem()

  if !empty(l:build_system)
    call s:run_in_env(l:build_system.path,
      \ s:get_buildsys_item(l:build_system.name, 'command')
      \ . ' ' . l:target . ' ' . l:extra_args)
  elseif !strlen(expand('%:t'))
    echo 'build.vim: the current file has no name'
  elseif strlen(l:target) == 0
    echo 'No build target specified'
  elseif exists('g:build#languages')
    \ && s:has_lang_target(g:build#languages, l:target)
    call s:build_lang_target(g:build#languages, l:target, l:extra_args)
  elseif s:has_lang_target(s:language_cmds, l:target)
    call s:build_lang_target(s:language_cmds, l:target, l:extra_args)
  else
    echo 'Unable to ' . l:target . ' ' . expand('%:t')
  endif
endfunction " }}}

" Runs 'makeprg'.
function! build#run_makeprg() " {{{
  if has('nvim')
    let l:cmd = &l:makeprg
    rightbelow new
    autocmd WinLeave <buffer> wincmd p
    call termopen(l:cmd)
    startinsert
  else
    lmake!
  endif
endfunction " }}}
