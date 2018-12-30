let s:current_search = 0

function! quickpick#pickers#npm#utils#filter(items, searchterm) abort
    let searchterm = tolower(a:searchterm)
    return empty(searchterm) ? a:items : filter(a:items, {index, item-> stridx(tolower(item['label']), searchterm) > -1})
endfunction

function! quickpick#pickers#npm#utils#search(searchterm, callback) abort
    if empty(trim(a:searchterm))
        call a:callback([])
        return
    endif
    " let l:url = printf('https://www.npmjs.com/search/suggestions?q=%s',a:searchterm)
    let l:url = printf('https://registry.npmjs.org/-/v1/search?text=%s&size=20',a:searchterm)
    let ctx = {'buffer': ''}
    call s:exec(['curl', l:url], 1, function('s:on_search_result', [ctx, a:callback]))
endfunction

function! s:on_search_result(ctx, callback, id, data, event) abort
    if a:event == 'stdout'
        let a:ctx['buffer'] = a:ctx['buffer'] . a:data
    elseif a:event == 'exit'
        call a:callback(json_decode(a:ctx['buffer'])['objects'])
    endif
endfunction

" vim8/neovim jobs wrapper {{{
function! s:exec(cmd, str, callback) abort
    if has('nvim')
        return jobstart(a:cmd, {
                \ 'on_stdout': function('s:on_nvim_job_event', [a:str, a:callback]),
                \ 'on_stderr': function('s:on_nvim_job_event', [a:str, a:callback]),
                \ 'on_exit': function('s:on_nvim_job_event', [a:str, a:callback]),
            \ })
    else
        let l:info = { 'close': 0, 'exit': 0, 'exit_code': -1 }
        let l:jobopt = {
            \ 'out_cb': function('s:on_vim_job_event', [l:info, a:str, a:callback, 'stdout']),
            \ 'err_cb': function('s:on_vim_job_event', [l:info, a:str, a:callback, 'stderr']),
            \ 'exit_cb': function('s:on_vim_job_event', [l:info, a:str, a:callback, 'exit']),
            \ 'close_cb': function('s:on_vim_job_close_cb', [l:info, a:str, a:callback]),
        \ }
        if has('patch-8.1.350')
          let l:jobopt['noblock'] = 1
        endif
        let l:job = job_start(a:cmd, l:jobopt)
        let l:channel = job_getchannel(l:job)
        return ch_info(l:channel)['id']
    endif
endfunction

function! s:on_nvim_job_event(str, callback, id, data, event) abort
    if (a:event == 'exit')
        call a:callback(a:id, a:data, a:event)
    elseif a:str
        " convert array to string since neovim uses array split by \n by default
        call a:callback(a:id, join(a:data, "\n"), a:event)
    else
        call a:callback(a:id, a:data, a:event)
    endif
endfunction

function! s:on_vim_job_event(info, str, callback, event, id, data) abort
    if a:event == 'exit'
        let a:info['exit'] = 1
        let a:info['exit_code'] = a:data
        let a:info['id'] = a:id
        if a:info['close'] && a:info['exit']
            " for more info refer to :h job-start
            " job may exit before we read the output and output may be lost.
            " in unix this happens because closing the write end of a pipe
            " causes the read end to get EOF.
            " close and exit has race condition, so wait for both to complete
            call a:callback(a:id, a:data, a:event)
        endif
    elseif a:str
        call a:callback(a:id, a:data, a:event)
    else
        " convert string to array since vim uses string by default
        call a:callback(a:id, split(a:data, "\n", 1), a:event)
    endif
endfunction

function! s:on_vim_job_close_cb(info, str, callback, channel) abort
    let a:info['close'] = 1
    if a:info['close'] && a:info['exit']
        call a:callback(a:info['id'], a:info['exit_code'], 'exit')
    endif
endfunction
" }}}
