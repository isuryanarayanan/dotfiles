return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      markdown = { "prettier" },
    },
    formatters = {
      prettier = {
        -- Prettier 3.x silently skips gitignored files when invoked
        -- via stdin. Disable its ignore-path so it formats regardless.
        prepend_args = { "--ignore-path", "" },
      },
    },
  },
}
