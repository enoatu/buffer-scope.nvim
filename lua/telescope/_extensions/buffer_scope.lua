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

        if opts.cwd_only and not buf_in_cwd(bufname, vim.loop.cwd()) then
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

    local cwd = utils.path_expand(opts.cwd or vim.loop.cwd())

    local make_display = function(entry)
        -- bufnr_width + modes + icon + 3 spaces + : + lnum
        opts.__prefix = opts.bufnr_width + 4 + icon_width + 3 + 1 + #tostring(entry.lnum)
        local display_bufname, path_style = utils.transform_path(opts, entry.filename)
        local icon, hl_group = utils.get_devicons(entry.filename, disable_devicons)

        return displayer({
            { entry.bufnr, "TelescopeResultsNumber" },
            { entry.indicator, "TelescopeResultsComment" },
            { icon, hl_group },
            {
                display_bufname .. ":" .. entry.lnum,
                function()
                    return path_style
                end,
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

return telescope.register_extension({
    exports = {
        buffers = M.buffers,
    },
})
