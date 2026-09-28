return {
  {
    dir = vim.fn.stdpath("config") .. "/local/viki-ide",
    name = "viki-ide",
    lazy = false,
    config = function()
      require("viki-ide").setup({
        auto_start = true,
        suggestion = {
          auto_trigger = true,
          default_keys = true,
        },
      })
    end,
  },
}
