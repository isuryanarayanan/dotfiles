return {
  {
    "milanglacier/minuet-ai.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("minuet").setup({
        provider = "claude",
        provider_options = {
          claude = {
            model = "claude-sonnet-4-6",
            max_tokens = 512,
            system = require("minuet.config").default_system,
          },
        },
        -- Throttle requests to avoid burning tokens on every keystroke
        throttle = 1500,
        debounce = 450,
        n_completions = 3,
        notify = "warn",
      })
    end,
  },

  -- Wire minuet into blink.cmp
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = { "milanglacier/minuet-ai.nvim" },
    opts = {
      sources = {
        default = { "minuet" },
        providers = {
          minuet = {
            name = "minuet",
            module = "minuet.blink",
            async = true,
            timeout_ms = 3000,
            score_offset = 50,
          },
        },
      },
      completion = {
        trigger = { prefetch_on_insert = false },
      },
    },
  },
}
