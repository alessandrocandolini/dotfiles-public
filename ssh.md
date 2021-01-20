how to configure ssh keys for multiple github accounts: add to `$HOME/.ssh/config` the following 

```
Host github.com-acando86
  AddKeysToAgent yes
  HostName github.com
  User git
  IdentityFile ~/.ssh/key_for_acando86_account

Host github.com-alessandrocandolini
  AddKeysToAgent yes
  HostName github.com
  User git
  IdentityFile ~/.ssh/key_for_alessandrocandolini_account
```   

(obviously, when setting the remote of a repo, the hosts should be configured as above)
