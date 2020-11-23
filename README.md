# Procursus

A new, powerful cross-compilation system for *OS devices coupled with an APT repo.

## Why?

At its birth, this build-system was meant to create an APT repo included in a specific jailbreak. That never came to pass, however, and it turned into more of a hobby project.

The current goal of Procursus is to provide a large set of consistently up-to-date *nix tools cross compiled to work on Darwin based platforms. It's built from the ground up in such a way that updating packages is quick and easy, helping to not fall behind upstream.

In the iOS jailbreak scene, it also attempts to address an odd fragmentation problem seen over the past couple years. There have been a couple new APT repositories that have arrisen from the ashes of Saurik's Telesphoreo, both with their own respective flaws. One of the main issues with both of these, however, is that they're targetted towards one jailbreak or another. Here, this has been wholeheartedly solved. Procursus includes 0 code-injection and hooking platforms, and can be ran fully functionally with one or more of the four main GUI package managers as of 06/04/2020. Here are a few of the main changes over other similar build systems:
* Based on Makefiles. This allows for parallel building of packages that don't depend on each other, making it much quicker to build. Not only that, but the way it is setup, adding a new package is as easy as making a new .mk file and adding a respective .control file.
* Fully open to community contribution. See [Contributing](#Contributing).
* No jailbreak-specific software, meaning it is plug and play for anyone that decides to use it in their jailbreak or project.
- To elaborate on this point, any jailbreak wishing to include Procursus need not collaborate with us to get their hooking library or package manager on the repo. They can have their own seperate repo for those jailbreak-specific tools, and we'll just keep managing the tools we provide.
* **First main jailbreak repository ever** to be fully functional with any one of the main four package managers out of the box, allowing you to remove the default.
* Includes an Obj-C implementation of the traditional firmware.sh that's not only quicker, but also creates a package for cpu subtype. (cy.cpu.arm64e, for example)
* Uses GNU tools.
* Updating most packages is as simple as changing the version number in it's .mk file and recompiling.

## Building

Building has been made to be simple, yet get the job done properly. Both macOS and Linux are supported build systems. Linux is not, however, fully supported, and not *all* packages are compilable there; MacOS is the main system you'll want to be building with. 

Supported host systems as of 06/04/2020 are iphoneos-arm64, iphoneos-arm, appletvos-arm64, watchos-arm64, and watchos-arm.

|                     Requirements                                  |
|:-----------------------------------------------------------------:|
| Xcode + Xcode Commandline Tools + Homebrew (on macOS)             |
| [An iOS toolchain, cctools-port recommended (on Linux)](LINUX.md) |
| GNU make (On macOS you'll have to run `gmake`)                    |
| GNU coreutils                                                     |
| GNU findutils                                                     |
| GNU sed                                                           |
| GNU tar                                                           |
| GNU patch                                                         |
| bash 5.0                                                          |
| openssl                                                           |
| gnupg                                                             |
| ldid with sha256 hashes (ldid from Homebrew is fine)              |
| libtoolize                                                        |
| automake                                                          |
| yacc, lex, groff                                                  |
| fakeroot                                                          |
| dpkg                                                              |
| zstd                                                              |
| ncurses 6                                                         |

| Supported commands    | Function                                                                                                                            |
|:--------------------------------------:|:-------------------------------------------------------------------------------------------------------------------|
| `make` or `make all` or `make package` | Compiles the entire Procursus suite and packs it into debian packages.                                             |
| `make (tool)`                          | Used to compile only a specified tool.                                                                             |
| `make (tool)-package`                  | Used to compile only a specified tool and pack it into a debian package.                                           |
| `make rebuild-(tool)`                  | Used to recompile only a specified tool after it's already been compiled before.                                   |
| `make rebuild-(tool)-package`          | Used to recompile only a specified tool after it's already been compiled before and pack it into a debian package. |
| `make everything`                      | Compiles the entire Procursus suite for every supported host platform and packs it into debian packages.           |
| `make clean`                           | Clean out $(BUILD_STAGE), $(BUILD_BASE), and $(BUILD_WORK).                                                        |
| `make extreme-clean`                   | Resets the entire git repository.                                                                                  |

There are very few variables you'll need to pay attention to/change to get building working well.

| Variable       | Function                                                                                                                                                             |
|:--------------:|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| MEMO_TARGET    | Can be set to any of the supported host systems. Pretty self explainatory. (Defaults to iphoneos-arm64)                                                              |
| MEMO_CFVER     | Used to set minimum *OS version to compile for. Use the CoreFoundation version that coresponds to the OS version you're compiling for. (Defaults to 1600 for iOS 13) |
| NO_PGP         | Set to 1 if you want to bypass verifying tarballs with gpg. Useful if you just want a quick build without importing everyone's public keys.                          |
| TARGET_SYSROOT | Path to your chosen iPhone SDK. (Defaults to Xcode default path on macOS and the cctools-port default path on Linux.)                                                |
| MACOSX_SYSROOT | Path to your chosen macOS SDK. (Defaults to Xcode default path on macOS and the cctools-port default path on Linux.)                                                 |
| BUILD_ROOT     | If you have this repo in one place, but want to build everything in a different place, set BUILD_ROOT to said different place. (Untested but should work fine.)      |

## Contributing and/or Issues

Contributions in the form of Issues or Pull Requests are welcome with open arms. See the [CONTRIBUTING.md](https://github.com/ProcursusTeam/Procursus/blob/master/CONTRIBUTING.md).

## Credits

Build system created by [Diatrus](https://twitter.com/Diatrus) and [Kirb](https://twitter.com/hbkirb). Built to be better by all our wonderful contributors. Made worth it by people like you!
