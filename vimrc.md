# vim/neovim 

I love vim as a text editor. 

I've been using vim for approximately twenty years, and over this time my preferences have gradually evolved towards a minimalistic approach to vim:
* be sensible about which default settings to override
* minimise the number of new custom key mappings
* minimise the usage of external plugins

Among the practical advantages of this approach:
* more robust and portable knowledge of vim: vim skills can seemlessly be ported to a different vim installation if/when needed (other workstations, remote servers, etc), ie, i can switch to "factory" mode `vim -u NONE` without encountering too much friction. 
* save time looking around for plugins and at the same that be less sensitive to older plugins becoming unsupported

Certain default key mappings (eg, C-W for window operations) are indeed not very confortable, but it's just matter of time and practice to become more used to them. 

The advent of language server protocol (LSPs) servers has slightly changed the above when I use vim for coding tasks that would benefit from "intellisense". 

I personally don't like these huge IDEs that do too many things (ie, git integration and debugging and running test and building and inspecting and maybe preparing the coffee ;) )
I tend to use command-line tools for git and build systems and personally I'm more productive that way. 
However, "intellisense"-like features are a must when programming, for features like:
* smart renaming (not find-and-replace-ish renaming)
* go to definition (not tags based, in case of duplicated definitions and/or particularly when exploring third party libraries) 
* fast inline feedback loop from linters/compilers and  
* assisted refactoring 
* automatic imports 
* etc

To bring LSP to vim, I use indeed plugins and new custom key mapping. As plugin, I currently rely on CoC (although i keep an eye on the neovim built-in LSP). 
Unfortunately, this makes the vim configuration less self-contained (LSP servers need to be installed in the system independently).

Few other plugins that i use: [vim-surrond](https://github.com/tpope/vim-surround) and [fzf.vim](https://github.com/junegunn/fzf.vim) (the latter requires fzf independently installed in the system).

I don't like the fact that, for the LSP part, my vim configuration requires coordination with the environment (installing tools, etc): I would probably try to move to nix to manage the dependencies in a more reproducible and trackable way 
