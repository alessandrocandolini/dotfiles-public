{
  description = "Infrastructure development shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" ];
    in
    {
      devShells = nixpkgs.lib.genAttrs systems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.opentofu
              pkgs.tflint
              pkgs.terraform-ls
              (
                (pkgs.mkTerraform {
                  version = "1.5.7";
                  hash = "sha256-pIhwJfa71/gW7lw/KRFBO4Q5Z5YMcTt3r9kD25k8cqM=";
                  vendorHash = "sha256-lQgWNMBf+ioNxzAV7tnTQSIS840XdI9fg9duuwoK+U4=";
                }).overrideAttrs
                  (old: {
                    meta = old.meta // {
                      license = pkgs.lib.licenses.mpl20;
                    };
                  })
              )
              pkgs.poetry
              pkgs.black
            ];

            shellHook = ''
              export POETRY_VIRTUALENVS_CREATE=false
            '';
          };
        }
      );
    };
}
