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
  \               . ' && mkdir -p build/'
  \               . ' && cd build/'
  \               . ' && cmake ../ -DCMAKE_EXPORT_COMPILE_COMMANDS=1',
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
  \     'clean' : 'rm ./%HEAD%',
  \     'build' : 'gcc -std=c11 -Wall -Wextra ./%NAME% -o ./%HEAD%',
  \     'run'   : './%HEAD%',
  \   },
  \   'cpp':
  \   {
  \     'clean' : 'rm ./%HEAD%',
  \     'build' : 'g++ -std=c++17 -Wall -Wextra ./%NAME% -o ./%HEAD%',
  \     'run'   : './%HEAD%',
  \   },
  \   'd':
  \   {
  \     'clean' : 'rm ./%HEAD% ./%HEAD%.o',
  \     'build' : 'dmd ./%NAME%',
  \     'run'   : './%HEAD%',
  \   },
  \   'haskell':
  \   {
  \     'clean' : 'rm ./%HEAD%{,.hi,.o}',
  \     'build' : 'ghc ./%NAME%',
  \     'run'   : './%HEAD%',
  \   },
  \   'java':
  \   {
  \     'clean'  : 'rm ./%HEAD%.class',
  \     'build'  : 'javac -Xlint ./%NAME%',
  \     'run'    : 'java ./%HEAD%',
  \   },
  \   'nim':
  \   {
  \     'clean' : 'rm -rf nimcache ./%HEAD%',
  \     'build' : 'nim compile ./%NAME%',
  \     'run'   : './%HEAD%',
  \   },
  \   'ocaml':
  \   {
  \     'build' : 'dune build',
  \     'clean' : 'dune clean',
  \     'run'   : 'dune exec ./%HEAD%.exe',
  \   },
  \   'racket':
  \   {
  \     'run'   : 'racket ./%NAME%',
  \     'build' : 'raco make -v ./%NAME%',
  \     'clean' : 'rm compiled/*_rkt.{dep,zo}; rm -rf compiled/drracket; rmdir compiled',
  \   },
  \   'rust':
  \   {
  \     'clean' : 'rm ./%HEAD%',
  \     'build' : 'rustc ./%NAME%',
  \     'run'   : './%HEAD%',
  \   },
  \   'scala':
  \   {
  \     'clean'  : 'rm ./%HEAD%*.class',
  \     'build'  : 'scalac ./%NAME%',
  \     'run'    : 'scala ./%HEAD%',
  \   },
  \   'tex':
  \   {
  \     'clean'  : 'rm ./%HEAD%.{aux,log,nav,out,pdf,snm,toc}',
  \     'build'  : 'pdflatex -file-line-error -halt-on-error ./%NAME%',
  \     'run'    : 'xdg-open ./%HEAD%.pdf',
  \   },
  \ }

" Add support for some scripting languages.
let s:scripting_languages =
  \ 'sh,csh,tcsh,zsh,sed,awk,lua,python,ruby,perl,perl6,tcl,scheme'

for s:language in split(s:scripting_languages, ',')
  let s:language_cmds[s:language] =
    \ { 'run' : 'chmod +x ./%NAME% && ./%NAME%' }
endfor

unlet s:scripting_languages s:language
" }}}

" Logs the given message.
function! s:log(message) " {{{
  echo 'build.vim: ' . a:message . '.'
endfunction " }}}
"
" Logs the given error message.
function! s:log_err(message) " {{{
  echoerr 'build.vim: ' . a:message . '.'
endfunction " }}}

