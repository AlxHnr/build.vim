if executable('nproc')
  let s:jobs = systemlist('nproc')[0]
else
  let s:jobs = 1
endif

let s:current_build_system = {}

" Informations about various builds systems. {{{
let s:build_systems =
  \ {
  \   'Autotools':
  \   {
  \     'file'     : 'configure',
  \     'commands' :
  \     {
  \        'do'    : 'make --jobs=' . s:jobs,
  \        'build' : 'make --jobs=' . s:jobs,
  \        'clean' : 'make --jobs=' . s:jobs . ' clean',
  \        'init'  : './configure',
  \        'run'   : './%RELPATH%/%HEAD%',
  \        'test' : 'make --jobs=' . s:jobs . ' test',
  \     }
  \   },
  \   'Cargo':
  \   {
  \     'file'     : 'Cargo.toml',
  \     'commands' :
  \     {
  \        'do'    : 'cargo',
  \        'build' : 'cargo build',
  \        'clean' : 'cargo clean',
  \        'run'   : 'cargo run',
  \        'test'  : 'cargo test',
  \     },
  \   },
  \   'CMake':
  \   {
  \     'file'     : 'CMakeLists.txt',
  \     'commands' :
  \     {
  \        'do'    : 'cmake --build ./build/ -- -j ' . s:jobs,
  \        'build' : 'cmake --build ./build/ -- -j ' . s:jobs,
  \        'clean' : 'rm -r build',
  \        'init'  : 'ln -sf build/compile_commands.json'
  \                . ' && mkdir -p build/'
  \                . ' && cd build/'
  \                . ' && cmake ../ -DCMAKE_EXPORT_COMPILE_COMMANDS=1',
  \        'run'   : './build/%HEAD%',
  \        'test' : 'cmake --build ./build/ -- -j ' . s:jobs . ' test',
  \     },
  \   },
  \   'DUB':
  \   {
  \     'file'     : 'dub.json',
  \     'commands' :
  \     {
  \        'do'    : 'dub',
  \        'build' : 'dub build',
  \        'clean' : 'dub clean',
  \        'run'   : 'dub run',
  \        'test'  : 'dub test',
  \     },
  \   },
  \   'Dune':
  \   {
  \     'file'     : 'dune',
  \     'commands' :
  \     {
  \       'do'     : 'dune',
  \       'build'  : 'dune build',
  \       'clean'  : 'dune clean',
  \       'run'    : 'dune exec ./%RELPATH%/%HEAD%.exe',
  \       'test'   : 'dune runtest',
  \     },
  \   },
  \   'Make':
  \   {
  \     'file'     : 'Makefile,makefile',
  \     'commands' :
  \     {
  \        'do'    : 'make --jobs=' . s:jobs,
  \        'build' : 'make --jobs=' . s:jobs,
  \        'clean' : 'make --jobs=' . s:jobs . ' clean',
  \        'run'   : './%RELPATH%/%HEAD%',
  \        'test'  : 'make --jobs=' . s:jobs . ' test',
  \     }
  \   },
  \   'Maven':
  \   {
  \     'file'     : 'pom.xml',
  \     'commands' :
  \     {
  \        'do'    : 'mvn',
  \        'build' : 'mvn build',
  \        'clean' : 'mvn clean',
  \        'test'  : 'mvn test',
  \     }
  \   },
  \   'Nimble':
  \   {
  \     'file'    : '*.nimble',
  \     'command' : 'nimble',
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
  \     'build' : 'ocamlc ./%NAME%',
  \     'clean' : 'rm -f ./%HEAD%',
  \     'run'   : 'ocaml ./%NAME%',
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

" Return the path dest relative to the path start
" if dest or start are relative path, they are taken
" relative to the current working directory
" Example:
"   " current working directory is /a/b/c
"   s:relative_to('/a/b/d/e/f/g', '../d/e')
" Returns:
"   'f/g'
function! s:relative_to(dest, start) " {{{
  " make sure both path are absolute
  let l:dest = fnamemodify(a:dest, ':p')
  let l:start = fnamemodify(a:start, ':p')

  let l:initial_wd = getcwd()

  " move to the starting directory
  exec 'lcd '.l:start
  " expand the destination into a relative path to cwd
  let l:dest = fnamemodify(l:dest, ':.')
  " move back to were we started
  exec 'lcd '.l:initial_wd
  return l:dest
endfunction " }}}

" Return the specified key for the given build system. Will return 0 if the
" requested item doesn't exist. It will first look into g:build#systems and then
" fallback to s:build_systems.
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

" Return a dictionary containing all available commands for the specified
" build system. Will return an empty dictionary if nothing is found.
" If the build_system is not a fallback, both g:build#systems and
" s:build#systems are considered, the former overwriting the latter.
" It the build_system is a fallback, both g:build#languages and s:language_cmds
" are considered.
"
" Example:
"   s:gather_commands({'name': 'c', 'fallback': v:true))
" Returns:
"   {
"     'clean' : 'rm ./%HEAD%',
"     'build' : 'gcc -std=c11 -Wall -Wextra ./%NAME% -o ./%HEAD%',
"     'run'   : './%HEAD%',
"   }
function! s:gather_commands(build_system) " {{{
  let l:commands = {}
  let l:name = a:build_system.name

  if a:build_system.fallback
    if has_key(s:language_cmds, l:name)
      let l:commands = copy(s:language_cmds[l:name])
    endif
    if exists('g:build#languages') && has_key(g:build#languages, l:name)
      call extend(l:commands, g:build#languages[l:name])
    endif
  else
    if has_key(s:build_systems, l:name) && has_key(s:build_systems[l:name], 'commands')
      let l:commands = copy(s:build_systems[l:name].commands)
    endif
    if exists('g:build#systems')
      \ && has_key(g:build#systems, l:name)
      \ && has_key(g:build#systems[l:name], 'commands')
      call extend(l:commands, g:build#systems[l:name].commands)
    endif
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
"   s:prepare_cmd_for_shell('This is %NAME%',
"         \ {'fallback': v:true'})
" Returns:
"   "This is 'main.cpp'"
function! s:prepare_cmd_for_shell(str, build_system) " {{{
  let l:str = a:str
  let l:str = substitute(l:str, '%PATH%', escape(shellescape(expand('%:p:h')), '\'), 'g')
  let l:str = substitute(l:str, '%NAME%', escape(shellescape(expand('%:t')), '\'),   'g')
  let l:str = substitute(l:str, '%HEAD%', escape(shellescape(expand('%:t:r')), '\'), 'g')
  if a:build_system.fallback
    let l:str = substitute(l:str, '%RELPATH%', '.', 'g')
  else
    let l:str = substitute(l:str, '%RELPATH%',
          \ escape(shellescape(s:relative_to(expand('%:p:h'), a:build_system.path)), '\'),
          \ 'g')
  endif
  return l:str
endfunction " }}}

" Run the command with eventual arguments at the location of the build_system
function! s:run_command(cmd, extra_args, build_system) " {{{
  let l:path = a:build_system.fallback? expand('%:p:h') : a:build_system.path
  let l:command = s:prepare_cmd_for_shell(a:cmd, a:build_system)
        \ . (empty(a:extra_args)? '' : ' ' . a:extra_args)
  call s:run_in_env(l:path, l:command)
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
            \ && has_key(g:build#systems[l:bs_name], 'commands')
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
      if !empty(globpath(a:dir, l:build_file))
        return l:build_name
      endif
    endfor
  endfor

  return {}
endfunction " }}}

" Returns a dictionary containing informations about the current build
" system. If no build system could be found, a fallback build system
" based on file type is proposed
" The result is stored on the first call and the research will not be done
" again. To force the research to be refreshed, provide v:true as an optional
" argument.
"
" Example: When run in a buffer containing /some/path/CMakeLists.txt
"   build#get_current_build_system()
" Result:
" {
"   'name': 'CMake',
"   'path': '/some/path',
"   'fallback': v:false,
" }
function! build#get_current_build_system(...) " {{{
  if !empty(s:current_build_system) && (a:0 == 0 || !a:1)
    return s:current_build_system
  end

  let l:current_path = expand('%:p')
  if !strlen(l:current_path)
    let s:current_build_system = {'name': &filetype, 'fallback': v:true, 'path': '.'}
    return s:current_build_system
  endif

  let l:known_systems = s:get_list_of_known_build_system_names()

  " Check the current working directory first. This is useful in combination with plugins which
  " chdir into the projects root directory.
  if stridx(l:current_path, getcwd()) == 0
    let l:build_system_name = s:get_first_build_system_in_dir(getcwd(), l:known_systems)
    if !empty(l:build_system_name)
      let s:current_build_system = {
        \ 'name': l:build_system_name,
        \ 'path': getcwd(),
        \ 'fallback': v:false,
        \ }
      return s:current_build_system
    endif
  endif

  " Search all directories from the current files pwd upwards for known
  " build files.
  while l:current_path !~ '\v^(\/|\.)$'
    let l:current_path = fnamemodify(l:current_path, ':h')
    let l:build_system_name = s:get_first_build_system_in_dir(l:current_path, l:known_systems)
    if !empty(l:build_system_name)
      let s:current_build_system = {
        \ 'name': l:build_system_name,
        \ 'path': l:current_path,
        \ 'fallback': v:false,
        \ }
      return s:current_build_system
    endif
  endwhile
  let s:current_build_system = {'name': &filetype, 'fallback': v:true, 'path': '.'}
  return s:current_build_system
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
  elseif a:0 ==# 1
    return build#target('init ' . a:1)
  else
    return build#target('init')
  endif
endfunction " }}}

" Print usage examples for the given commands.
function! s:print_command_examples(commands, build_system) " {{{
  for [l:subcmd, l:command] in items(a:commands)
    echo '  :Build ' . l:subcmd . ' [args...]'
    echo '      => ' . s:prepare_cmd_for_shell(l:command, a:build_system) . ' [args...]'
  endfor
endfunction " }}}

" Print an info message for the given build system
function! s:info_message(build_system)
  let l:commands = s:gather_commands(a:build_system)

  if a:build_system.fallback
    call s:log('Current file does not belong to any known build system')
    if empty(l:commands)
      echo 'No fallback commands defined for filetype "' . &filetype . '".'
      return
    endif
    echo 'Fallback commands are provided. See the examples below.'
  else
    echo 'Build system:      ' . a:build_system.name
    echo 'Project directory: ' . a:build_system.path
  endif
endfunction

" Print a help message for the given build system
function! s:help_message(build_system)
  let l:commands = s:gather_commands(a:build_system)
  echo 'Usage:'
  echo '  :Build [SUBCMD [args...]]'
  echo "\n"
  echo 'Examples:'
  call s:print_command_examples(l:commands, a:build_system)
endfunction

" Run the provided subcommand. If no argument is provided, the default
" subcommand is build.  Arguments must be supplied as a single string.
" '[SUBCMD [args...]]', e.g. 'clean' or 'clean --all'.
"
" Examples:
"   1) call build#target()
"   2) call build#target('build')
"   3) call build#target('build -O2 -DMY_MACRO="Value 123"')
"   4) call build#target('do all CFLAGS="-O2 -Werror"')
"   5) call build#target('clean')
"
" If the current file belongs to an autotools project, it will run the following commands:
"   1) make --jobs=8
"   2) make --jobs=8
"   3) make --jobs=8 -O2 -DMY_MACRO="Value 123"
"   4) make --jobs=8 all CFLAGS="-O2 -Werror"
"   5) make --jobs=8 clean
"
" If the current file is a standalone C file which does not belong to any known build system, it
" will run the following commands:
"   1) gcc -std=c11 -Wall -Wextra ./'foo.c' -o ./'foo'
"   2) gcc -std=c11 -Wall -Wextra ./'foo.c' -o ./'foo'
"   3) gcc -std=c11 -Wall -Wextra ./'foo.c' -o ./'foo' -O2 -DMY_MACRO="Value 123"
"   4) -- ERROR: command 'do' is not defined for C files --
"   5) rm ./'foo'
function! build#target(...) " {{{
  if a:0 > 1
    return s:log_err('build#target(): too many arguments. Takes 0 or 1 argument')
  endif

  let l:build_system = build#get_current_build_system()

  if !strlen(expand('%:t'))
    return s:log('Current file has no name')
  endif

  if a:0 == 0
    let l:subcmd = 'build'
    let l:extra_args = ''
  else
    let l:split_args = matchlist(a:1, '\v^\s*(\S*)\s*(.*)$')
    let l:subcmd = l:split_args[1]
    let l:extra_args = l:split_args[2]
  endif

  if l:subcmd ==# 'help'
    return s:help_message(l:build_system)
  elseif l:subcmd ==# 'info'
    return s:info_message(l:build_system)
  endif

  let l:commands = s:gather_commands(l:build_system)
  if empty(l:commands)
    if l:build_system.fallback
      call s:log('Current file does not belong to any known build system')
      call s:log('No fallback commands defined for filetype "' . &filetype . '"')
    else
      call s:log('The build system "'.l:build_system.name.'" does not have any commands defined.')
    endif
    return
  endif

  if !has_key(l:commands, l:subcmd)
    if l:build_system.fallback
      call s:log('Current file does not belong to any known build system')
      call s:log('Command "' . l:subcmd . '" is not defined for the filetype "' . &filetype . '"')
    else
      call s:log('Command "' . l:subcmd . '" is not defined for the build system "'
        \ . l:build_system.name . '"')
    endif
    echo "\n"
    call s:help_message(l:build_system)
    return
  endif

  call s:run_command(l:commands[l:subcmd], l:extra_args, l:build_system)
endfunction " }}}

" Print build informations about the current file.
function! build#info() " {{{
  let l:build_system = build#get_current_build_system()
  call s:info_message(l:build_system)
  echo "\n"
  call s:help_message(l:build_system)
endfunction " }}}
