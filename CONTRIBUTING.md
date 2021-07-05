# Contributing to Procursus
Community involvement is one of the main goals of this project, so we're glad you'd like to make a contribution. There are a few requirements, but they shouldn't be too unreasonable.

If you have any questions, or would like to contact team members, you can either
- Email [Hayden](mailto:me@diatr.us) about your issue/concern (or annoy him on [Twitter](https://twitter.com/Diatrus)), or..
- Join [Hayden's Discord Server](https://diatr.us/discord), where most team members are capable of providing support and answering questions

## Submitting Issues
Any issue with the build system or a package on the APT repo can be submitted as a Github issue, and will be tracked as soon as possible.

While there isn't an overbearing policy on how to properly submit issues, please be courteous and provide as much information about the situation as possible **in a cohesive matter.** Low effort or low info issues will be closed and marked as invalid.

## Contribution Process
1. Fork the project and make changes relevant to what you're trying to add/fix — do this in a seperate branch in your fork
2. Test your changes made on a **physical** device. If you're adding or updating a package, test your changes with a build of the package you added/updated
3. Create a Pull Request for your changes in your specific branch — include a description of the change and where you tested your change

Don't expect your changes to be merged and pushed to upstream immediately — your changes will be reviewed by a team member (or Hayden), providing suggested changes which must be met.

Once all further changes have been met (if any) and your changes are approved, they will be merged into upstream. The APT repository will shortly update showcasing your changes.

### Adding a New Package
Adding new packages to Procursus is fairly easy and simple. For most packages, you're likely to need 2 files
- A ``.mk`` file, that builds the package, and..
- A ``.control`` file, which contains info about your package

A way to get these files is by using the [``new_package.sh``](./build_tools/new_package.sh) script (in ``build_tools``), which can generate packages for some major platforms/build systems, like Python and Perl.

Some things to keep in mind when adding a new package
- Always ensure that the Architecture and Maintainer fields of your control file are populated with ``@DEB_ARCH@`` and ``@DEB_MAINTAINER@``, respectively
- If you take advantage of already-made patchfiles from an external source, download them and implement them to your project. Check out how it's done in [``bash.mk``](./makefiles/bash.mk)
- If the package you're adding only requires a few small edits, try taking advantage of ``sed`` in your package's setup stage
- Use designated functions found in the [documentation](https://github.com/ProcursusTeam/Procursus/wiki) to download, patch, or make other changes to your package

### Updating a Package
Package update contributions are always welcome, as not all team members are aware of new versions provided by the build-system. For this specific scenario, there's two options

- **Fork and pull request**. Most of the time, updating packages is as simple as updating the version number in the ``.mk`` file of the package and recompiling. If you have the ability to test new versions of packages, feel free to go this route (following [package addition guidelines](#adding-a-new-package)). Otherwise...
- **Submit an issue**. Tell us that there's a new version of a specific package, and we'll do our best to update it