" Return the specified key for the given build system. Will return 0 if the
" requested item doesn't exist. It will first look into g:build#systems and
" then fallback to s:build_systems.
"
" Example:
"   s:get_buildsys_item('CMake', 'file')
" Returns:
"   'CMakeLists.txt'
function! s:get_buildsys_item(bs_name, key) " {{{
  if exists('g:build#systems')
    \ && has_key(g:build#systems, a:bs_name)
    \ && has_key(g:build#systems[a:bs_name], a:key)
    return g:build#systems[a:bs_name][a:key]
  elseif has_key(s:build_systems, a:bs_name)
    \ && has_key(s:build_systems[a:bs_name], a:key)
    return s:build_systems[a:bs_name][a:key]
  else
    return 0
  endif
endfunction " }}}

" Return a dictionary containing all fallback targets for the specified language. Will return an
" empty dictionary if no fallback targets exist. Both s:language_cmds and g:build#languages are
" considered, while the latter has a higher priority.
"
" Example:
"   s:gather_fallback_targets('c')
" Returns:
"   {
"     'clean' : 'rm ./%HEAD%',
"     'build' : 'gcc -std=c11 -Wall -Wextra ./%NAME% -o ./%HEAD%',
"     'run'   : './%HEAD%',
"   }
function! s:gather_fallback_targets(language) " {{{
  let l:commands = {}
  if has_key(s:language_cmds, a:language)
    let l:commands = copy(s:language_cmds[a:language])
  endif
  if exists('g:build#languages') && has_key(g:build#languages, a:language)
    call extend(l:commands, g:build#languages[a:language])
  endif

  return l:commands
endfunction " }}}

" Run the given command in the specified directory.
function! s:run_in_env(dir, cmd) " {{{
  if has('nvim')
    rightbelow new
    autocmd WinLeave <buffer> wincmd p
    call termopen(a:cmd, {'cwd': a:dir})
    startinsert
  else
    " Fall back to lmake in legacy Vim.
    let l:old_makeprg = &l:makeprg
    let &l:makeprg = a:cmd
    execute 'lchdir! ' . escape(a:dir, '\ ')
    lmake!
    lchdir! -
    let &l:makeprg = l:old_makeprg
  endif
endfunction " }}}

" Expands various placeholders in the given string and escapes it to
" be appended to shell commands.
"
" Example:
"   s:prepare_cmd_for_shell('This is %NAME%')
" Returns:
"   "This is 'main.cpp'"
function! s:prepare_cmd_for_shell(str) " {{{
  let l:str = a:str
  let l:str = substitute(l:str, '%PATH%', escape(shellescape(expand('%:p:h')), '\'), 'g')
  let l:str = substitute(l:str, '%NAME%', escape(shellescape(expand('%:t')), '\'),   'g')
  let l:str = substitute(l:str, '%HEAD%', escape(shellescape(expand('%:t:r')), '\'), 'g')
  return l:str
endfunction " }}}

" Builds the target for the current file with rules from the given dict.
" This function expects a valid dict with all entries needed to build the
" current file. It takes an extra argument string for the build command.
function! s:build_lang_target(cmd, extra_args) " {{{
  call s:run_in_env(expand('%:p:h'),
    \ s:prepare_cmd_for_shell(a:cmd) . ' ' . a:extra_args)
endfunction " }}}

" Merge the names in s:build_systems with g:build#systems, prioritising the
" latter. Returns {} if g:build#systems is broken.
"
" Example:
"   call s:get_list_of_known_build_system_names()
" Result:
"   ['CMake', 'Cargo', 'Maven']
function! s:get_list_of_known_build_system_names() " {{{
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
        call s:log_err('build system "' . l:bs_name . '" is incomplete')
        return {}
      endif
    endfor
  endif

  return l:known_systems
endfunction " }}}

" Check if the specified directory contains any build-system files
" belonging to the given list of build-systems. Returns the name of the
" first matching build system on success or {} on failure.
"
" Example:
"   call s:get_first_build_system_in_dir('/path/to/project', ['CMake', 'Maven'])
" Returns: When the given path contains "CMakeList.txt".
"   "CMake"
" Returns: When the given path contains neither "CMakeList.txt" nor "pom.xml".
"   {}
function! s:get_first_build_system_in_dir(dir, build_system_names) " {{{
  for l:build_name in a:build_system_names
    for l:build_file in split(s:get_buildsys_item(l:build_name, 'file'), ',')
      if filereadable(a:dir . '/' . l:build_file)
        return l:build_name
      endif
    endfor
  endfor

  return {}
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
function! build#get_current_build_system() " {{{
  let l:current_path = expand('%:p')
  if !strlen(l:current_path)
    return {}
  endif

  let l:known_systems = s:get_list_of_known_build_system_names()

  " Check the current working directory first. This is useful in combination with plugins which
  " chdir into the projects root directory.
  if stridx(l:current_path, getcwd()) == 0
    let l:build_system_name = s:get_first_build_system_in_dir(getcwd(), l:known_systems)
    if !empty(l:build_system_name)
      return {
        \ 'name': l:build_system_name,
        \ 'path': getcwd(),
        \ }
    endif
  endif

  " Search all directories from the current files pwd upwards for known
  " build files.
  while l:current_path !~ '\v^(\/|\.)$'
    let l:current_path = fnamemodify(l:current_path, ':h')
    let l:build_system_name = s:get_first_build_system_in_dir(l:current_path, l:known_systems)
    if !empty(l:build_system_name)
      return {
        \ 'name': l:build_system_name,
        \ 'path': l:current_path,
        \ }
    endif
  endwhile
endfunction " }}}

" Try to initialize the init system to which the current file belongs. Takes one optional string
" containing arguments to be passed to the build systems init command.
"
" Examples:
"   1) call build#init()
"   2) call build#init('--enable-gtk --cflags="-O2 -Wall"')
"
" If the current file belongs to an autotools project, it will run the following commands:
"   1) ./configure
"   2) ./configure --enable-gtk --cflags="-O2 -Wall"
function! build#init(...) " {{{
  if a:0 > 1
    return s:log_err('build#init(): too many arguments. Takes 0 or 1 argument')
  endif

  let l:build_system = build#get_current_build_system()

  if empty(l:build_system)
    return s:log('Current file does not belong to any known build system')
  endif

  let l:init_cmd = s:get_buildsys_item(l:build_system.name, 'init')
  if empty(l:init_cmd)
    return s:log('Build system "' . l:build_system.name . '" does not need to be initialized')
  endif

  call s:run_in_env(l:build_system.path, l:init_cmd . (a:0? ' ' . a:1 : ''))
endfunction " }}}

" Print usage examples for the given fallback targets.
function! s:print_fallback_examples(fallback_targets) " {{{
  for [target, command] in items(a:fallback_targets)
    echo '  :Build ' . target . ' [args...]'
    echo '      => ' . s:prepare_cmd_for_shell(command) . ' [args...]'
  endfor
endfunction " }}}

" Try to build the given optional target with the specified optional arguments. The target and its
" arguments must be supplied as a single string. The first part of this string specifies the target:
" '[TARGET [args...]]', e.g. 'clean' or 'clean --all'.
"
" Examples:
"   1) call build#target()
"   2) call build#target('build')
"   3) call build#target('build -O2 -DMY_MACRO="Value 123"')
"   4) call build#target('all CFLAGS="-O2 -Werror"')
"   5) call build#target('clean')
"
" If the current file belongs to an autotools project, it will run the following commands:
"   1) make --jobs=8
"   2) make --jobs=8 build
"   3) make --jobs=8 build -O2 -DMY_MACRO="Value 123"
"   4) make --jobs=8 all CFLAGS="-O2 -Werror"
"   5) make --jobs=8 clean
"
" If the current file is a standalone C file which does not belong to any known build system, it
" will run the following commands:
"   1) gcc -std=c11 -Wall -Wextra ./'foo.c' -o ./'foo'
"   2) gcc -std=c11 -Wall -Wextra ./'foo.c' -o ./'foo'
"   3) gcc -std=c11 -Wall -Wextra ./'foo.c' -o ./'foo' -O2 -DMY_MACRO="Value 123"
"   4) -- ERROR: target 'all' is not defined for C files --
"   5) rm ./'foo'
function! build#target(...) " {{{
  if a:0 > 1
    return s:log_err('build#target(): too many arguments. Takes 0 or 1 argument')
  endif

  let l:build_system = build#get_current_build_system()
  if !empty(l:build_system)
    let l:command = s:get_buildsys_item(l:build_system.name, 'command')
    call s:run_in_env(l:build_system.path, l:command . (a:0? ' ' . a:1 : ''))
    return
  endif

  if !strlen(expand('%:t'))
    return s:log('Current file has no name')
  endif

  if a:0 == 0
    let l:target = 'build'
    let l:extra_args = ''
  else
    let l:split_args = matchlist(a:1, '\v^\s*(\S*)\s*(.*)$')
    let l:target = l:split_args[1]
    let l:extra_args = l:split_args[2]
  endif

  let l:commands = s:gather_fallback_targets(&filetype)
  if empty(l:commands)
    call s:log('Current file does not belong to any known build system')
    call s:log('No fallback commands defined for filetype "' . &filetype . '"')
    return
  endif

  if !has_key(l:commands, l:target)
    call s:log('Current file does not belong to any known build system')
    call s:log('Fallback target "' . l:target . '" is not defined for the filetype "'
      \ . &filetype . '"')
    echo "\n"
    echo 'Commands available for this file:'
    call s:print_fallback_examples(l:commands)
    return
  endif

  call s:build_lang_target(l:commands[l:target], l:extra_args)
endfunction " }}}

" Print build informations about the current file.
function! build#info() " {{{
  let l:build_system = build#get_current_build_system()

  if !empty(l:build_system)
    let l:command = s:get_buildsys_item(l:build_system.name, 'command')

    echo 'Build system:      ' . l:build_system.name
    echo 'Project directory: ' . l:build_system.path
    echo '-'
    echo 'Build command:     ' . l:command

    let l:init_cmd = s:get_buildsys_item(l:build_system.name, 'init')
    if !empty(l:init_cmd)
      echo 'Init command:      ' . l:init_cmd
    endif

    echo '-'
    return
  endif

  echo 'The current file does not belong to any known build system.'

  let l:commands = s:gather_fallback_targets(&filetype)
  if empty(l:commands)
    echo 'No fallback commands defined for filetype "' . &filetype . '".'
    return
  endif

  echo 'Fallback commands are provided. See the examples below.'
  echo "\n"
  echo 'Usage:'
  echo '  :Build [TARGET [args...]]'
  echo "\n"
  echo 'Examples:'
  call s:print_fallback_examples(l:commands)
endfunction " }}}
