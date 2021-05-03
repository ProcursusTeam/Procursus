# Building on FreeBSD
Building on FreeBSD is made possible by cctools-port.

This assumes you have sudo installed and configured.

1. install packages
```
sudo pkg install findutils git gmake patch gnugrep po4a docbook-xsl ncurses autoconf automake gettext libtool pkgconf dpkg fakeroot zstd python39 coreutils bash cmake gnupg openssl gsed gtar perl5 wget
```
2. get triehash
```
wget -O triehash https://raw.githubusercontent.com/julian-klode/triehash/main/triehash.pl
gsed -i 's@#!/usr/bin/perl -w@#!/usr/bin/env perl -w@g' triehash
sudo mv triehash /usr/local/bin
```
3. Run iOS toolchain [installer script](https://gist.github.com/asdfugil/71cdfca5aa1bc0d59de06518cd1c530c)
```
wget https://gist.githubusercontent.com/asdfugil/71cdfca5aa1bc0d59de06518cd1c530c/raw/d1c87a29c2659c6a6ad090638de3053934ad477e/procursus-utils-fbsd.sh
bash procursus-utils-fbsd.sh
```
4. Set up environment on every login
```
echo 'source procursus-utils-fbsd.sh' > .profile
```

5. Make it usable immediately
```
source procursus-utils-fbsd.sh
```
Now you can build Procursus packages! 

If you used a different SDK, you need to set `TARGET_SYSROOT=$(HOME)/cctools/SDK/YOUR_SDK_HERE.` Ideally, you should set it inside your .profile, .bashrc, or .zshrc. Then, open a new shell or use `source` again.

Test your toolchain by trying to build libmd: 

```make libmd```

This will build libmd quickly, so you can test if your toolchain works. If it does, congratulations! 
You should now be able to compile most packages in Procursus. 
Some packages, like golang and nodejs, will require an actual macOS system to build, but most won't.
