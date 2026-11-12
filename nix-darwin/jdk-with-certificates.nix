{ pkgs, certificatePath }:

let
  inherit (pkgs) lib;
  javaTruststore = import ./java-truststore.nix { inherit pkgs certificatePath; };
  merger = pkgs.writeText "MergeCertificates.java" ''
    import java.nio.file.*;
    import java.security.*;
    import java.security.cert.X509Certificate;
    import java.util.*;

    class MergeCertificates {
        static String fingerprint(java.security.cert.Certificate certificate) throws Exception {
            return HexFormat.of().formatHex(
                MessageDigest.getInstance("SHA-256").digest(certificate.getEncoded()));
        }

        public static void main(String[] args) throws Exception {
            var path = Path.of(args[0]).toRealPath();
            var root = Path.of(args[2]).toRealPath();
            var home = Path.of(System.getProperty("java.home")).toRealPath();
            if (!home.startsWith(root) || !path.startsWith(root))
                throw new IllegalStateException("JVM and cacerts must belong to the new JDK output");
            var store = KeyStore.getInstance(path.toFile(), (char[]) null);
            if (!store.getType().equalsIgnoreCase("PKCS12"))
                throw new IllegalStateException("Expected the Zulu passwordless PKCS12 store");
            var extra = KeyStore.getInstance(new java.io.File(args[1]), (char[]) null);
            var known = new HashSet<String>();
            for (var alias : Collections.list(store.aliases())) {
                if (!store.isCertificateEntry(alias))
                    throw new IllegalStateException("Unexpected non-certificate entry in cacerts");
                known.add(fingerprint(store.getCertificate(alias)));
            }
            var additions = new TreeMap<String, X509Certificate>();
            for (var alias : Collections.list(extra.aliases())) {
                var certificate = (X509Certificate) extra.getCertificate(alias);
                if (!extra.isCertificateEntry(alias))
                    throw new IllegalArgumentException("Expected a trusted certificate entry");
                additions.put(fingerprint(certificate), certificate);
            }
            for (var entry : additions.entrySet()) {
                if (known.add(entry.getKey())) {
                    var alias = "extra-sha256-" + entry.getKey();
                    if (store.containsAlias(alias))
                        throw new IllegalStateException("Certificate alias collision: " + alias);
                    store.setCertificateEntry(alias, entry.getValue());
                }
            }
            // Preserve the seed's passwordless/no-MAC semantics, checked by OpenSSL below.
            // New entry creation dates mean byte-for-byte reproducibility is not promised.
            try (var output = Files.newOutputStream(path)) {
                store.store(output, null);
            }
        }
    }
  '';
in
baseJdk:
let
  major = lib.versions.major baseJdk.version;
in
assert lib.assertMsg (
  pkgs.stdenv.hostPlatform.isDarwin
  && baseJdk.pname == "zulu-ca-jdk"
  && builtins.elem major [
    "21"
    "25"
  ]
) "mkJdkWithCertificates currently supports Darwin Zulu JDK 21 and 25 only";
baseJdk.overrideAttrs (
  finalAttrs: old: {
    pname = "${old.pname}-with-extra-certificates";
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.openssl ];
    # Zulu's installPhase does not run postInstall. Append after the vendor install.
    installPhase = old.installPhase + ''
      unset JAVA_TOOL_OPTIONS JDK_JAVA_OPTIONS _JAVA_OPTIONS JAVAX_NET_SSL_TRUSTSTORE
      store="$out/lib/security/cacerts"
      test ! -e "$out/lib/security/jssecacerts"
      case "$(readlink -f "$store")" in
        "$out"/*) ;;
        *) echo "cacerts must belong to the new JDK output" >&2; exit 1 ;;
      esac
      # Refuse to weaken a future seed store with different protection settings.
      openssl pkcs12 -in "$store" -passin pass: -info -noout 2> store-info
      grep -q 'MAC is absent' store-info
      if grep -Eq 'Encrypted|Shrouded|Key bag' store-info; then
        echo "Expected an unencrypted, certificate-only Zulu store" >&2
        exit 1
      fi
      "$out/bin/java" -XX:-UsePerfData \
        -Dkeystore.pkcs12.certProtectionAlgorithm=NONE \
        -Dkeystore.pkcs12.macAlgorithm=NONE \
        ${merger} "$store" ${javaTruststore} "$out"
    '';
    # The vendor passthru closes over the ORIGINAL derivation.
    passthru = (old.passthru or { }) // {
      home = finalAttrs.finalPackage;
      bundle = "${finalAttrs.finalPackage}/Library/Java/JavaVirtualMachines/zulu-${major}.jdk";
      tests = (old.passthru.tests or { }) // {
        version = pkgs.testers.testVersion {
          package = finalAttrs.finalPackage;
          command = "java -version";
          version = baseJdk.version;
        };
      };
    };
  }
)
