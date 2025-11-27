return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    -- Remove time from lualine_z (bottom right)
    opts.sections = opts.sections or {}
    opts.sections.lualine_z = {}
    return opts
  end,
}
