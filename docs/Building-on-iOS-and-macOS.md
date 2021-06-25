Building Procursus packages on iOS and macOS is fairly simple. Make sure that you have a decent amount of free space on your device.

This setup guide assumes that your device is already setup with Procursus already.

1. Install toolchain

    On macOS, install the latest stable Xcode.

    On iOS, install the following in your preferred package manager (e.g Sileo), or with APT

    ```
    sudo apt install clang dsymutil odcctools
    ```

1. Download SDKs (iOS only)

    If you are on macOS, skip to step 3.

    To build Procursus packages, you'll need an iOS and macOS SDK. You already have an iOS SDK installed after installing the toolchain. The repository below is one where you can grab a macOS SDK.

    - [phracker/MacOSX-SDKs](https://github.com/phracker/MacOSX-SDKs) for macOS SDKs

    You'd likely want to checkout the default values of the platform where you're setting up Procursus, since each platform uses a different path for SDKs

    Ideally, you can also export SDK variables from the ["Build options"](https://github.com/ProcursusTeam/Procursus/wiki/Build-options) page on your shell configuration

2. Install dependencies

    You can install dependencies with your package manager or APT

    ```
    sudo apt install autoconf automake autopoint bison cmake docbook-xml docbook-xsl fakeroot flex gawk git gnupg groff ldid libtool make ncurses-bin openssl patch pkg-config po4a python3 sed tar triehash wget xz-utils zstd
    ```
    
3. Clone the Procursus build system

    ```
    git clone --recursive https://github.com/ProcursusTeam/Procursus.git
    ```

4. Build!

    Building packages on iOS can be a bit of a hit or miss. However, macOS is the main supported system where all packages should (and will) compile.

    To test your own build system setup, attempt to build ``bash``. Checkout the ["Build options"](https://github.com/ProcursusTeam/Procursus/wiki/Build-options) page to see what valid options can be passed

    ```
    make bash-package [OPTIONS]
    ```
    
    Now you're rolling. Cheers!
