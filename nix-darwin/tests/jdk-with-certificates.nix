{ pkgs }:

let
  fixtures =
    pkgs.runCommandLocal "java-truststore-synthetic-fixtures" { nativeBuildInputs = [ pkgs.openssl ]; }
      ''
        mkdir -p "$out"
        for name in first second unrelated; do
          openssl req -x509 -newkey rsa:2048 -nodes -keyout "$name.key" \
            -out "$out/$name.pem" -days 3650 -subj "/CN=Test CA $name" \
            -addext basicConstraints=critical,CA:TRUE -addext keyUsage=critical,keyCertSign,cRLSign
          openssl req -new -newkey rsa:2048 -nodes -keyout leaf.key \
            -out leaf.csr -subj "/CN=synthetic.invalid"
          printf '%s\n' 'basicConstraints=critical,CA:FALSE' \
            'keyUsage=critical,digitalSignature,keyEncipherment' \
            'extendedKeyUsage=serverAuth' 'subjectAltName=DNS:synthetic.invalid' > leaf.ext
          openssl x509 -req -in leaf.csr -CA "$out/$name.pem" -CAkey "$name.key" \
            -set_serial 2 -days 3650 -extfile leaf.ext -out "$out/$name-leaf.pem"
        done
        openssl x509 -in "$out/second.pem" -addtrust anyExtendedKeyUsage \
          -trustout -out "$out/trusted.pem"
        printf '# Synthetic bundle\r\n' > "$out/valid.pem"
        sed 's/$/\r/' "$out/first.pem" >> "$out/valid.pem"
        cat "$out/second.pem" "$out/trusted.pem" >> "$out/valid.pem"
        ln -s valid.pem "$out/symlink.pem"

      '';
  converterTests = import ./java-truststore.nix { inherit pkgs; };
  mkJdk = import ../jdk-with-certificates.nix {
    inherit pkgs;
    certificatePath = "${fixtures}/valid.pem";
  };
  seed =
    jdk:
    jdk.overrideAttrs (
      _: old: {
        installPhase = old.installPhase + ''
          ${pkgs.openssl}/bin/openssl pkcs12 -export -nokeys -jdktrust anyExtendedKeyUsage \
            -certpbe NONE -nomac -passout pass: \
            -in ${fixtures}/first.pem -out "$out/lib/security/cacerts"
        '';
      }
    );
  seed21 = seed pkgs.jdk21;
  seed25 = seed pkgs.jdk25;
  jdk21 = mkJdk seed21;
  jdk25 = mkJdk seed25;
  overlayPkgs =
    (import ../java-certificate-overlay.nix {
      certificatePath = "${fixtures}/valid.pem";
    })
      pkgs
      pkgs;
  probe = pkgs.writeText "TrustCheck.java" ''
    import java.nio.file.*;
    import java.security.*;
    import java.security.cert.*;
    import java.util.*;
    import javax.net.ssl.*;

    public class TrustCheck {
        static X509Certificate certificate(Path path) throws Exception {
            try (var input = Files.newInputStream(path)) {
                return (X509Certificate) CertificateFactory.getInstance("X.509").generateCertificate(input);
            }
        }
        public static void main(String[] args) throws Exception {
            var home = Path.of(System.getProperty("java.home")).toRealPath();
            if (args.length == 1 && args[0].equals("--child")) {
                System.out.println(home);
                return;
            }
            for (var name : List.of("JAVA_TOOL_OPTIONS", "JDK_JAVA_OPTIONS", "_JAVA_OPTIONS", "JAVAX_NET_SSL_TRUSTSTORE"))
                if (System.getenv(name) != null) throw new AssertionError("Unexpected environment: " + name);
            for (var name : List.of("javax.net.ssl.trustStore", "javax.net.ssl.trustStorePassword", "javax.net.ssl.trustStoreType"))
                if (System.getProperty(name) != null) throw new AssertionError("Unexpected trust property: " + name);
            var root = Path.of(args[0]).toRealPath();
            var fixtures = Path.of(args[1]);
            boolean extended = Boolean.parseBoolean(args[2]);
            var storePath = home.resolve("lib/security/cacerts").toRealPath();
            if (!home.startsWith(root) || !storePath.startsWith(root))
                throw new AssertionError("Runtime home/store escaped derived output: " + home);
            if (!root.resolve("bin/java").toRealPath().equals(home.resolve("bin/java").toRealPath()))
                throw new AssertionError("Wrong java symlink");
            var factory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
            factory.init((KeyStore) null);
            var manager = (X509TrustManager) factory.getTrustManagers()[0];
            var expected = new HashSet<X509Certificate>();
            expected.add(certificate(fixtures.resolve("first.pem")));
            if (extended) expected.add(certificate(fixtures.resolve("second.pem")));
            if (!expected.equals(new HashSet<>(Arrays.asList(manager.getAcceptedIssuers()))))
                throw new AssertionError("Unexpected DEFAULT trusted certificates");
            var store = KeyStore.getInstance(storePath.toFile(), (char[]) null);
            if (store.size() != expected.size()) throw new AssertionError("Duplicate or missing entries");
            for (var alias : Collections.list(store.aliases()))
                if (!store.isCertificateEntry(alias)) throw new AssertionError("Not a trusted certificate entry");
            if (extended) {
                var b = certificate(fixtures.resolve("second.pem"));
                var alias = "extra-sha256-" + HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(b.getEncoded()));
                if (!b.equals(store.getCertificate(alias))) throw new AssertionError("Missing fingerprint alias");
            }
            for (var name : List.of("first", "second", "unrelated")) {
                boolean shouldTrust = name.equals("first") || (extended && name.equals("second"));
                try {
                    manager.checkServerTrusted(new X509Certificate[] {
                        certificate(fixtures.resolve(name + "-leaf.pem")),
                        certificate(fixtures.resolve(name + ".pem"))
                    }, "RSA");
                    if (!shouldTrust) throw new AssertionError("Unexpectedly trusted " + name);
                } catch (CertificateException e) {
                    if (shouldTrust) throw new AssertionError("Rejected " + name, e);
                }
            }
            var child = new ProcessBuilder(root.resolve("bin/java").toString(), "-XX:-UsePerfData",
                "-cp", Path.of(TrustCheck.class.getProtectionDomain().getCodeSource().getLocation().toURI()).toString(),
                "TrustCheck", "--child")
                .redirectError(ProcessBuilder.Redirect.INHERIT).start();
            var childHome = new String(child.getInputStream().readAllBytes()).trim();
            if (child.waitFor() != 0 || !home.toString().equals(childHome))
                throw new AssertionError("Subprocess failed or selected wrong JVM");
            System.out.println("Verified default trust: " + home);
        }
    }
  '';
