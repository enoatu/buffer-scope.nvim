# 🔭 buffer-scope.nvim

> **Dramatically boost your development efficiency with smart buffer management**

Tired of hunting for buffers in Neovim? Ever got lost juggling multiple projects at once?

`buffer-scope.nvim` is a revolutionary Telescope extension that transforms your development workflow.

## ✨ Features

### 🎯 **Real-time Sorting**
Switch sorting methods instantly with a single `Ctrl+s`:
- **📊 Frequency** - Prioritize recently used files
- **🔤 A-Z** - Alphabetical organization
- **🔽 Z-A** - Reverse alphabetical browsing

### 🎨 **Visual Experience**
- Different colors for each directory
- Buffer states at a glance
- Beautiful color highlighting

### ⚡ **Stress-free**
- Switch sorting without closing the picker
- Lightning-fast and responsive
- Intuitive key mappings

## 🚀 Installation

### lazy.nvim
```lua
{
  "yourusername/buffer-scope.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim"
  },
  config = function()
    require("buffer-scope").setup()
  end
}
```

### packer.nvim
```lua
use {
  "yourusername/buffer-scope.nvim",
  requires = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim"
  },
  config = function()
    require("buffer-scope").setup()
  end
}
```

## 🎮 Usage

### Basic Command
```vim
:Telescope buffer_scope buffers
```

### Sort Options
```vim
" Frequency order (default)
:Telescope buffer_scope buffers sort_by=frequency

" Alphabetical ascending
:Telescope buffer_scope buffers sort_by=alphabetical_asc

" Alphabetical descending
:Telescope buffer_scope buffers sort_by=alphabetical_desc
```

### Key Mappings
| Key | Function |
|-----|----------|
| `Ctrl+s` | Cycle through sorting methods |
| `Alt+d` | Delete buffer |

## ⚙️ Configuration

```lua
require("buffer-scope").setup({
  telescope = {
    buffers = {
      sort_mru = true,                -- Sort by most recently used
      show_all_buffers = true,        -- Show all buffers
      ignore_current_buffer = false,  -- Ignore current buffer
      cwd_only = false,               -- Show only current directory
      disable_devicons = false,       -- Disable devicons
    },
  },
})
```

## 🎯 Why buffer-scope.nvim?

### Before (Traditional Buffer Management)
```
😵 Chaotic buffer lists
😫 Time-consuming file searches
😤 Getting lost in multiple projects
```

### After (buffer-scope.nvim)
```
😊 Instant sort switching
⚡ Quick access to target files
🎯 Organized workflow
```

## 🔧 For Developers

### Buffer Status Indicators
- `%` - Current buffer
- `#` - Previous buffer
- `h` - Hidden buffer
- `+` - Modified
- `=` - Read-only

## 🤝 Contributing

Pull requests and issues are welcome! Let's build better tools together.

## 📄 License

MIT License

---

<div align="center">

**⭐ If you like it, please give us a star! ⭐**

[Bug Reports](issues) • [Feature Requests](issues) • [Contributing](CONTRIBUTING.md)

</div>
