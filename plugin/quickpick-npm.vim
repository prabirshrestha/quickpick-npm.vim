if exists('g:quickpick_npm')
    finish
endif
let g:quickpick_npm = 1

command! Pnpm call quickpick#pickers#npm#show()
