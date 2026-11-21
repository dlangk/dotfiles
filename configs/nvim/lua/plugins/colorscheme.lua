return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  opts = {
    flavour = "mocha",
    transparent_background = false,
    -- Kognic (relaxed): matches configs/ghostty/themes/kognic and the starship 'kognic' palette
    color_overrides = {
      mocha = {
        rosewater = "#f7c6bb",
        flamingo = "#f7a896",
        pink = "#d8d2f7",
        mauve = "#a99cf5",
        red = "#f2937e",
        maroon = "#f7a896",
        peach = "#f7a896",
        yellow = "#f0cf8e",
        green = "#8ed98a",
        teal = "#8fd3ec",
        sky = "#8fd3ec",
        sapphire = "#aedff0",
        blue = "#a99cf5",
        lavender = "#bdb3f7",
        text = "#cfd2e6",
        subtext1 = "#c0c4da",
        subtext0 = "#b0b4cc",
        overlay2 = "#9c9cb8",
        overlay1 = "#8484a2",
        overlay0 = "#6c6c8c",
        surface2 = "#4b4b6b",
        surface1 = "#34306a",
        surface0 = "#252246",
        base = "#17172c",
        mantle = "#131326",
        crust = "#0f0f20",
      },
    },
    integrations = {
      cmp = true,
      gitsigns = true,
      nvimtree = true,
      telescope = true,
      treesitter = true,
      mason = true,
    },
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin")
  end,
}
