# Contributing to Procursus
Community involvement is one of the main goals of this project, so we're glad you'd like to make contributions. There a few requirements, but they shouldn't be too unreasobable

If you're like to contact team members, there are two options
- Going through Hayden. You can either [email Hayden](mailto:me@diatr.us) or annoy him on [Twitter](https://twitter.com/Diatrus), or...
- Joining [Hayden's Discord Server](https://diatr.us/discord). This is where most team members are capable of providing answers to questions and further support.

## Submitting Issues
Any issue with the build system, or any package on the APT repo can be submitted as a Github Issue, and will be tracked as soon as possible.

While there isn't an overbaring policy on how to properly submit issues, please be courteous and provide as much information about the situation as possible **in a cohesive matter.** Low effort or low-info issues will be closed.

## Contribution Process
1. Fork the project, and make changes relevant to what you're trying to add/fix on a seperate branch
2. Create a Github Pull Request for your change in your specific branch. You should include a description of the change, why you're requesting your change to be made, and where you tested your change
3. Don't expect your changes to be merge to upstream, since a team member will review your pull request, asking for further possible changes
4. Once all further changes have been met (if any) and your changes are approved, it will be merged to upstream and the APT repository shortly updated

### Adding a New Package
Adding new packages to Procursus is fairly easy and simple. For most packages, you're likely to need 2 files, only: a ``.mk`` file and a ``.control`` file. For documented examples, take a look at the [``grep.mk`` template](./grep.mk.template) and its [control file](./grep.control).

Some things to keep in mind when adding a new package
- Always ensure that the Architecture and Maintainer fields of your control file are populated with ``@DEB_ARCH@`` and ``@DEB_MAINTAINER@``, respectively
- If you take advantage of already-made patchfiles from an external source, download them and implement them to your project. Check out it's done in [``bash.mk``](./bash.mk)
- If the package you're adding only requires a few small edits, try taking advantage of ``sed`` in your packages' setup stage
- Use designated functions found in the [documentation](https://github.com/ProcursusTeam/Procursus/wiki) to download, patch, or make other changes to your package
- **Always** test your changes on a physical device with a build of the package you're attempting to add

### Updating a Package
Package update contributions are always welcome, as not all team members are aware of new versions provided by the build-system. For this specific scenario, there's two options

- **Fork and pull request**. Most of the time, updating packages is as simple as updating the version number in the ``.mk`` file of the package and recompiling. If you have the ability to test new versions of packages, feel free to go this route (following [package addition guidelines](#adding-a-new-package)). Otherwise...
- **Submit an issue**. Tell us that there's a new version of a specific package, and we'll do our best to update it.
