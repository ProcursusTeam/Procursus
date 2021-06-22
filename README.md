<p align="center">
    <h1 align="center">Procursus</h1>
    <p align="center">
        <a href="https://github.com/ProcursusTeam/Procursus/wiki">Documentation</a> •
        <a href="https://procursus.creator-spring.com/">Merchandise</a>
    </p>
</p>

A new, powerful, cross-compilation *OS boostrap. At its core, Procursus is a build-system that provides a large set of consistently up-to-date *nix tools cross compiled to work on Darwin based platforms.

The build-system is built in a manner where maintance of packages is fairly simple, helping not fall behind upstream. 

## History
At its birth, this build-system was meant to be an APT repository included in a specific jailbreak. However, that never came to pass, turning the project into a hobby.

In the iOS jailbreak scene, Procursus attempts to address an odd fragmentation problem seen over the past couple of years. Many new APT repositories have arisen from the ashes of Saurik's Telesphoreo, both with their respective flaws. One of the main issues is that each repository is targeted to one specific jailbreak.

Procursus attempts to circumvent this by excluding hooking platforms or packages that provide code-injection, providing a "plug-and-play" experience for anyone who decides to use it on their specific project.

## Features
Here are a few changes over other existing build-systems
- Based on Makefiles, allowing parallel package building that is much quicker, while also making easier to add new packages
- Fully open sourced and open to community contribution, with the usage of GNU tools. See [Contributing](#Contributing)
- No jailbreak-specific software, making it easier to implement with othe projects
- **First ever build-system** to be fully functional with one of the main 4 package managers out of the box, making easier to switch to your prefered package manager
- Better Obj-C implementation of ``firmware.sh`` that's not only quicker, but also based on CPU subtype (e.g cy.cpu.arm64e)

## Contributing
Contributions (Issues or Pull Requests) are welcome with open arms. Check out the [contribution guidelines](./CONTRIBUTING.md) before helping out.

## Credits
Build system created by [Diatrus](https://twitter.com/Diatrus) and [Kirb](https://twitter.com/hbkirb). Built better by all our wonderful contributors. Made worth it by people like you!
