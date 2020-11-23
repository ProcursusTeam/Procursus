# Building on Linux
Building on linux is made possible by cctools-port.

### The easiest way to do this is by using [this script](https://gist.github.com/1Conan/4347fd5f604cfe6116f7acb0237ef155).

```bash
wget https://gist.github.com/1Conan/4347fd5f604cfe6116f7acb0237ef155/raw/1def5bf44275ffd6424721f1ce7a535db71a3016/procursus-utils.sh

# run this once to download and compile everything needed
bash procursus-utils.sh

# then you can source it in your .profile or just in your shell to get started
source procursus-utils.sh
```


If you want to do it manually, however, follow these instructions.

1. Dependencies
- You need: clang (>=3.4) and everything Procursus normally needs. Get clang with apt.

2. Get iOS SDK
- You're going to need an iOS 13 SDK. Since you're on Linux, you're going to have to download an _unpatched_ SDK, and add C++ standard libraries to it.
```
TEMPSDKFOLDER=$(mktemp -d)
mkdir $TEMPSDKFOLDER/tmp
wget https://github.com/okanon/iPhoneOS.sdk/releases/download/v0.0.1/iPhoneOS13.2.sdk.tar.gz -O $TEMPSDKFOLDER/iOSSDK.tar.gz
tar -xf $TEMPSDKFOLDER/iOSSDK.tar.gz -C $TEMPSDKFOLDER/tmp
wget https://cdn.discordapp.com/attachments/688121419980341282/725234834024431686/c.zip -O $TEMPSDKFOLDER/iOSC.zip
unzip -o $TEMPSDKFOLDER/iOSC.zip -d $TEMPSDKFOLDER/tmp/iPhoneOS13.2.sdk/usr/include
(
cd $TEMPSDKFOLDER/tmp/
tar caf ~/iPhoneOS13.2.sdk.tar.xz iPhoneOS13.2.sdk
)
rm -Rf $TEMPSDKFOLDER
```

3. Get CCTools Port
- You need Git for this. 

```git clone https://github.com/tpoechtrager/cctools-port```

4. Build iOS Toolchain
- Edit TRIPLE in cctools-port/usage_examples/ios_toolchain/build.sh (line 90) to aarch64-apple-darwin, or whatever toolchain you want to build. Just make sure you remove the 11 from darwin.
```
cd cctools-port/usage_examples/ios_toolchain
sed -i 's/arm-apple-darwin11/aarch64-apple-darwin/g' build.sh
```
- Now, build!

```./build.sh ~/iPhoneOS13.2.sdk.tar.xz arm64```

5. Add to PATH
- The last step made a toolchain in the "target" folder. We can use this to compile Procursus, but first we need to move it to our home folder and tell our system to use it.

```mv target ~/cctools```
- Then add this to your .profile, .bashrc, or .zshrc (for whichever shell you're using):
```
if [ -d "$HOME/cctools" ] ; then
    PATH="$HOME/cctools/bin:$PATH"
fi
```
- And finally, login to a new shell or

```source ~/.the_file_you_just_edited```. 


6. Get MacOS SDK

We're going to download the MacOS 10.15 SDK from https://github.com/phracker/MacOSX-SDKs and extract it, then move it to ~/cctools/SDK/MacOSX.sdk.
```
wget https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz
tar -xf MacOSX10.15.sdk.tar.xz -C ~/cctools/SDK/
mv ~/cctools/SDK/MacOSX10.15.sdk ~/cctools/SDK/MacOSX.sdk
rm MacOSX10.15.sdk.tar.xz
```

You can now compile Procursus packages!

If you used a different SDK, you need to set `TARGET_SYSROOT=$(HOME)/cctools/SDK/YOUR_SDK_HERE`.
Ideally, you should set it inside your .profile, .bashrc, or .zshrc. Then, open a new shell or use ```source``` again.

Test your toolchain by trying to build bash: 

```make bash```

This will build bash quickly, so you can test if your toolchain works. If it does, congratulations! 
You should now be able to compile almost everything in Procursus with Linux. 
Some tools, like golang and nodejs, will need an actual MacOS system, but most things won't. If you do find the need to run MacOS, you can use [this excellent guide for setting up MacOS in a KVM](https://github.com/foxlet/macOS-Simple-KVM).
