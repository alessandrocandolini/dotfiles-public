{ pkgs, certificatePath }:

pkgs.runCommandLocal "java-truststore.p12"
  {
    nativeBuildInputs = [ pkgs.openssl ];
    certificateBundle = pkgs.writeText "java-ca-bundle.pem" (builtins.readFile certificatePath);
  }
  ''
    begins=$(grep -Ec '^-----BEGIN (TRUSTED )?CERTIFICATE-----[[:space:]]*$' "$certificateBundle")
    ends=$(grep -Ec '^-----END (TRUSTED )?CERTIFICATE-----[[:space:]]*$' "$certificateBundle")
    test "$begins" -gt 0
    test "$begins" -eq "$ends"
    if grep -Eq '^-----BEGIN .*PRIVATE KEY-----' "$certificateBundle"; then
      echo "The certificate bundle contains a private key" >&2
      exit 1
    fi

    openssl pkcs12 -export -nokeys -jdktrust anyExtendedKeyUsage \
      -certpbe NONE -nomac -passout pass: \
      -in "$certificateBundle" -out "$out"

    openssl pkcs12 -in "$out" -nokeys -passin pass: -out exported.pem
    test "$(grep -c '^-----BEGIN CERTIFICATE-----' exported.pem)" -eq "$begins"
  ''
