{ pkgs ? import <nixpkgs> {} }:

let
  python = pkgs.python313;
in
pkgs.mkShell {
  buildInputs = [
    # Terraform 1.5.7
    (pkgs.mkTerraform {
      version = "1.5.7";
      hash = "sha256-pIhwJfa71/gW7lw/KRFBO4Q5Z5YMcTt3r9kD25k8cqM=";
      vendorHash = "sha256-lQgWNMBf+ioNxzAV7tnTQSIS840XdI9fg9duuwoK+U4=";
    })

    # Python 3.13 and tools
    python
    pkgs.poetry
    python.pkgs.black
  ];

  shellHook = ''
    export POETRY_VIRTUALENVS_CREATE=false
  '';
}
