local telescope = require("telescope")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local make_entry = require("telescope.make_entry")
local entry_display = require("telescope.pickers.entry_display")
local conf = require("telescope.config").values
local utils = require("telescope.utils")
local Path = require("plenary.path")
local strings = require("plenary.strings")

local M = {}

-- バッファがカレントディレクトリ内にあるかチェック
local function buf_in_cwd(bufname, cwd)
    if bufname == "" then
        return true
    end
    local bufname_path = Path:new(bufname):normalize(cwd)
    return bufname_path:sub(1, #cwd) == cwd
end

function M.buffers(opts)
    opts = opts or {}

    local bufnrs = vim.tbl_filter(function(bufnr)
        if 1 ~= vim.fn.buflisted(bufnr) then
            return false
        end
        -- only hide unloaded buffers if opts.show_all_buffers is false, keep them listed if true or nil
        if opts.show_all_buffers == false and not vim.api.nvim_buf_is_loaded(bufnr) then
            return false
        end
        if opts.ignore_current_buffer and bufnr == vim.api.nvim_get_current_buf() then
            return false
        end

        local bufname = vim.api.nvim_buf_get_name(bufnr)

        if opts.cwd_only and not buf_in_cwd(bufname, vim.fn.getcwd()) then
            return false
        end
        if not opts.cwd_only and opts.cwd and not buf_in_cwd(bufname, opts.cwd) then
            return false
        end
        return true
    end, vim.api.nvim_list_bufs())

    if not next(bufnrs) then
        utils.notify("builtin.buffers", { msg = "No buffers found with the provided options", level = "INFO" })
        return
    end

    if opts.sort_mru then
        table.sort(bufnrs, function(a, b)
            return vim.fn.getbufinfo(a)[1].lastused > vim.fn.getbufinfo(b)[1].lastused
        end)
    end

    if type(opts.sort_buffers) == "function" then
        table.sort(bufnrs, opts.sort_buffers)
    end

    local buffers = {}
    local default_selection_idx = 1
    for i, bufnr in ipairs(bufnrs) do
        local flag = bufnr == vim.fn.bufnr("") and "%" or (bufnr == vim.fn.bufnr("#") and "#" or " ")

        if opts.sort_lastused and not opts.ignore_current_buffer and flag == "#" then
            default_selection_idx = 2
        end

        local element = {
            bufnr = bufnr,
            flag = flag,
            info = vim.fn.getbufinfo(bufnr)[1],
        }

        if opts.sort_lastused and (flag == "#" or flag == "%") then
            local idx = ((buffers[1] ~= nil and buffers[1].flag == "%") and 2 or 1)
            table.insert(buffers, idx, element)
        else
            if opts.select_current and flag == "%" then
                default_selection_idx = i
            end
            table.insert(buffers, element)
        end
    end

    if not opts.bufnr_width then
        local max_bufnr = math.max(unpack(bufnrs))
        opts.bufnr_width = #tostring(max_bufnr)
    end

    pickers
        .new(opts, {
            prompt_title = "Buffers",
            finder = finders.new_table({
                results = buffers,
                entry_maker = opts.entry_maker or M.gen_from_buffer(opts),
            }),
            previewer = conf.grep_previewer(opts),
            sorter = conf.generic_sorter(opts),
            default_selection_index = default_selection_idx,
            attach_mappings = function(_, map)
                map({ "i", "n" }, "<M-d>", actions.delete_buffer)
                return true
            end,
        })
        :find()
end

function M.gen_from_buffer(opts)
    opts = opts or {}

    local disable_devicons = opts.disable_devicons

    local icon_width = 0
    if not disable_devicons then
        local icon, _ = utils.get_devicons("fname", disable_devicons)
        icon_width = strings.strdisplaywidth(icon)
    end

    local displayer = entry_display.create({
        separator = " ",
        items = {
            { width = opts.bufnr_width },
            { width = 4 },
            { width = icon_width },
            { remaining = true },
        },
    })

    local cwd = utils.path_expand(opts.cwd or vim.fn.getcwd())

    local make_display = function(entry)
        -- bufnr_width + modes + icon + 3 spaces
        opts.__prefix = opts.bufnr_width + 4 + icon_width + 3
        local display_bufname, path_style = utils.transform_path(opts, entry.filename)
        local icon, hl_group = utils.get_devicons(entry.filename, disable_devicons)
        -- /ごとに色を変える
        -- 色は文字で一意に決まる
        local hl_params = {}
        local start_pos = 0
        for i, dir in ipairs(vim.split(display_bufname, "/")) do
            local color = M.GenerateRandomColor(dir)
            -- 色作成
            vim.cmd(
                'execute "hi def buffer_scope_' .. dir .. " ctermfg=168 ctermbg=16 guifg=" .. color .. ' guibg=NONE"'
            )
            -- ハイライト追加
            local end_pos = start_pos + #dir

            table.insert(hl_params, { { start_pos, end_pos }, "buffer_scope_" .. dir })
            start_pos = end_pos + 1
        end

        -- git の差分行数を表示する
        local git_diff_add = 0
        local git_diff_del = 0
        
        -- gitリポジトリかチェック
        local is_git_repo = vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null"):match("true")
        
        if is_git_repo and entry.path then
            local git_diff = vim.fn.system("git diff --numstat -- " .. vim.fn.shellescape(entry.path) .. " 2>/dev/null")
            if git_diff and git_diff ~= "" then
                local git_diff_lines = vim.split(git_diff, "\n")
                for i, line in ipairs(git_diff_lines) do
                    local diff = vim.split(line, "\t")
                    if #diff == 3 then
                        git_diff_add = git_diff_add + (tonumber(diff[1]) or 0)
                        git_diff_del = git_diff_del + (tonumber(diff[2]) or 0)
                    end
                end
            end
        end

        return displayer({
            { entry.bufnr, "TelescopeResultsNumber" },
            { entry.indicator, "TelescopeResultsComment" },
            { icon, hl_group },
            {
                display_bufname,
                function()
                    return hl_params
                end,
            },
            {
                " +" .. git_diff_add .. " -" .. git_diff_del,
                "TelescopeResultsComment",
            },
        })
    end

    return function(entry)
        local filename = entry.info.name ~= "" and entry.info.name or nil
        local bufname = filename and Path:new(filename):normalize(cwd) or "[No Name]"

        local hidden = entry.info.hidden == 1 and "h" or "a"
        local readonly = vim.api.nvim_buf_get_option(entry.bufnr, "readonly") and "=" or " "
        local changed = entry.info.changed == 1 and "+" or " "
        local indicator = entry.flag .. hidden .. readonly .. changed
        local lnum = 1

        -- account for potentially stale lnum as getbufinfo might not be updated or from resuming buffers picker
        if entry.info.lnum ~= 0 then
            -- but make sure the buffer is loaded, otherwise line_count is 0
            if vim.api.nvim_buf_is_loaded(entry.bufnr) then
                local line_count = vim.api.nvim_buf_line_count(entry.bufnr)
                lnum = math.max(math.min(entry.info.lnum, line_count), 1)
            else
                lnum = entry.info.lnum
            end
        end

        return make_entry.set_default_entry_mt({
            value = bufname,
            ordinal = entry.bufnr .. " : " .. bufname,
            display = make_display,
            bufnr = entry.bufnr,
            path = filename,
            filename = bufname,
            lnum = lnum,
            indicator = indicator,
        }, opts)
    end
end

function M.GenerateHexColor(seed)
    local hex = "789ABCDE"
    local color = ""
    local number = seed
    for i = 1, 6 do
        color = color .. string.sub(hex, number % 8 + 1, number % 8 + 1)
        number = math.floor(number / 16)
    end
    return color
end

function M.GenerateSeedIDFromString(name)
    local id = vim.fn.sha256(name)
    local numbers = {}
    for char in string.gmatch(id, ".") do
        if char >= "0" and char <= "9" then
            table.insert(numbers, char)
        end
    end
    return table.concat(numbers):sub(1, 9)
end

function M.GenerateRandomColor(name)
    local seed = M.GenerateSeedIDFromString(name)
    return "#" .. M.GenerateHexColor(seed)
end

return telescope.register_extension({
    exports = {
        buffers = M.buffers,
    },
})
