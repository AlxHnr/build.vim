" Copyright (c) 2014 Alexander Heinrich <alxhnr@nudelpost.de> {{{
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

" Informations about various builds systems. {{{
let s:build_systems =
  \ {
  \   'make':
  \   {
  \     'file'    : 'Makefile,makefile',
  \     'command' : 'make',
  \     'target-args':
  \     {
  \       'build' : 'all',
  \     },
  \   },
  \   'CMake':
  \   {
  \     'file'    : 'CMakeLists.txt',
  \     'command' : 'cmake',
  \     'target-args':
  \     {
  \       'build' : 'all',
  \     },
  \     'target-flags':
  \     {
  \       'clean' : 'uninit',
  \     },
  \   },
  \   'dub':
  \   {
  \     'file'    : 'dub.json',
  \     'command' : 'dub',
  \   },
  \ }
" }}}

" Fallback build commands for specific languages. {{{
let s:language_fallback_commands =
  \ {
  \   'c':
  \   {
  \     'clean' : 'rm "%OUTPUT%"',
  \     'build' : 'gcc -std=c11 -Wall -Wextra "%FILE%" -o "%OUTPUT%"',
  \     'run'   : './"%OUTPUT%"',
  \   },
  \   'cpp':
  \   {
  \     'inherit' : 'c',
  \     'build'   : 'g++ -std=c++11 -Wall -Wextra "%FILE%" -o "%OUTPUT%"',
  \   },
  \   'd':
  \   {
  \     'clean' : 'rm "%OUTPUT%" "%OUTPUT%.o"',
  \     'build' : 'dmd "%FILE%"',
  \     'run'   : './"%OUTPUT%"',
  \   },
  \   'java':
  \   {
  \     'clean'  : 'rm "%OUTPUT%"',
  \     'build'  : 'javac -Xlint "%FILE%"',
  \     'run'    : 'java "%RAW_OUT%"',
  \     'output' : '%OUTPUT%.class',
  \   },
  \   'tex':
  \   {
  \     'clean'  : 'rm "%RAW_OUT%".{aux,log,nav,out,pdf,snm,toc}',
  \     'build'  : 'pdflatex -file-line-error -halt-on-error "%FILE%"',
  \     'run'    : 'xdg-open "%OUTPUT%"',
  \     'output' : '%OUTPUT%.pdf',
  \   },
  \   'ocaml':
  \   {
  \     'run' : 'ocaml "%FILE%"',
  \   },
  \   'sh,lua,python':
  \   {
  \     'run' : 'chmod +x "%FILE%" && ./"%FILE%"',
  \   },
  \ }

if exists('g:is_chicken')
  let s:language_fallback_commands.scheme =
  \ {
  \   'inherit' : 'c',
  \   'build' : 'csc -O3 "%FILE%" -o "%OUTPUT%"',
  \ }
endif
" }}}

" Resolve content in 's:language_fallback_commands'. {{{
let s:language_commands = {}
for [ languages, table ] in items(s:language_fallback_commands)
  let s:inherited_languages = {}
  let s:body = {}

  " Resolve inheritance.
  if has_key(table, 'inherit')
    for language in split(table.inherit, ',')
      if has_key(s:inherited_languages, language)
        echoerr "fatal: '" . languages . "' tries to inherit from "
          \ . language . " multiple times."
        finish
      endif
      let s:inherited_languages[language] = 1

      " Copy content from inherited languages into body.
      if has_key(s:language_commands, language)
        for [ entry_name, content ] in items(s:language_commands[language])
          let s:body[entry_name] = content
        endfor
      else
        echoerr "fatal: '" . languages . "' can't inherit from"
          \ . " unresolved language '" . language . "'."
        finish
      endif
    endfor
  endif

  " Overwrite inherited items with language specific values.
  for [ entry_name, content ] in items(table)
    if entry_name != 'inherit'
      let s:body[entry_name] = content
    endif
  endfor

  for language in split(languages, ',')
    let s:language_commands[language] = s:body
  endfor
endfor
" }}}

function! build#setup() " {{{
  let l:current_path = expand('%:p')
  if !strlen(l:current_path)
    return
  endif

  " Search all directories from the current files pwd upwards for known
  " build files.
  while l:current_path !~ '\v^(\/|\.)$'
    let l:current_path = fnamemodify(l:current_path, ':h')
    for l:build_name in keys(s:build_systems)
      for l:build_file in split(s:build_systems[l:build_name].file, ',')
        if filereadable(l:current_path . '/' . l:build_file)
          let b:build_path = l:current_path
          let b:build_system_name = l:build_name
          let &l:makeprg = s:build_systems[l:build_name].command

          if exists('g:build#autochdir') && g:build#autochdir
            execute 'lchdir! ' . escape(b:build_path, '\ ')
          endif
          return
        endif
      endfor
    endfor
  endwhile

  unlet! b:build_path
  unlet! b:build_system_name
endfunction " }}}

function! build#target(name) " {{{
  if exists('b:build_path')
    let l:build_info = s:build_systems[b:build_system_name]

    " Determine arguments for the current build target.
    if has_key(l:build_info, 'target-args')
      \ && has_key(l:build_info['target-args'], a:name)
      let l:target_args = l:build_info['target-args'][a:name]
    else
      let l:target_args = a:name
    endif

    " Handle the build target in the build directory.
    execute 'lchdir! ' . escape(b:build_path, '\ ')
    execute 'lmake! ' . l:target_args
    lchdir! -
  endif
endfunction " }}}
