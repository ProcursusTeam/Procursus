Building Procursus packages on GNU Linux is possible with [cctools-port](https://github.com/tpoechtrager/cctools-port). While there's no specific Linux distro that you should use, it's recommended that you use a fairly known distro (e.g Debian).

If you're using Debian (specifically Unstable or Buster), you can use a prebuilt toolchain, which provides everything you need (except SDKs).

    $ curl -LO https://cameronkatri.com/cameronkatri.gpg
    $ sudo install -o root -g root cameronkatri.gpg /etc/apt/trusted.gpg.d/cameronkatri.gpg
    $ echo -e 'deb https://cameronkatri.com/debian $(lsb_release -cs) main\ndeb-src https://cameronkatri.com/debian $(lsb_release -cs) main' | sudo tee /etc/apt/sources.list.d/cameronkatri.list
    $ sudo apt update
    $ sudo apt install cctools-port ldid

Another easy way to setup Procursus on your Linux distro is using [this script](https://gist.github.com/1Conan/4347fd5f604cfe6116f7acb0237ef155). Download it on your system and run it.

    $ bash procursus-utils.sh
    $ source procursus-utils.sh

The script will setup everything needed for Procursus (e.g SDK, dependencies, toolchain, etc). However, if the script doesn't work for you, you'll need to manually setup your build system.

1. Install dependencies and download Procursus

    Most packages you'll need should be available through APT or whichever package manager your distro uses. You'll need Git installed on your system to clone Procursus

        $ git clone --recursive https://github.com/ProcursusTeam/Procursus.git

2. Download your iOS SDK

    Unlike other platforms, your iOS SDK on Linxu needs a bit of "surgery", since you'll need to add C++ standard libraries to it. 
    
    It's prefered that you get an SDK for iOS 13 or above. Once you have your iOS SDK, add the C++ libraries

        $ TEMPSDKFOLDER=$(mktemp -d)
        $ mkdir $TEMPSDKFOLDER/tmp
        $ wget https://github.com/okanon/iPhoneOS.sdk/releases/download/v0.0.1/iPhoneOS13.2.sdk.tar.gz -O $TEMPSDKFOLDER/iOSSDK.tar.gz
        $ tar -xf $TEMPSDKFOLDER/iOSSDK.tar.gz -C $TEMPSDKFOLDER/tmp
        $ wget https://cdn.discordapp.com/attachments/688121419980341282/725234834024431686/c.zip -O $TEMPSDKFOLDER/iOSC.zip
        $ unzip -o $TEMPSDKFOLDER/iOSC.zip -d $TEMPSDKFOLDER/tmp/iPhoneOS13.2.sdk/usr/include
        (
        cd $TEMPSDKFOLDER/tmp/
        tar caf ~/iPhoneOS13.2.sdk.tar.xz iPhoneOS13.2.sdk
        )
        $ rm -Rf $TEMPSDKFOLDER

3. Setup cctools-port and build an iOS toolchain

    To get started with your toolchain, clone cctools-port on your system

        $ git clone --recursive https://github.com/tpoechtrager/cctools-port

    After, edit ``TRIPLE`` in ``build.sh`` (line 90) to ``aarch64-apple-darwin``, or whatever toolchain you want to build. It's recommended that you "remove the 11 from Darwin"

        $ cd cctools-port/usage_examples/ios_toolchain
        $ sed -i 's/arm-apple-darwin11/aarch64-apple-darwin/g' build.sh

    After, you can run ``build.sh`` by specifying your iOS SDK path

        $ ./build.sh [SDK] arm64

4. Add your created toolchain to PATH

    This step makes it easier for Procursus to use tools from the created toolchain. It's recommended that you move your created toolchain to your home folder
    
    The toolchain created is within the "target" folder

        $ mv target ~/cctools
        
    You can then add the new path (~/cctools) to your shell's configuration profile (e.g .profile, .bashrc, .zshrc). Make sure to reload your config file or relogin to a new shell

        if [ -d "$HOME/cctools" ]; then
            PATH="$HOME/cctools/bin:$PATH"
        fi

5. Get your macOS SDK

    Unlike your iOS SDK, you can just download a macOS SDK from [phracker/MacOSX-SDKs](https://github.com/phracker/MacOSX-SDKs), extract it, and move it to ``~/cctools/SDK/``

    It's recommended that you use the latest available SDK in the repository above

        $ wget https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.3.sdk.tar.xz
        $ tar -xf MacOSX11.3.sdk.tar.xz -C ~/cctools/SDK/
        $ mv ~/cctools/SDK/MacOSX11.3.sdk ~/cctools/SDK/MacOSX.sdk
        $ rm MacOSX11.3.sdk.tar.xz

    You can also specify and export SDK variables to use a differnet path. Check out the ["Build options"](https://github.com/ProcursusTeam/Procursus/wiki/Build-options) page for more documentation

6. Build!

    To check whether you did everything correctly, attempt to build ``bash`` with a few options from the ["Build options"](https://github.com/ProcursusTeam/Procursus/wiki/Build-options) page

        $ make bash [OPTIONS]

    If the build is successful, congrats! You should now be able to compile packages from Procursus

    Similar to other supported platforms, it's likely that some packages (particularly those that need Go, Python, and/or NodeJS) will fail to compile. You'll need a macOS build system if this is the case

    If you find yourself needing a macOS build system, you can [setup macOS in a KVM](https://github.com/foxlet/macOS-Simple-KVM)
