let s:items  = [
    \   { 'label': 'Add package', 'user_data': 'package:add' },
    \   { 'label': 'Remove package', 'user_data': 'package:remove' },
    \   { 'label': 'Install packages', 'user_data': 'package:install' },
    \ ]

function! quickpick#pickers#npm#show(...) abort
    let id = quickpick#create({
        \   'on_change': function('s:on_change'),
        \   'on_accept': function('s:on_accept'),
        \   'items': s:items,
        \ })
    call quickpick#show(id)
    return id
endfunction

function! s:on_change(id, action, searchterm) abort
    let items = quickpick#pickers#npm#utils#filter(copy(s:items), a:searchterm)
    call quickpick#set_items(a:id, items)
endfunction

function! s:on_accept(id, action, data) abort
    call quickpick#close(a:id)
    let item = a:data['items'][0]
    if item['user_data'] == 'package:add'
        call quickpick#pickers#npm#search_packages#show()
        return
    endif
    echom 'not implemented yet '. json_encode(item)
endfunction
