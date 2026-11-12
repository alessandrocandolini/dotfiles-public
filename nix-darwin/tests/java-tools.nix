{ pkgs }:

let
  jdkTests = import ./jdk-with-certificates.nix { inherit pkgs; };
  inherit (jdkTests)
    fixtures
    jdk21
    jdk25
    probe
    ;
  sbt = pkgs.sbt.override { jre = jdk25; };
  coursier = pkgs.coursier.override { jre = jdk25; };
  # JDK 25 toolchains require Gradle >= 9.1; leave the default Gradle alias alone.
  gradle = pkgs.gradle_9.override {
    java = jdk21;
    javaToolchains = [
      jdk21
      jdk25
    ];
  };
  # The pinned cs is a bootstrap launcher. Fetch its public runtime dependencies
  # as a fixed-output build input; the actual tests below run offline.
  coursierBootstrap =
    pkgs.runCommand "coursier-test-bootstrap-${coursier.version}"
      {
        nativeBuildInputs = [
          pkgs.curl
          pkgs.unzip
        ];
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        outputHashMode = "recursive";
        outputHashAlgo = "sha256";
        outputHash = "sha256-JIqNEPNKbMYeNmVSJGnsTCXAgcoVkNGGPh3xHqAf0nc=";
      }
      ''
        unzip -p ${coursier.src} coursier/bootstrap/launcher/bootstrap-jar-urls > urls || test "$?" -eq 1
        test -s urls
        while IFS= read -r url || test -n "$url"; do
          case "$url" in
            https://repo1.maven.org/maven2/*) ;;
            *) echo "Unexpected Coursier bootstrap URL: $url" >&2; exit 1 ;;
          esac
          curl --fail --location --retry 2 --create-dirs \
            "$url" -o "$out/https/''${url#https://}"
        done < urls
      '';
