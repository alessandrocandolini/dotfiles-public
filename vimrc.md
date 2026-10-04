# neovim

I've been using vim for more than twenty years, I love vim, and over this time my preferences have gradually evolved towards a **minimalistic** approach to vim:
* be sensible about which default editor or plugin's settings to override
* minimise the number of bespoke key mappings
* minimise the usage of external plugins

Among the practical advantages of this approach:
* **more robust and portable** setup: vim skills can seamlessly be ported to a different vim installation if/when needed (other workstations, remote servers, etc), i can switch to "factory" settings `vim -u NONE` without encountering too much friction, and other people can use my editor during remote or onsite pairing sessions
* **decreased maintenance burden**: less time spent in looking for plugins, keeping them up-to-date, less sensitivity to older plugins becoming unsupported
* The limited number of plugins ensures also a fast experience: **responsiveness** of the editor is of key importance to me
* **Less cognitive overhead**

Certain default key mappings (eg, C-W for window operations) are arguably not very comfortable, but it's just matter of time and practice to become more used to them.

The advent of language server protocol (LSPs) servers has slightly changed the above when I use vim for coding tasks that would benefit from "intellisense".

I personally don't like these huge IDEs that do too many things at once (eg, git integration and debugging and running test and building and inspecting and maybe preparing the coffee ;) )
I tend to use command-line tools for git and build systems and personally I'm more productive that way.
However, "intellisense"-like features are a must when programming, for features like:
* smart renaming (not find-and-replace-ish renaming)
* semantic go to definition/find references (not syntactically ctags-based, in case of duplicated definitions and/or particularly when exploring third party libraries; although tree sitter grammars can help here)
* fast inline feedback loop from linters/compilers and
* assisted refactoring
* automatic imports
* exploration / signatures from third-party dependencies, etc
* features like autocomplete for exhaustive pattern matching
* surface compiler diagnostics

For this reason, I've migrated from vim to neovim, which has built-in support for LSP.

Beyond built-in LSP support, neovim is really having a wave of interesting developments. For instance, the upcoming neovim 0.12 comes with a built-in package manager, that i'm already using. This means I don't have to worry about installing a package manager.

I don't let neovim manage my LSP servers: I manage them through nix, and in the setup of neovim I just assume those are available outside.

Other plugins that I use include: fzf (for fuzzy search), cmp (for autocompletion), and occasionally I use lua snippets. I don't care about git integration in the editor, or fancy UI, or ways to browse the codebase: fzf is my way to browse files based on search. For git blame, i vibe coded a lua function that provides exactly the bespoke minimal experience I'm looking for, and nothing else.

## Quick guide

### Grammar and spelling (LaTeX and Markdown)

LaTeX (`tex`), plain TeX (`plaintex`), and Markdown (`markdown`) use
[LTeX+](https://github.com/ltex-plus/ltex-ls-plus) for local grammar and spelling
diagnostics in British English (`en-GB`). Built-in spelling is disabled for these filetypes.

Both Nix setups include `ltex-ls-plus`. After rebuilding your active Nix setup, run
`make nvim` to link the config and restart Neovim. The server starts automatically
for TeX and Markdown files when `ltex-ls-plus` is on `PATH`, including files outside Git projects.

| Key | Action |
| --- | --- |
| `]c` / `[c` | Next / previous diagnostic, with an explanation. |
| `<leader>a` | Code actions, including suggested spelling and grammar corrections. |
| `<leader>dl` | List diagnostics for the current buffer. |
| `<leader>ls` | List attached servers; look for `ltex_plus`. |

The default leader is `\`. Language and parser settings live in
[`lsp/ltex_plus.lua`](nvim/.config/nvim/lsp/ltex_plus.lua). Asymptote paths and
`dmath` environments are excluded from checking. The existing TeX syntax extension
still handles their visual highlighting; LTeX+ has its own parser.

The English comma-spacing rule (`COMMA_PARENTHESIS_WHITESPACE`) is disabled:
removing an ignored `dmath` equation makes LTeX+ see whitespace before its trailing
comma and underline the whole equation. This also suppresses genuine comma-spacing
warnings in both LaTeX and Markdown. Other grammar and spelling checks remain enabled.

`zg` only teaches Neovim's built-in spell checker. LTeX+ uses its own
`settings.ltex.dictionary` (keyed by language, e.g. `["en-GB"] = { "Asymptote" }`).
Dictionary and rule-management code actions require additional client support;
use the settings file for these customisations.

### Built-in spell checking (plain text)

Plain-text buffers (`filetype=text`, normally `.txt` files) automatically use
Neovim's built-in British English spelling (`en_gb`). For a buffer with no detected
filetype, use `:setfiletype text` to opt in. No external tool is needed.

Use `:setlocal nospell` to temporarily disable it, or
`:setlocal spell spelllang=en_gb` to enable it manually in another buffer. The
automatic setting is reapplied when entering a buffer or changing its filetype,
so spelling highlights do not carry over into code, LaTeX, or Markdown.
Built-in spelling uses highlights and spelling commands, not LSP diagnostics.

Use these keys in normal mode:

| Key | Action |
| --- | --- |
| `]s` | Jump to the next spelling mistake. |
| `[s` | Jump to the previous spelling mistake. |
| `z=` | Show spelling suggestions for the word under the cursor. |
| `zg` | Accept the word under the cursor and save it in your personal dictionary. |
| `zug` | Undo accepting a word with `zg`. |

These shortcuts apply only to built-in spelling; use the diagnostic shortcuts
above for LTeX+. Use `:help spell` for the full reference.

## Managing plugin versions

From the repo root, run `make nvim-update` to generate a lockfile change without changing installed plugins, then review, test, and commit it. CI can use the same command.
After pulling changes (or first running `make nvim`), run `make nvim-sync` to apply the locked revisions and wait for build hooks. It preserves the lockfile and fails on errors; fix the cause and rerun to retry builds.
Both require Neovim and Git; sync also needs Stack for Cornelis. Restart Neovim afterward; normal startup only loads prepared plugins.