in
assert jdk21.drvPath == (overlayPkgs.mkJdkWithCertificates seed21).drvPath;
assert jdk25.drvPath == (overlayPkgs.mkJdkWithCertificates seed25).drvPath;
assert
  jdk21.drvPath == (import ../jdk-with-certificates.nix {
    inherit pkgs;
    certificatePath = "${fixtures}/symlink.pem";
  } seed21).drvPath;
assert
  jdk21.drvPath != (import ../jdk-with-certificates.nix {
    inherit pkgs;
    certificatePath = "${fixtures}/second.pem";
  } seed21).drvPath;
assert jdk21.drvPath != jdk25.drvPath;
assert toString jdk21.home == toString jdk21;
assert toString jdk25.home == toString jdk25;
pkgs.runCommandLocal "jdk-with-certificates-tests"
  {
    nativeBuildInputs = [ pkgs.openssl ];
    inherit converterTests;
    passthru = {
      inherit
        fixtures
        jdk21
        jdk25
        probe
        ;
    };
  }
  ''
    unset JAVA_TOOL_OPTIONS JDK_JAVA_OPTIONS _JAVA_OPTIONS JAVAX_NET_SSL_TRUSTSTORE JAVA_HOME
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    cp ${probe} TrustCheck.java
    ${jdk21}/bin/javac -J-XX:-UsePerfData -d . TrustCheck.java
    ${seed21}/bin/java -XX:-UsePerfData TrustCheck ${seed21} ${fixtures} false
    ${seed25}/bin/java -XX:-UsePerfData TrustCheck ${seed25} ${fixtures} false
    ${jdk21}/bin/java -XX:-UsePerfData TrustCheck ${jdk21} ${fixtures} true
    ${jdk25}/bin/javac -J-XX:-UsePerfData -d . TrustCheck.java
    ${jdk25}/bin/java -XX:-UsePerfData TrustCheck ${jdk25} ${fixtures} true
    for jdk in ${jdk21} ${jdk25}; do
      unset JAVA_HOME
      . "$jdk/nix-support/setup-hook"
      test "$JAVA_HOME" = "$jdk"
      openssl pkcs12 -in "$jdk/lib/security/cacerts" -passin pass: -info -noout 2> info
      grep -q 'MAC is absent' info
      ! grep -Eq 'Encrypted|Shrouded|Key bag' info
    done
    test "$(readlink -f "${jdk21.bundle}/Contents/Home/bin/java")" = "$(readlink -f "${jdk21}/bin/java")"
    test "$(readlink -f "${jdk25.bundle}/Contents/Home/bin/java")" = "$(readlink -f "${jdk25}/bin/java")"
    touch "$out"
  ''
