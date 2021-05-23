# Contributing to Procursus

So, you want to contribute to Procursus. That's absolutely wonderful, because community involvement is one of the main goals of this project. There are requirements present, but not too unreasonable.

## Contact Us

At the moment the best way to contact the team is to go directly through Hayden. You can either [email Hayden](mailto:me@diatr.us) or annoy him on [Twitter](https://twitter.com/Diatrus).

## Submitting Issues

Any issue with the build system, or any package on the APT repo, can be submitted as an GitHub Issue, and will be tackled as soon as possible.

While there isn't an overbearing policy on how to properly submit issues here, please be courteous and provide as much information about the situation as possible. Low-effort or low-info issues will be closed.

## Contribution Process

1. Fork Procursus and make any changes relevant to what you're trying to add/fix.
2. Create a GitHub Pull Request for your change, including information about why you're requesting the change, and where you tested building.
3. Someone from the team will review your pull request, possibly requesting changes.
4. Once the pull request is approved, it will be merged to master and the APT repository shortly updated.

### Adding a new package

Adding a new package to Procursus is very easy. For a simple package, only 2 files are needed: a .mk file for the package and a .control file for the package.
For documented templates, have a look at the [grep.mk.template](https://github.com/ProcursusTeam/Procursus/blob/master/grep.mk.template) and [grep.control](https://github.com/ProcursusTeam/Procursus/blob/master/build_info/grep.control) files.

A small list of things to keep in mind:
* Always ensure the Architecture and Maintainer fields of the control file are populated with `@DEB_ARCH@` and `@DEB_MAINTAINER@` respectively.
* If you take advantage of already-made patchfiles from an external source, download and patch similar to how it's done in [bash.mk](https://github.com/ProcursusTeam/Procursus/blob/master/bash.mk).
* If the tool you're adding only requires small edits, try and take advantage of sed in your tool's setup stage.
* **Always** confirm what you've added builds a working tool + deb file by installing and testing it on your *OS device.

### Updating a package

Package update contributions are always welcome, as we can't know everytime one of these many packages has a new version. In this case, there are two options:

* **Fork and pull request.** Most of the time, updating a package is as simple as updating the version number in the .mk file and recompiling. If you have the ability to test the new version, feel free to go this route. Otherwise...
* **Submit an issue.** Tell us that there's a new version of x package and we will do our best to update it.
