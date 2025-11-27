return {
  "nvim-telescope/telescope.nvim",
  opts = {
    defaults = {
      file_ignore_patterns = {
        "node_modules",
        ".git/",
      },
    },
    pickers = {
      find_files = {
        hidden = true,
        -- Also search files ignored by .gitignore
        no_ignore = false,
        -- Show dotfiles
        find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
      },
    },
  },
}
