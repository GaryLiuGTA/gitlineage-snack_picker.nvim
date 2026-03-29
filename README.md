![logo](https://raw.githubusercontent.com/LionyxML/gitlineage.nvim/refs/heads/media/logo.png)

# gitlineage-snack_picker.nvim
This is forked from https://github.com/lionyxml/gitlineage.nvim.
View git history for selected lines in a [Snacks.picker](https://github.com/folke/snacks.nvim) (git-lineage display in a separate tab).

Select a range of lines in visual mode, use the `:GitLineageSnackPicker` command, or
press the keymap in normal mode to see how they evolved through git commits
using `git log -L`.

## How it Works

1. Select a range of lines in visual mode, or just place your cursor on a line.
2. Press `<leader>gh` (customizable), or run `:GitLineageSnackPicker`. A Snacks.picker opens with the git history of the selected lines.
3. Browse commits, preview diffs, filter by message.
4. Press `<C-y>` to yank a commit SHA, or `<C-d>` to open in diffview.nvim.

## Requirements

**Required:**

- Neovim >= 0.7.0
- Git
- [snacks.nvim](https://github.com/folke/snacks.nvim)

**Optional:**

- [diffview.nvim](https://github.com/sindrets/diffview.nvim) - for viewing full commit diffs (`<C-d>` in picker)

## Installation

### lazy.nvim

```lua
{
    "GaryLiuGTA/gitlineage-snack_picker.nvim",
    dependencies = {
        "folke/snacks.nvim",
        "sindrets/diffview.nvim", -- optional, for open_diffview action
    },
    config = function()
        require("gitlineage_snack_picker").setup()
    end
}
```

### mini.deps

```lua
local add = require("mini.deps").add

add("folke/snacks.nvim")
add("sindrets/diffview.nvim") -- optional, for open_diffview action
add("GaryLiuGTA/gitlineage-snack_picker.nvim")

require("gitlineage_snack_picker").setup()
```

## Configuration

```lua
require("gitlineage_snack_picker").setup({
    keymap = "<leader>gh", -- set to nil to disable default keymap
})
```

| Option   | Default      | Description                                                     |
| -------- | ------------ | --------------------------------------------------------------- |
| `keymap` | `<leader>gh` | Normal and visual mode keymap. Set to `nil` to define your own. |

## Usage

### Using the keymap

1. In **normal mode**, press `<leader>gh` to show history for the current line
2. In **visual mode**, select lines and press `<leader>gh` to show history for the selection

### Using the command

- `:GitLineageSnackPicker` -- show history for the current line
- `:'<,'>GitLineage` -- show history for the visual selection
- `:10,20GitLineage` -- show history for an explicit line range

### Picker keymaps

Once the picker is open:

| Key      | Action                                         |
| -------- | ---------------------------------------------- |
| `<C-y>`  | Yank commit SHA to clipboard                   |
| `<C-d>`  | Open full commit diff (requires diffview.nvim)  |

## Health check

```vim
:checkhealth gitlineage_snack_picker
```

## Documentation

```
:h gitlineage_snack_picker
```

## License

MIT

## Similar Plugins

- [mini-git](https://github.com/nvim-mini/mini.nvim/blob/main/readmes/mini-git.md) - `MiniGit.show_range_history()`
- [diffview.nvim](https://github.com/sindrets/diffview.nvim) - `:DiffviewFileHistory`
