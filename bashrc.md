# Bashrc

My `.bashrc` contains: 
* bash configuration (prompt, history, some env variables, etc)
* general purpose safe aliases (override standard bash commands with a safer version to ask for confirmation before eg deleting a file) 
* export `PATH` variable (with `if` conditions that should make it quite portable to different machines with different settings) 
* load some tools, if available (ie, git autocompletion) 

Some sections (eg, latex, npm etc) require some cleanup

## Instructions to use

Tool-specific instructions are always wrapped into `if` statements, so that this bashrc should load correctly also on machines where the corresponding tools are not available. 

However, in the happiest path, this `.bashrc` provides support for the following tools (that needs to be installed independently)
* bash git autocompletion, which needs to be cloned in $HOME (see instructions in the corresponding `.bashrc` section) 
* fzf (which is installed by nix-darwing separately, or can be installed independently) 
* support for starship (which is installed by nix-darwind separately, and the config is provided via `stow`) 


## Naive "profiling"

It's of key importance to have 
* smooth startup of a new bash session 
* fast prompt response time 

We can do some naive "profiling" by using the `date` command, or `gdate` on MAC OS X (`gdate` is available by installing `brew install coreutils` using homebrew).

Update `.bashrc` to read
```
STARTTIME=$(gdate +%s%N | cut -b1-13)

....

ENDTIME=$(gdate +%s%N | cut -b1-13)
echo "$(($ENDTIME - $STARTTIME))"
```

You can also add an early return in `.bashrc` to exit the bash config file at a early stage and measure the impact of various configurations on the startup time
```
return 1
```
