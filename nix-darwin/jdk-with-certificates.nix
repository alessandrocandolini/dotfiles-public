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
                throw new IllegalStateException("Expected a passwordless PKCS12 cacerts");
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
            try (var output = Files.newOutputStream(path)) {
                store.store(output, null);
            }
        }
    }
  '';
in
baseJdk:
baseJdk.overrideAttrs (
  finalAttrs: old:
  let
    rebase =
      value:
      let
        insideStorePath = builtins.match "${builtins.storeDir}/[^/]+(.*)" (
          builtins.unsafeDiscardStringContext (toString value)
        );
      in
      if insideStorePath == null then
        value
      else
        "${finalAttrs.finalPackage}${builtins.head insideStorePath}";
  in
  {
    pname = "${old.pname}-with-extra-certificates";
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.openssl ];
    postFixup = (old.postFixup or "") + ''
      unset JAVA_TOOL_OPTIONS JDK_JAVA_OPTIONS _JAVA_OPTIONS JAVAX_NET_SSL_TRUSTSTORE
      home=$("$out/bin/java" -XX:-UsePerfData -XshowSettings:properties -version 2>&1 \
        | sed -n 's/^ *java\.home = //p')
      test -n "$home"
      store="$home/lib/security/cacerts"
      test ! -e "$home/lib/security/jssecacerts"
      case "$(readlink -f "$store")" in
        "$out"/*) ;;
        *) echo "cacerts must belong to the new JDK output" >&2; exit 1 ;;
      esac
      openssl pkcs12 -in "$store" -passin pass: -info -noout 2> store-info
      grep -q 'MAC is absent' store-info
      if grep -Eq 'Encrypted|Shrouded|Key bag' store-info; then
        echo "Expected an unencrypted, certificate-only cacerts" >&2
        exit 1
      fi
      "$out/bin/java" -XX:-UsePerfData \
        ${merger} "$store" ${javaTruststore} "$out"
    '';
    passthru =
      (old.passthru or { })
      // lib.mapAttrs (_: rebase) (
        builtins.intersectAttrs {
          home = null;
          bundle = null;
        } (old.passthru or { })
      )
      // {
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
