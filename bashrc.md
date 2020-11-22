# Bashrc

My `.bashrc` contains: 
* bash configuration (prompt, history, etc)
* general purpose safe aliases (override standard bash commands with a safer version to ask for confirmation before eg deleting a file) 
* export `PATH` variable (with `if` conditions that should make it quite portable to different machines with different settings) 
* load some tools, if available (ie, git autocompletion, git prompt, fzf for fuzzy search) 

Some sections (eg, latex, npm etc) require some cleanup

## Instructions to use

The provided `.bashrc` file should behave correctly if some things (eg, android, latex, java, etc) are not available in a machine. 
In fact, most of the instructions are wrapped into `if` statements to check the availability of the tools/folders/files before running any instruction.
However, in the happiest path, this `.bashrc` provides support for the following tools (that needs to be installed independently)
* automatic set of JAVA_HOME, if java is installed
* Android points to `%HOME/Library/Android`
* bash git autocompletion and git bash prompt should be installed / cloned in $HOME (see instructions in the corresponding `.bashrc` section) 
* fzf 


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