in
pkgs.runCommandLocal "java-tool-tests"
  {
    nativeBuildInputs = [ pkgs.unzip ];
    inherit jdkTests;
    passthru = { inherit coursierBootstrap; };
  }
  ''
    unset JAVA_TOOL_OPTIONS JDK_JAVA_OPTIONS _JAVA_OPTIONS JAVAX_NET_SSL_TRUSTSTORE
    unset JAVA_HOME JDK_HOME JAVA_OPTS SBT_OPTS GRADLE_OPTS
    export HOME="$TMPDIR/home"
    export XDG_CONFIG_HOME="$HOME/.config" XDG_CACHE_HOME="$HOME/.cache"
    export COURSIER_CACHE="$TMPDIR/coursier"
    export GRADLE_USER_HOME="$TMPDIR/gradle"
    mkdir -p "$HOME" "$COURSIER_CACHE"
    cp -R ${coursierBootstrap}/. "$COURSIER_CACHE/"
    chmod -R u+w "$COURSIER_CACHE"
    cp ${probe} TrustCheck.java
    ${jdk21}/bin/javac -J-XX:-UsePerfData TrustCheck.java
    ${jdk21}/bin/jar --create --file probe.jar --main-class TrustCheck TrustCheck.class

    # Exercise sbt's actual launcher with a local replacement boot JAR.
    cat > SbtLaunch.java <<'JAVA'
    import java.nio.file.*;
    class SbtLaunch {
        public static void main(String[] args) throws Exception {
            if (args.length > 0 && args[0].equals("--rt-ext-dir")) {
                System.out.println(Path.of("java9-rt-ext-test").toAbsolutePath());
            } else if (args.length > 0 && args[0].equals("--export-rt")) {
                Files.createFile(Path.of(args[1]));
            } else {
                TrustCheck.main(new String[] { "${jdk25}", "${fixtures}", "true" });
            }
        }
    }
    JAVA
    ${jdk21}/bin/javac -J-XX:-UsePerfData SbtLaunch.java
    ${jdk21}/bin/jar --create --file sbt-probe.jar --main-class SbtLaunch SbtLaunch.class TrustCheck.class
    ${sbt}/bin/sbt --batch --allow-empty --sbt-jar "$PWD/sbt-probe.jar" > sbt.log 2>&1
    grep -F "Verified default trust: ${jdk25}/" sbt.log

    # A synthetic Maven application: test the Coursier JVM and its forked app.
    mkdir -p maven/test/probe/1
    cp probe.jar maven/test/probe/1/probe-1.jar
    cat > maven/test/probe/1/probe-1.pom <<'POM'
    <project><modelVersion>4.0.0</modelVersion><groupId>test</groupId><artifactId>probe</artifactId><version>1</version></project>
    POM
    # The shell launcher uses PATH; macOS app JVM discovery needs JAVA_HOME.
    ${coursier}/bin/cs -J-XX:-UsePerfData -J-Duser.home="$HOME" \
      -J-XshowSettings:properties --help > coursier-launcher.log 2>&1
    grep -F 'java.home = ${jdk25}/' coursier-launcher.log
    export JAVA_HOME=${jdk25.home}
    for fork in false true; do
      ${coursier}/bin/cs -J-XX:-UsePerfData -J-Duser.home="$HOME" launch --no-default \
        --repository "file://$PWD/maven" --fork="$fork" \
        --main-class TrustCheck test:probe:1 -- ${jdk25} ${fixtures} true
    done

    unset JAVA_HOME

    # Check the daemon's default trust independently of compilation toolchains.
    mkdir -p project/src/main/java
    cp TrustCheck.java project/src/main/java/
    cat > project/settings.gradle <<'GRADLE'
    rootProject.name = 'synthetic-trust'
    GRADLE
    cat > project/gradle.properties <<'GRADLE'
    org.gradle.java.installations.auto-detect=false
    org.gradle.java.installations.auto-download=false
    GRADLE
    cat > project/build.gradle <<'GRADLE'
    plugins { id 'java' }
    def expectedHome = providers.gradleProperty('expectedHome').get()
    def expectedVersion = providers.gradleProperty('testJdk').get().toInteger()
    java { toolchain { languageVersion = JavaLanguageVersion.of(expectedVersion) } }
    tasks.register('checkRuntime') {
        doLast {
            assert new File(System.getProperty('java.home')).canonicalPath.startsWith(expectedHome + '/')
            def tmf = javax.net.ssl.TrustManagerFactory.getInstance(
                javax.net.ssl.TrustManagerFactory.defaultAlgorithm)
            tmf.init((java.security.KeyStore) null)
            def accepted = new HashSet(Arrays.asList(tmf.trustManagers[0].acceptedIssuers))
            def cf = java.security.cert.CertificateFactory.getInstance('X.509')
            def expected = ['first', 'second'].collect {
                new File('${fixtures}/' + it + '.pem').withInputStream { cf.generateCertificate(it) }
            }.toSet()
            assert accepted == expected
            println 'Verified Gradle runtime: ' + System.getProperty('java.home')
        }
    }
    tasks.register('probe', JavaExec) {
        dependsOn classes, checkRuntime
        classpath = sourceSets.main.runtimeClasspath
        mainClass = 'TrustCheck'
        javaLauncher = javaToolchains.launcherFor {
            languageVersion = JavaLanguageVersion.of(expectedVersion)
        }
        args(expectedVersion == 21 ? '${jdk21}' : '${jdk25}', '${fixtures}', 'true')
    }
    tasks.named('compileJava') {
        doFirst {
            def expected = expectedVersion == 21 ? '${jdk21}' : '${jdk25}'
            assert javaCompiler.get().metadata.installationPath.asFile.canonicalPath.startsWith(expected)
        }
    }
    GRADLE
    for version in 21 25; do
      ${gradle}/bin/gradle -p project --offline --no-daemon --console plain \
        -PexpectedHome=${jdk21} -PtestJdk="$version" clean probe
    done
    # An inherited JAVA_HOME takes precedence over Gradle's default.
    JAVA_HOME=${jdk25} ${gradle}/bin/gradle -p project --offline --no-daemon --console plain \
      -PexpectedHome=${jdk25} -PtestJdk=25 checkRuntime
    touch "$out"
  ''
