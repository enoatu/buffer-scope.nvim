" buffer-scope.nvim の初期化スクリプト
if exists('g:loaded_buffer_scope')
  finish
endif
let g:loaded_buffer_scope = 1

" Telescope コマンドの定義
command! -nargs=* -complete=customlist,v:lua.package.loaded.telescope.builtin.complete BufferScope 
  \ lua require('telescope').extensions.buffer_scope.buffers(<f-args>)