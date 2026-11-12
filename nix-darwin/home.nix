{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  jdkWithCertificates = pkgs.mkJdkWithCertificates or (jdk: jdk);
  jdk25 = jdkWithCertificates pkgs.jdk25;

  dockerStuff = with pkgs; [
    docker_29
    docker-compose
    aws-iam-authenticator
    amazon-ecr-credential-helper
    docker-credential-helpers
  ];

  scalaStuff = [
    jdk25
    (pkgs.sbt.override { jre = jdk25; })
    (pkgs.coursier.override { jre = jdk25; })
    pkgs.async-profiler
  ];

  haskellStuff = with pkgs; [
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

  nvimNightly = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;

  cliStuff = with pkgs; [
    jq
    fzf
    ripgrep
    fd
    git
    delta
    awscli2
    tmux
    unzip
    pigz # multicore gz
    curl
    starship
    coreutils
    zlib
    pkg-config
    btop
    macmon
    universal-ctags
    # aerc
    opentofu
    tflint
    proximity-sort
    tree
  ];

  lspStuff = with pkgs; [
    bash-language-server
    shellcheck
    nil
    nixfmt
    terraform-ls
    basedpyright
    ruff
    lua-language-server
    ltex-ls-plus
  ];

  rustPkgs = pkgs.extend inputs.rust-overlay.overlays.default;

  rustToolchain = rustPkgs.rust-bin.stable."1.93.0".default.override {
    extensions = [
      "rust-analyzer"
      "rust-src"
      "clippy"
      "rustfmt"
      "llvm-tools-preview"
    ];
  };
  rustStuff = [
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

  llmStuff = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
    ccusage
    agentop
  ];

  fastPkgs = inputs.nixpkgs-fast.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  # Upstream mactop 2.0.5 currently fails tests in the Nix sandbox by writing under $HOME.
  mactopNoTests = fastPkgs.mactop.overrideAttrs (_: {
    doCheck = false;
  });
  fastMovingStuff = with fastPkgs; [
    colima
    mactopNoTests
    gh
    ghorg
  ];
in
{
  home.stateVersion = "25.05";

  home.packages = [
    nvimNightly
  ]
  ++ dockerStuff
  ++ scalaStuff
  ++ haskellStuff
  ++ cliStuff
  ++ fastMovingStuff
  ++ lspStuff
  ++ rustStuff
  ++ llmStuff;

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
