{ certificatePath }:
final: prev: {
  mkJdkWithCertificates = import ./jdk-with-certificates.nix {
    pkgs = prev;
    inherit certificatePath;
  };
}
