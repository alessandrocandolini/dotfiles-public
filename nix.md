# Nix & nix-darwin on macOS

This document provides concise instructions for installing **Nix** and **nix-darwin** on macOS, dealing with common pitfalls like `/run` and conflicting `/etc` files.

## Why Nix?

[Nix](https://github.com/NixOS/nix) is a *purely functional* package manager designed for **reproducible builds** and **isolated dev environments**. Key benefits:

- **Ephemeral builds** via `nix-shell -p <pkg>`, eliminating global installations and allowing temporary usage.
- **Per-project environments** that reduce conflicts in language runtimes or system packages.
- **Declarative** configuration of packages and services, achievable on macOS through **nix-darwin**.

## Installing Nix

No additional dependencies are required.

Run the official installer as described on https://nixos.org/download/
   
```bash
sh <(curl -L https://nixos.org/nix/install)
```

Opt for verbose mode and follow the prompts, allowing sudo access when requested. A multi-user installation is recommended on macOS.

Ensure that `/nix` is created. macOS restricts direct creation of folders under /, but modern Nix installers should be able to handle this by creating a volume and mounting it automatically.

## Troubleshooting Nix on macOS Sequoia 15.3

After upgrading macOS, running `nix-shell -p hello` or similar commands might result in the daemon disconnecting:
```
Nix daemon disconnected unexpectedly (maybe it crashed?).
```

In my case, Nix failed to download from the cache (cache.nixos.org) due to an SSL error:
```
Problem with the SSL CA cert (path? access rights?) (77)
```
This indicated that it couldn’t find a valid CA certificate bundle, expected at `/etc/ssl/certs/ca-certificates.crt`. 

It turned out `/etc/ssl/certs/ca-certificates.crt` was a symlink pointing to a non-existent or inaccessible file. Consequently, the Nix daemon had no trusted certificate authorities to verify HTTPS connections, causing it to crash on fetch attempts. Reinstalling Nix didn’t fix the missing CA certificates by itself

How to troubleshot
1. verify whether the daemon is loaded via `launchctl`
   ```
   sudo launchctl list | grep nix
   ```
2. Checks daemon logs:
   ```
   log show --predicate 'process == "nix-daemon"' --last 1d
   ```

Note: In my case there was no direct crash logs, however the error output in the terminal indicated an SSL issue.
To fix this CA problem, first delete the broken link 
```
sudo rm /etc/ssl/certs/ca-certificates.crt
```
and use macOS security tool to export the trusted root certificates from the System keychain and store them in a file:
```
security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain \
  | sudo tee /etc/ssl/certs/ca-certificates.crt >/dev/null
```
(Note: Directly redirecting (`>` instead of `tee`) to `/etc/ssl/certs/ca-certificates.crt` is not possible due to system protections.)
This replaced the broken symlink with a real file containing all the macOS-trusted CAs.

Finally, set the correct file permissions:
```
sudo chmod 644 /etc/ssl/certs/ca-certificates.crt
```
Point Nix to the certificate bundle:
```
export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
```
and reboot just in case. 

## Installing nix-darwin (Channel-Based)

It can be installed using `nix`, once nix is installed.

Check latest instructions on [nix-darwin README](https://github.com/LnL7/nix-darwin). In general, `nix-darwin` offers two installations 
* flake-based (preferred)
* channel-based

This dotfile repo still uses the old channel-based solution for the configuration file. 
Check the docs for details, but high level it usually involves adding the nix-darwin channel (no need for sudo here) 
```
nix-channel --add https://github.com/LnL7/nix-darwin/archive/master.tar.gz darwin
nix-channel --update
```
and assuming the configuration file provided by this repo has been `stow`-ed, 
```
nix-build '<darwin>' -A darwin-rebuild
./result/bin/darwin-rebuild switch -I darwin-config="$HOME/.nixpkgs/darwin-configuration.nix"
```

If nix-darwin complains about files like `/etc/bashrc` or `/etc/ssl/certs/ca-certificates.crt`, rename them to preserve your existing content:
```
sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
sudo mv /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt.before-nix-darwin
```
(this requires `sudo`) and then re-run.

### Setting up /run with /etc/synthetic.conf

It might happen that the `nix-darwin` installer fails due to the need of creating a symbolic link on `/run`. 
The solution is to edit `/etc/synthetic.conf` to look like this: 
```
12:50 $ cat /etc/synthetic.conf
nix
run     /System/Volumes/Data/private/var/run/
```
then run the following command to apply the changes 
```
sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t
```
and **reboot** the machine in order the changes to become effective. 

After reboot, confirm /run is now a symlink:
```
ls -l /run
# => run -> private/var/run
```

## Further readings 
* [What Is Nix and Why You Should Use It](https://serokell.io/blog/what-is-nix)
* [Using Nix to set up my new Mac](https://adrianhesketh.com/2020/07/03/mac-setup-with-nix-darwin/)
* [https://wickedchicken.github.io/post/macos-nix-setup/](https://wickedchicken.github.io/post/macos-nix-setup/)
* [Dev Environment Setup With Nix on MacOS](https://www.mathiaspolligkeit.de/dev/exploring-nix-on-macos/)
* [Set up nix & home-manager in macoS Big Sur 11](https://gist.github.com/mandrean/65108e0898629e20afe1002d8bf4f223)
