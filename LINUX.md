# Building on Linux
Building on linux is made possible by cctools-port.

### The easiest way to do this is by using [this script](https://gist.github.com/1Conan/4347fd5f604cfe6116f7acb0237ef155).

If you want to do it manually, however, follow these instructions.

1. Dependencies
- You need: clang (>=3.4) and everything Procursus normally needs. Get clang with apt.

2. Get iOS SDK
- You're going to need an iOS 13 SDK. Since you're on Linux, you're going to have to search online for one. I personally use https://github.com/xybp888/iOS-SDKs.

3. Compress SDK
- Compress iPhoneOS.sdk to iPhoneOS.sdk.tar.xz. ```tar caf iPhoneOS.sdk.tar.xz iPhoneOS.sdk```

4. Get CCTools Port
- You need Git for this. ```git clone https://github.com/tpoechtrager/cctools-port```

5. Build iOS Toolchain
- ```cd cctools-port/usage_examples/ios_toolchain && ./build.sh /PATH/TO/IPHONEOS-SDK/TAR/XZ arm64```

6. Add to PATH
- The last step made a toolchain in the "target" folder. We can use this to compile Procursus, but first we need to move it to our home folder and tell our system to use it.
- ```mv target ~/cctools```
- Then add this to your .profile, .bashrc, or .zshrc:

```
if [ -d "$HOME/cctools" ] ; then
    PATH="$HOME/cctools/bin:$PATH"
fi
```
- And finally, ```source ~/.the_file_you_just_edited```. Or, just exit and relogin to a new shell.

7. Rename files

- You need to rename the files for them to work properly with Procursus.

```cd ~/cctools/bin
for i in aarch64*; do; mv -v "$i" "$(echo "$i" | sed -e 's/11//' -)"; done
```

8. Get MacOS SDK

Download the MacOS 10.15 SDK from https://github.com/phracker/MacOSX-SDKs and extract it, then move it to ~/cctools/SDK/MacOSX.sdk.

You can now compile Procursus... with some tweaking. You'll need to set some options manually with your custom build.

You need to set TARGET_SYSROOT=$(HOME)/cctools/SDK/YOUR_SDK_HERE (in case you didn't use the 13.2 SDK, which is default for this repo).

The final command to build looks something like this: 

```make bash TARGET_SYSROOT=$(HOME)/cctools/SDK/iPhoneOS13.3.sdk```

You should now be able to compile almost everything in Procursus with Linux. Some tools, like golang and nodejs, will need an actual MacOS system, but most things won't.
