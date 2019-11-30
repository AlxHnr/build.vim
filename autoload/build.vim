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
  \     'clean' : 'rm %HEAD%',
  \     'build' : 'gcc -std=c11 -Wall -Wextra %NAME% -o %HEAD%',
  \     'run'   : './%HEAD%',
  \   },
  \   'cpp':
  \   {
  \     'clean' : 'rm %HEAD%',
  \     'build' : 'g++ -std=c++11 -Wall -Wextra %NAME% -o %HEAD%',
  \     'run'   : './%HEAD%',
  \   },
  \   'd':
  \   {
  \     'clean' : 'rm %HEAD% %HEAD%.o',
  \     'build' : 'dmd %NAME%',
  \     'run'   : './%HEAD%',
  \   },
  \   'haskell':
  \   {
  \     'clean' : 'rm %HEAD%{,.hi,.o}',
  \     'build' : 'ghc %NAME%',
  \     'run'   : './%HEAD%',
  \   },
  \   'java':
  \   {
  \     'clean'  : 'rm %HEAD%.class',
  \     'build'  : 'javac -Xlint %NAME%',
  \     'run'    : 'java %HEAD%',
  \   },
  \   'nim':
  \   {
  \     'clean' : 'rm -rf nimcache %HEAD%',
  \     'build' : 'nim compile %NAME%',
  \     'run'   : './%HEAD%',
  \   },
  \   'ocaml':
  \   {
  \     'run' : 'ocaml %NAME%',
  \   },
  \   'racket':
  \   {
  \     'run'   : 'racket %NAME%',
  \     'build' : 'raco make -v %NAME%',
  \     'clean' : 'rm compiled/*_rkt.{dep,zo}; rm -rf compiled/drracket; rmdir compiled',
  \   },
  \   'rust':
  \   {
  \     'clean' : 'rm %HEAD%',
  \     'build' : 'rustc %NAME%',
  \     'run'   : './%HEAD%',
  \   },
  \   'scala':
  \   {
  \     'clean'  : 'rm %HEAD%*.class',
  \     'build'  : 'scalac %NAME%',
  \     'run'    : 'scala %HEAD%',
  \   },
  \   'tex':
  \   {
  \     'clean'  : 'rm %HEAD%.{aux,log,nav,out,pdf,snm,toc}',
  \     'build'  : 'pdflatex -file-line-error -halt-on-error %NAME%',
  \     'run'    : 'xdg-open %HEAD%.pdf',
  \   },
  \ }

" Add support for some scripting languages.
let s:scripting_languages =
  \ 'sh,csh,tcsh,zsh,sed,awk,lua,python,ruby,perl,perl6,tcl,scheme'

for s:language in split(s:scripting_languages, ',')
  let s:language_cmds[s:language] =
    \ { 'run' : 'chmod +x %NAME% && ./%NAME%' }
endfor

unlet s:scripting_languages s:language
" }}}

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

" Return the specified command for the given language. Will return 0 if the
" requested item doesn't exist. It will first look into g:build#languages
" and then fallback to s:language_cmds.
"
" Example:
"   s:get_lang_cmd('c', 'run')
" Returns:
"   './%HEAD%'
function! s:get_lang_cmd(language, cmd_name) " {{{
  if exists('g:build#languages')
    \ && has_key(g:build#languages, a:language)
    \ && has_key(g:build#languages[a:language], a:cmd_name)
    return g:build#languages[a:language][a:cmd_name]
  elseif has_key(s:language_cmds, a:language)
  \ && has_key(s:language_cmds[a:language], a:cmd_name)
    return s:language_cmds[a:language][a:cmd_name]
  else
    return 0
  endif
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
        echomsg "build.vim: build system '" . l:bs_name . "' is incomplete"
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

" Convert the given string list to a single string to be appended to shell
" commands.
function! s:to_shellescaped_string(list) " {{{
  return join(map(copy(a:list), {index, value -> shellescape(value)}))
endfunction " }}}

" Tries to initialize the current build system. Takes an arbitrary amount
" of arguments, which will be passed to the initialisation command.
function! build#init(...) " {{{
  let l:build_system = build#get_current_build_system()

  if empty(l:build_system)
    echo "The current file doesn't belong to a known build system"
    return
  endif

  let l:init_cmd = s:get_buildsys_item(l:build_system.name, 'init')
  if !empty(l:init_cmd)
    call s:run_in_env(l:build_system.path, l:init_cmd
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
    let l:target = a:1
    let l:escaped_target = shellescape(l:target)
    let l:extra_args = s:to_shellescaped_string(a:000[1:])
  else
    let l:target = ''
    let l:escaped_target = ''
    let l:extra_args = ''
  endif

  let l:build_system = build#get_current_build_system()

  if !empty(l:build_system)
    call s:run_in_env(l:build_system.path,
      \ s:get_buildsys_item(l:build_system.name, 'command')
      \ . ' ' . l:escaped_target . ' ' . l:extra_args)
  elseif !strlen(expand('%:t'))
    echo 'build.vim: the current file has no name'
  elseif strlen(l:target) == 0
    echo 'No build target specified'
  else
    let l:lang_cmd = s:get_lang_cmd(&filetype, l:target)

    if !empty(lang_cmd)
      call s:build_lang_target(l:lang_cmd, l:extra_args)
    else
      echo 'Unable to run "' . l:target . '" on "' . expand('%:t') . '"'
    endif
  endif
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

  echo 'The current file does not belong to any known build systems.'

  let l:global_cmds = {}
  if exists('g:build#languages') && has_key(g:build#languages, &filetype)
    let l:global_cmds = g:build#languages[&filetype]
  endif

  if empty(l:global_cmds) && !has_key(s:language_cmds, &filetype)
    return
  endif

  echo 'Here is a list of build targets and their associated commands'
  echo 'for the current file:'
  echo '-'

  for l:target in keys(l:global_cmds)
    echo l:target . ': ' . s:prepare_cmd_for_shell(l:global_cmds[l:target])
  endfor

  if has_key(s:language_cmds, &filetype)
    for l:target in keys(s:language_cmds[&filetype])
      if !has_key(l:global_cmds, l:target)
        echo l:target . ': '
          \ . s:prepare_cmd_for_shell(s:language_cmds[&filetype][l:target])
      endif
    endfor
  endif

  echo '-'
endfunction " }}}
