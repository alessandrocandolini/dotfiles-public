{ pkgs }:

let
  fixtures =
    pkgs.runCommandLocal "java-truststore-synthetic-fixtures"
      {
        nativeBuildInputs = [ pkgs.openssl ];
      }
      ''
        mkdir -p "$out"
        for name in first second; do
          openssl req -x509 -newkey rsa:2048 -nodes -keyout "$name.key" \
            -out "$out/$name.pem" -days 3650 -subj "/CN=Test CA $name" \
            -addext basicConstraints=critical,CA:TRUE
        done
        openssl x509 -in "$out/second.pem" -addtrust anyExtendedKeyUsage \
          -trustout -out "$out/trusted.pem"
        printf '# Synthetic bundle\r\n' > "$out/valid.pem"
        sed 's/$/\r/' "$out/first.pem" >> "$out/valid.pem"
        cat "$out/second.pem" "$out/trusted.pem" >> "$out/valid.pem"
        ln -s valid.pem "$out/symlink.pem"

        printf '# Empty bundle\n' > "$out/empty.pem"
        cat "$out/first.pem" > "$out/truncated.pem"
        sed '/-----END CERTIFICATE-----/d' "$out/second.pem" >> "$out/truncated.pem"
        cat "$out/first.pem" > "$out/invalid.pem"
        printf '%s\n' '-----BEGIN CERTIFICATE-----' 'YWJjZA==' \
          '-----END CERTIFICATE-----' >> "$out/invalid.pem"
        cat "$out/first.pem" > "$out/private-key.pem"
        printf '%s\n' '-----BEGIN PRIVATE KEY-----' 'YWJjZA==' \
          '-----END PRIVATE KEY-----' >> "$out/private-key.pem"
      '';
  mkTruststore =
    name:
    import ../java-truststore.nix {
      inherit pkgs;
      certificatePath = "${fixtures}/${name}.pem";
    };
  valid = mkTruststore "valid";
  repeated = valid.overrideAttrs (_: {
    name = "java-truststore-repeated.p12";
  });
  failures = map (name: pkgs.testers.testBuildFailure' { drv = mkTruststore name; }) [
    "empty"
    "truncated"
    "invalid"
    "private-key"
  ];
in
assert valid.drvPath == (mkTruststore "symlink").drvPath;
assert valid.drvPath != (mkTruststore "first").drvPath;
pkgs.runCommandLocal "java-truststore-tests"
  {
    nativeBuildInputs = [ pkgs.jdk25 ];
    inherit failures;
  }
  ''
    cmp ${valid} ${repeated}
    cat > TruststoreCheck.java <<'JAVA'
    import java.nio.file.*;
    import java.security.KeyStore;
    import java.security.cert.CertificateFactory;
    import java.util.*;
    import javax.net.ssl.*;
    class TruststoreCheck {
        public static void main(String[] args) throws Exception {
            var store = KeyStore.getInstance("PKCS12");
            try (var input = Files.newInputStream(Path.of(args[0]))) {
                store.load(input, null);
            }
            var certificates = CertificateFactory.getInstance("X.509");
            var expected = new HashSet<java.security.cert.Certificate>();
            for (int i = 1; i < args.length; i++) {
                try (var input = Files.newInputStream(Path.of(args[i]))) {
                    expected.add(certificates.generateCertificate(input));
                }
            }
            var factory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
            factory.init(store);
            var manager = (X509TrustManager) factory.getTrustManagers()[0];
            if (store.size() != 3 || !expected.equals(new HashSet<>(Arrays.asList(manager.getAcceptedIssuers()))))
                throw new AssertionError("Unexpected truststore contents");
        }
    }
    JAVA
    java -XX:-UsePerfData TruststoreCheck.java ${valid} ${fixtures}/first.pem ${fixtures}/second.pem
    touch "$out"
  ''
