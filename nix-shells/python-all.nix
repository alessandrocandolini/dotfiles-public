{ pkgs ? import <nixpkgs> {} }:

let
  # Import the Nix standard library
  lib = pkgs.lib;

  # Choose a more recent Python version, such as Python 3.11
  python-version = pkgs.python311;

  # Define the list of packages available in Nixpkgs
  python-with-my-packages = python-version.withPackages (p: with p; [
    msal
    requests
    python-dotenv
    beautifulsoup4
    openai
    jsonschema
    ijson
    tenacity
    tiktoken
    sqlalchemy
    psycopg
    psycopg2
    selenium
    markdownify
    opentelemetry-api
    opentelemetry-sdk
    pandas
    openpyxl
    virtualenv  # Include virtualenv here
    notebook
  ]);

  # List of packages to install via pip
  pipPackages = [
    "azure-functions"
    "load-dotenv==0.1.0"
    "mimetype"
    "json_repair"
    "azure-monitor-opentelemetry==1.6.1"
    "azure-monitor-opentelemetry-exporter==1.0.0b28"
    "opentelemetry-instrumentation-flask==0.47b0"
  ];

  # Concatenate pipPackages into a single string
  pipPackagesString = lib.concatStringsSep " " pipPackages;
in
pkgs.mkShell {
  buildInputs = [
    python-with-my-packages
    pkgs.neovim  # Include other tools if needed
  ];

  shellHook = ''
    # Create a temporary directory for the virtual environment
    export VENV_DIR=$(mktemp -d)
    export PIP_CACHE_DIR="$HOME/.cache/pip"

    # Create the virtual environment with access to Nix-installed packages
    python -m virtualenv --system-site-packages "$VENV_DIR"
    source "$VENV_DIR/bin/activate"

    # Upgrade pip and install missing packages
    pip install --upgrade pip setuptools wheel

    # Install missing packages via pip
    pip install --cache-dir "$PIP_CACHE_DIR" ${pipPackagesString}

    # Cleanup function to remove the virtual environment upon exit
    function cleanup() {
      deactivate
      rm -rf "$VENV_DIR"
    }
    # Ensure the cleanup function runs when the shell exits
    trap cleanup EXIT
  '';
}

