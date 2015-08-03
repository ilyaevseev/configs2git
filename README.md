# configs2git

Copies selected configs to Git or Hg repository. It is better than track entire /etc with tons of garbage.

### Example:

#### Prepare once:

* echo '
    /boot/grub/grub.cfg
    /etc/apt/sources.list.d/
    /etc/fstab
    /etc/group
    /etc/passwd
    /etc/shadow
    /etc/rc.local
    /root/.ssh/
    ' > myconfigs.lst
* git init myconfigs

#### Do periodically:

* configs2git myconfigs.lst myconfigs/

### Mercurial support

When script is named as **configs2hg**, it tries to use Mercurial instead of Git.

### Todo

* support wildcards
* helpers for OpenVZ and LXC
