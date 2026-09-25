return {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_dir = function(bufnr, on_dir)
    local crate = vim.fs.root(bufnr, "Cargo.toml")
    if not crate or vim.fn.executable("cargo") == 0 then
      on_dir(crate or vim.fs.root(bufnr, { "rust-project.json", ".git" }))
      return
    end

    -- Cargo knows workspace membership, including explicit package.workspace paths.
    vim.system({ "cargo", "locate-project", "--workspace", "--message-format", "plain" },
      { cwd = crate, text = true, timeout = 2000 }, vim.schedule_wrap(function(result)
        local manifest = vim.trim(result.stdout or "")
        local root = result.code == 0 and manifest ~= "" and vim.fs.dirname(manifest) or crate
        on_dir(root)
      end))
  end,
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        features = "all",
      },

      check = {
        command = "clippy",
      },

      imports = {
        group = {
          enable = false,
        },
      },

      completion = {
        postfix = {
          enable = false,
        },
      },
    },
  },
}
