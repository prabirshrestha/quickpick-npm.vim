function! quickpick#pickers#npm#search_packages#show(...) abort
    let id = quickpick#create({
        \ 'on_change': function('s:on_change'),
        \ 'on_accept': function('s:on_accept'),
        \ 'on_close': function('s:on_close'),
        \ 'items': ['express', 'react', 'react-dom', 'jest', 'typescript', 'webpack'],
        \ })
    call quickpick#show(id)
endfunction

function! s:on_change(id, action, searchterm) abort
    let s:current_picker_id = a:id
    call quickpick#set_busy(a:id, 1)
    if exists('s:search_timer')
        call timer_stop(s:search_timer)
        unlet s:search_timer
    endif
    let s:search_timer = timer_start(250, function('s:on_search', [a:id, a:searchterm]))
endfunction

function! s:on_search(id, searchterm, ...) abort
    call quickpick#pickers#npm#utils#search(a:searchterm, function('s:on_search_result', [a:id]))
endfunction

function! s:on_search_result(id, result) abort
    if s:current_picker_id == a:id
        let items = map(a:result, 'v:val["package"]["name"] . "@" . v:val["package"]["version"]')
        call quickpick#set_items(a:id, items)
        call quickpick#set_busy(a:id, 0)
    endif
endfunction

function! s:on_accept(id, action, data) abort
    call quickpick#close(a:id)
    echom 'Not implemented'
endfunction

function! s:on_close(id, action, data) abort
    let s:current_picker_id = -1
endfunction
