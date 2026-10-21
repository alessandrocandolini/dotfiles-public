{ pkgs, lib, ... }:

let
  fetchGitHubTarball =
    { owner, repo, rev }:
    builtins.fetchTarball {
      url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
    };

  # Keep the legacy setup aligned with nix-darwin/flake.lock for fast-moving inputs.
  pinnedSources = {
    nixpkgsDarwin = fetchGitHubTarball {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "c4e5bcc625bd88ba8ea792fa6616ab914fe990d0";
    };
    nixpkgsFast = fetchGitHubTarball {
      owner = "NixOS";
      repo = "nixpkgs";
      rev = "02c087f3fe673c9e317f206a627cb6b910336dbe";
    };
    neovimNightlyOverlay = fetchGitHubTarball {
      owner = "nix-community";
      repo = "neovim-nightly-overlay";
      rev = "6f951085a923e0c6e2c0c9257e0fd5ab732bd233";
    };
    rustOverlay = fetchGitHubTarball {
      owner = "oxalica";
      repo = "rust-overlay";
      rev = "5424e1e6dda30b0626935d2a03a6526db4858d60";
    };
    llmAgents = fetchGitHubTarball {
      owner = "numtide";
      repo = "llm-agents.nix";
      rev = "9d41351cd41c70c69f9a4ba635d95d5921ceed33";
    };
    agentop = fetchGitHubTarball {
      owner = "leboiko";
      repo = "claude-codex-pid-inspector";
      rev = "93fea49ff7101ec99bb192136a505eaf371128f3";
    };
  };

  unstablePkgs =
    import
      pinnedSources.nixpkgsFast
      {
        system = pkgs.system;
        config = pkgs.config; # keep unfree / allowBroken etc consistent
      };
  neovimPkgs =
    import
      pinnedSources.nixpkgsDarwin
      {
        system = pkgs.system;
        config = pkgs.config; # keep unfree / allowBroken etc consistent
        overlays = [
          (import pinnedSources.neovimNightlyOverlay)
          (_final: prev: {
            neovim = prev.neovim.overrideAttrs (_: {
              doCheck = false;
            });
            neovim-unwrapped = prev.neovim-unwrapped.overrideAttrs (_: {
              doCheck = false;
            });
          })
        ];
      };

  dockerStuff = with unstablePkgs; [
    colima
    docker_29
    docker-compose
    aws-iam-authenticator
    amazon-ecr-credential-helper
    docker-credential-helpers
  ];

  scalaStuff = with unstablePkgs; [
    jdk21
    (sbt.override { jre = pkgs.jdk21; })
    coursier # for metals
    async-profiler
  ];

  vimStuff = with unstablePkgs; [
    neovimPkgs.neovim
    proximity-sort
  ];

  lspStuff = with unstablePkgs; [
    bash-language-server
    shellcheck
    nil
    nixfmt
    terraform-ls
    basedpyright
    ruff
    lua-language-server
  ];

  rustOverlay = import pinnedSources.rustOverlay;

  rustPkgs = unstablePkgs.extend rustOverlay;

  rustToolchain = rustPkgs.rust-bin.stable."1.93.0".default.override {
    extensions = [
      "rust-analyzer"
      "rust-src"
      "clippy"
      "rustfmt"
    ];
  };

  rustStuff = [
    rustToolchain
    unstablePkgs.cargo-generate
    unstablePkgs.cargo-expand
  ];

  flakeCompat = builtins.fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/master.tar.gz";
  };

  llmAgentsFlake =
    (import flakeCompat {
      src = pinnedSources.llmAgents;
    }).defaultNix;

  # pick the right system key
  llmAgentsPkgs = llmAgentsFlake.packages.${pkgs.system};

  agentop = rustPkgs.rustPlatform.buildRustPackage {
    pname = "agentop";
    version = "unstable";
    src = pinnedSources.agentop;
    cargoLock.lockFile = pinnedSources.agentop + "/Cargo.lock";
    cargoTestFlags = [ "--lib" "--bins" ];
  };

  llmStuff = with llmAgentsPkgs; [
    claude-code
    ccusage
    agentop
  ];
in
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    with unstablePkgs;
    vimStuff
    ++ scalaStuff
    ++ dockerStuff
    ++ lspStuff
    ++ rustStuff
    ++ llmStuff
    ++ [
      jq
      fzf
      ripgrep
      git
      gh
      delta
      awscli2
      #     (gradle.override { java = pkgs.jdk17; })
      tmux
      unzip
      curl
      # nodejs_latest
      starship
      #     texlab
      #     apacheHttpd
      #     postgresql
      coreutils
      pigz
      fd
      zlib
      pkg-config
      # llama-cpp
      btop
      macmon
      universal-ctags
    ];

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  nix.package = pkgs.nix;

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 60d";
  };

  # Add extra cache for LLM artifacts
  nix.settings.extra-substituters = [ "https://cache.numtide.com" ];
  nix.settings.extra-trusted-public-keys = [
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
  ];
  # Point vim to neovim
  environment.shellAliases = {
    vi = "nvim";
    vim = "nvim";
  };
  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh.enable = false;
  programs.bash.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  environment.variables = {
    JAVA_HOME = "${pkgs.jdk21}/";
    PKG_CONFIG_PATH = "${
      lib.makeSearchPathOutput "dev" "lib/pkgconfig" [ unstablePkgs.zlib ]
    }:\${PKG_CONFIG_PATH}";
    CPATH = "${lib.makeSearchPathOutput "dev" "include" [ unstablePkgs.zlib ]}:\${CPATH}";
    LIBRARY_PATH = "${lib.makeLibraryPath [ unstablePkgs.zlib ]}:\${LIBRARY_PATH}";
  };
}
