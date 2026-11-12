{ certificatePath }:
final: prev:

let
  mkJdkWithCertificates = import ./jdk-with-certificates.nix {
    pkgs = prev;
    inherit certificatePath;
  };
in
{
  inherit mkJdkWithCertificates;
  jdk21WithExtraCertificates = mkJdkWithCertificates prev.jdk21;
  jdk25WithExtraCertificates = mkJdkWithCertificates prev.jdk25;
}
