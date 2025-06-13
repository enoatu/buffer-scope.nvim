-- buffer-scope.nvim のメインモジュール
local M = {}

-- デフォルト設定
M.config = {
  -- Telescope拡張の設定
  telescope = {
    -- バッファ表示の設定
    buffers = {
      sort_mru = true,                -- 最近使用した順にソート
      show_all_buffers = true,        -- 全バッファを表示
      ignore_current_buffer = false,  -- 現在のバッファを無視
      cwd_only = false,               -- カレントディレクトリのみ表示
      sort_lastused = false,          -- 最後に使用した順にソート
      select_current = false,         -- 現在のバッファを選択
      disable_devicons = false,       -- deviconsを無効化
    },
  },
}

-- setup関数
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)
  
  -- Telescope拡張を遅延読み込み
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      -- Telescopeが読み込まれているか確認
      local ok, telescope = pcall(require, "telescope")
      if ok then
        telescope.load_extension("buffer_scope")
      end
    end,
  })
end

return M