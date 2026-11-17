{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  fast = inputs.nixpkgs-fast.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  cli = with pkgs; [
    jq
    fzf
    ripgrep
    fd
    git
    delta
    awscli2
    unzip
    pigz # multicore gz
    curl
    starship
    coreutils
    zlib
    pkg-config
    universal-ctags
    # aerc
    proximity-sort
    tree
    nerd-fonts.meslo-lg
    eza
    docker_29
    docker-compose
  ];

  fastMovingCli = with fast; [
    colima
    mactop
    gh
    tmux
  ];

  nvim = [ inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  jdkWithCertificates = pkgs.mkJdkWithCertificates or (jdk: jdk);
  jdk25 = jdkWithCertificates pkgs.jdk25;

  scala = [
    jdk25
    (pkgs.sbt.override { jre = jdk25; })
    (fast.metals.override {
      jre = jdk25;
      extraJavaOpts = "-XX:+UseG1GC -XX:+UseStringDeduplication -Xss4m -Xms512m";
    })
    (pkgs.scalafmt.override { jre = jdk25; })
    (pkgs.giter8.override { jre = jdk25; })
    pkgs.async-profiler
  ];

  haskell = with pkgs; [
    haskellPackages.fast-tags
    (haskellPackages.hoogleWithPackages (p: [
      p.adjunctions
      p.aeson
      p.algebraic-graphs
      p.ansi-terminal
      p.array
      p.base
      p.bytestring
      p.comonad
      p.containers
      p.data-fix
      p.distributive
      p.either
      p.envparse
      p.hashable
      p.megaparsec
      p.mtl
      p.optparse-applicative
      p.parser-combinators
      p.recursion-schemes
      p.req
      p.safe
      p.split
      p.tardis
      p.text
      p.unordered-containers
      p.vector
      p.witherable
    ]))
  ];

  lsp = with pkgs; [
    bash-language-server
    shellcheck
    nil
    nixfmt
    basedpyright
    ruff
    lua-language-server
    ltex-ls-plus
  ];

  rustPkgs = pkgs.extend inputs.rust-overlay.overlays.default;

  rustToolchain = rustPkgs.rust-bin.stable."1.100.0".default.override {
    extensions = [
      "rust-analyzer"
      "rust-src"
      "clippy"
      "rustfmt"
      "llvm-tools-preview"
    ];
  };
  rust = [
    rustToolchain
    pkgs.cargo-generate
    pkgs.cargo-expand
  ];

  agentop = rustPkgs.rustPlatform.buildRustPackage {
    pname = "agentop";
    version = "unstable";
    src = inputs.agentop;
    cargoLock.lockFile = inputs.agentop + "/Cargo.lock";
    cargoTestFlags = [
      "--lib"
      "--bins"
    ];
  };

  llm = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
    ccusage
    agentop
  ];

in
{
  home.stateVersion = "25.05";

  home.packages = cli ++ fastMovingCli ++ nvim ++ scala ++ haskell ++ lsp ++ rust ++ llm;

  programs.bash.enable = false;
  programs.starship.enable = true;
  programs.git.enable = true;
  home.file.".git-completion.bash".source =
    "${config.programs.git.package}/share/bash-completion/completions/git";
  home.sessionVariables = {
    JAVA_HOME = "${jdk25}/";
    PKG_CONFIG_PATH = "${
      lib.makeSearchPathOutput "dev" "lib/pkgconfig" [ pkgs.zlib ]
    }:$PKG_CONFIG_PATH";
    CPATH = "${lib.makeSearchPathOutput "dev" "include" [ pkgs.zlib ]}:$CPATH";
    LIBRARY_PATH = "${lib.makeLibraryPath [ pkgs.zlib ]}:$LIBRARY_PATH";
  };
}
