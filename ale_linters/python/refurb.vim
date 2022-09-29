" Author: Sebastien Williams-Wynn <s.williamswynn.mail@gmail.com>
" Description: Refurb support for python modernisation

call ale#Set('python_refurb_executable', 'refurb')
call ale#Set('python_refurb_options', '')
call ale#Set('python_refurb_use_global', get(g:, 'ale_use_global_executables', 0))
call ale#Set('python_refurb_auto_pipenv', 0)

function! ale_linters#python#refurb#GetExecutable(buffer) abort
    if (ale#Var(a:buffer, 'python_auto_pipenv') || ale#Var(a:buffer, 'python_refurb_auto_pipenv'))
    \ && ale#python#PipenvPresent(a:buffer)
        return 'pipenv'
    endif

    return ale#python#FindExecutable(a:buffer, 'python_refurb', ['refurb'])
endfunction

" The directory to change to before running refurb
function! s:GetDir(buffer) abort
    let l:project_root = ale#python#FindProjectRoot(a:buffer)

    return !empty(l:project_root)
    \   ? l:project_root
    \   : expand('#' . a:buffer . ':p:h')
endfunction

function! ale_linters#python#refurb#GetCommand(buffer) abort
    let l:dir = s:GetDir(a:buffer)
    let l:executable = ale_linters#python#refurb#GetExecutable(a:buffer)

    return ale#path#CdString(l:dir) . ale#Escape(l:executable) . ' ' . expand('%:p')
endfunction

function! ale_linters#python#refurb#Handle(buffer, lines) abort
    let l:dir = s:GetDir(a:buffer)
    " Look for lines like the following:
    "
    " folder/map_pick.py:48:48 [FURB120]: Don't pass an argument if it is the same as the default value

    let l:pattern = '\v^([a-zA-Z]?:?[^:]+):(\d+):?(\d+)? \[(FURB\d+)\]\: (.+)$'
    let l:output = []

    for l:match in ale#util#GetMatches(a:lines, l:pattern)
        call add(l:output, {
        \   'filename': ale#path#GetAbsPath(l:dir, l:match[1]),
        \   'lnum': l:match[2] + 0,
        \   'col': l:match[3] + 0,
        \   'type': 'W',
        \   'text': l:match[5],
        \})
    endfor

    return l:output
endfunction

call ale#linter#Define('python', {
\   'name': 'refurb',
\   'executable': function('ale_linters#python#refurb#GetExecutable'),
\   'command': function('ale_linters#python#refurb#GetCommand'),
\   'callback': 'ale_linters#python#refurb#Handle',
\   'output_stream': 'both'
\})