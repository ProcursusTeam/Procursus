This specific page documents functions used in all Procursus packages, each having its purpose. These functions can be found within the ``Makefile``.

The table below showcases current functions used across all Procursus projects.

| Function | Description |
|----------|-------------|
| ``SIGN`` | Recursively signs Mach-O libraries and binaries with ``ldid`` or ``codesign``. |
| ``PACK`` | Creates a Debian package with ``dpkg`` or ``dm.pl`` for the given project. |
| ``EXTRACT_TAR`` | Extracts a tarball from ``BUILD_SOURCE`` to ``BUILD_WORK``. Use this to extract a downloaded tarball. |
| ``GITHUB_ARCHIVE`` | Downloads a Github archive from given paramters. This function makes it easier to download project files from Github. |
| ``GIT_CLONE`` | Much like ``GITHUB_ARCHIVE``, but clones the specified repo using ``git``. |

## ``GITHUB_ARCHIVE``
This function is used to download a Github archive of a specific project. The following table showcases documentation for parameters used by this function

| Index | Status | Description |
|-------|--------|-------------|
| 1 | Required | Github user or organization from which the project comes from |
| 2 | Required | Project/repository name from which an archive will be made from. This is also used as the filename for the downloaded tarball unless paramater 5 is given |
| 3 | Required | Specific paramter which appends the given version number to the downloaded tarball filename |
| 4 | Required | Release tag, branch name, or git hash from which an archive will be made from |
| 5 | Not required | Specifies a different name for the downloaded tarball. Use this if the tarball name is different than the repository name specified in parameter 3 |

There many ways in which you can manipulate this specific function in your Makefile. The examples below showcase most instances
#### Tag example
```makefile
APPUNINST_VERSION := 1.0.0

$(call GITHUB_ARCHIVE,quiprr,appuninst,$(APPUNINST_VERSION),v$(APPUNINST_VERSION))

# URL:     https://github.com/quiprr/appuninst/archive/v1.0.0.tar.gz
# tarball: $(BUILD_SOURCE)/appuninst-1.0.0.tar.gz
```

#### Commit example
```makefile
ZBRFIRMWARE_COMMIT  := e4b7cf07bb491ecdbf08519063d7a9fa16aefdb8

$(call GITHUB_ARCHIVE,zbrateam,Firmware,$(ZBRFIRMWARE_COMMIT),$(ZBRFIRMWARE_COMMIT))

# URL:     https://github.com/zbrateam/Firmware/archive/e4b7cf07bb491ecdbf08519063d7a9fa16aefdb8.tar.gz
# tarball: $(BUILD_SOURCE)/Firmware-e4b7cf07bb491ecdbf08519063d7a9fa16aefdb8.tar.gz
```

#### Branch example
```makefile
$(call GITHUB_ARCHIVE,tihmstar,jssy,master,master)

# URL:     https://github.com/tihmstar/jssy/archive/master.tar.gz
# tarball: $(BUILD_SOURCE)/jssy-master.tar.gz
```

#### Different tarball name example
```makefile
GHOSTBIN_COMMIT   := 0e0a3b72c3379e51bf03fe676af3a74a01239a47

$(call GITHUB_ARCHIVE,DHowett,spectre,v$(GHOSTBIN_COMMIT),$(GHOSTBIN_COMMIT),ghostbin)

# URL:     https://github.com/DHowett/spectre/archive/0e0a3b72c3379e51bf03fe676af3a74a01239a47.tar.gz
# tarball: $(BUILD_SOURCE)/ghostbin-v0e0a3b72c3379e51bf03fe676af3a74a01239a47.tar.gz
```

## ``GIT_CLONE``
Much like ``GITHUB_ARCHIVE``, this function allows you to download a project more easily. However, this extends support for projects that are outside of Github. Below is more documentation about specific paramters.

| Index | Status | Description |
|-------|--------|-------------|
| 1 | Required | Link of the project that should be cloned |
| 2 | Required | Branch that will be checkout upon cloning |
| 3 | Required | Folder name that the project will be cloned to. This folder will always default to being inside ``BUILD_WORK`` |

#### Example
```makefile
AOM_VERSION := 3.1.0

# Files are saved in BUILD_WORK/aom
$(call GIT_CLONE,https://aomedia.googlesource.com/aom.git,v$(AOM_VERSION),aom) 
```
