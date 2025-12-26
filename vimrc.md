# neovim 

I love vim as a text editor.

I've been using vim for more than twenty years, and over this time my preferences have gradually evolved towards a **minimalistic** approach to vim:
* be sensible about which default settings to override
* minimise the number of new bespoke key mappings
* minimise the usage of external plugins

Among the practical advantages of this approach:
* **more robust and portable** setup: vim skills can seemlessly be ported to a different vim installation if/when needed (other workstations, remote servers, etc), i can switch to "factory" mode `vim -u NONE` without encountering too much friction, and other people can use my editor during remote or onsite pairing sessions 
* **decreased maintenance burden**: less time spent in looking for plugins, keepign them up-to-date, less sensitivity to older plugins becoming unsupported
* The limited number of plugins ensures also a fast experience: **responsiness** of the editor is of key importance for me
* **Less cognitive load** 

Certain default key mappings (eg, C-W for window operations) are arguably not very confortable in my opinion, but it's just matter of time and practice to become more used to them. 

The advent of language server protocol (LSPs) servers has slightly changed the above when I use vim for coding tasks that would benefit from "intellisense". 

I personally don't like these huge IDEs that do too many things at once (eg, git integration and debugging and running test and building and inspecting and maybe preparing the coffee ;) )
I tend to use command-line tools for git and build systems and personally I'm more productive that way. 
However, "intellisense"-like features are a must when programming, for features like:
* smart renaming (not find-and-replace-ish renaming)
* sematic go to definition (not syntactically ctags-based, in case of duplicated definitions and/or particularly when exploring third party libraries; although tree sitter grammars can help here) 
* fast inline feedback loop from linters/compilers and  
* assisted refactoring 
* automatic imports
* exploration / signatures from third-party dependencies, etc

For this reason, in the last two years I migrated from vim to nvim, which has built-in support for LSP in case I need it. Everything non-lsp related should still work in vim 8, but there was no point for me supporting both, so I switched to nvim.  



I don't like the fact that, for the LSP part, my vim configuration requires coordination with the environment (installing tools, etc): I would probably like to explore moving to nix to manage the dependencies in a more reproducible and trackable way; i use nix a lot and this could be a solution, but it comes with downsides too. 
