# neovim

I've been using vim for more than twenty years, I love vim, and over this time my preferences have gradually evolved towards a **minimalistic** approach to vim:
* be sensible about which default edcitor or plugin's settings to override
* minimise the number of bespoke key mappings
* minimise the usage of external plugins

Among the practical advantages of this approach:
* **more robust and portable** setup: vim skills can seemlessly be ported to a different vim installation if/when needed (other workstations, remote servers, etc), i can switch to "factory" settings `vim -u NONE` without encountering too much friction, and other people can use my editor during remote or onsite pairing sessions
* **decreased maintenance burden**: less time spent in looking for plugins, keeping them up-to-date, less sensitivity to older plugins becoming unsupported
* The limited number of plugins ensures also a fast experience: **responsiveness** of the editor is of key importance to me
* **Less cognitive overhead**

Certain default key mappings (eg, C-W for window operations) are arguably not very confortable, but it's just matter of time and practice to become more used to them.

The advent of language server protocol (LSPs) servers has slightly changed the above when I use vim for coding tasks that would benefit from "intellisense".

I personally don't like these huge IDEs that do too many things at once (eg, git integration and debugging and running test and building and inspecting and maybe preparing the coffee ;) )
I tend to use command-line tools for git and build systems and personally I'm more productive that way.
However, "intellisense"-like features are a must when programming, for features like:
* smart renaming (not find-and-replace-ish renaming)
* sematic go to definition/find references (not syntactically ctags-based, in case of duplicated definitions and/or particularly when exploring third party libraries; although tree sitter grammars can help here)
* fast inline feedback loop from linters/compilers and
* assisted refactoring
* automatic imports
* exploration / signatures from third-party dependencies, etc
* features like autocomplete for exhaustive pattern matching
* surface compiler diagnostics

For this reason, I've migrated from vim to neovim, which has built-in support for LSP.

Beyond built-in LSP support, neovim is really having a wave of interesting developments. For instance, the upcoming neovim 0.12 comes with built-in package manager, that i'm already using. This means I don't have to worry about installing a package manager.

I don't let neovim manage my LSP servers: I manage them through nix, and in the setup of neovim I just assume those are available outside.

Other plugins that I use include: fzf (for fuzzy search), cmp (for autocompletion), and occasionally I use lua snippets. I don't care about git integration in the editor, or fancy UI, or ways to browse the codebase: fzf is my way to browse files based on search. For git blame, i vibe coded a lua function that provides exactly the bespoke minimal experience I'm looking for, and nothing else.
