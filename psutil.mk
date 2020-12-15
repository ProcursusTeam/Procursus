 
ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += psutil                                                                  ### In this case, STRAPPROJECTS is the variable used. Most tools are unneeded in the bootstrap and would instead the SUBPROJECTS variable.
PSUTIL_VERSION  := 5.7.3                                                                   ### For most tools, all it takes to update is changing this version number and recompiling the package.
DEB_PSUTIL_V    ?= $(PSUTIL_VERSION)-1                                                       ### This is the version number put into the package's control file. Just in case we need to increment the version before a new one is released by the maintainers. See it used on line 48.

psutil-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/psutil-$(PSUTIL_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/psutil-$(PSUTIL_VERSION).tar.gz \
			https://github.com/google/psutil/archive/v$(PSUTIL_VERSION).tar.gz
	$(call EXTRACT_TAR,psutil-$(PSUTIL_VERSION).tar.gz,psutil-$(PSUTIL_VERSION),psutil)          ### Extracts tarball.

ifneq ($(wildcard $(BUILD_WORK)/psutil/.build_complete),)                                ### On a successful build of a tool, a .build_complete file should be made in it's build work directory. (See line 33) This prevents it from being unnecessarily built again. You can rebuild a package by running `make rebuild-(tool)`.
psutil:
	@echo "Using previously built psutil."
else
psutil: psutil-setup                                                                   ### The (tool) target is where the actual building happens.
	cd $(BUILD_WORK)/psutil && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking \
		--disable-nls \
		--with-packager="$(DEB_MAINTAINER)"
	+$(MAKE) -C $(BUILD_WORK)/psutil
	+$(MAKE) -C $(BUILD_WORK)/psutil install \
		DESTDIR=$(BUILD_STAGE)/psutil                                                    ### On the completion of a successful build, always install files to a package's own directory in $(BUILD_STAGE).
	### If what you're building includes a shared library, also install to $(BUILD_BASE)
	### +$(MAKE) -C $(BUILD_WORK)/psutil install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/psutil/.build_complete                                           ### Explained on line 16.
endif

psutil-package: psutil-stage                                                               ### (tool)-stage should always be required by the (tool)-package target.
	# psutil.mk Package Structure
	rm -rf $(BUILD_DIST)/psutil
	mkdir -p $(BUILD_DIST)/psutil
	
	# psutil.mk Prep psutil
	cp -a $(BUILD_STAGE)/psutil/usr $(BUILD_DIST)/psutil
	
	# psutil.mk Sign
	$(call SIGN,psutil,general.xml)                                                      ### This signs the package with ldid. If your tool needs different entitlements than usual, place it's own entitlements file in build_info, and reflect said file here.
	
	# psutil.mk Make .debs
	$(call PACK,psutil,DEB_PSUTIL_V)                                                       ### This is where the deb is packaged, DEB__V being the variable made for the deb version on line 8.
	
	# psutil.mk Build cleanup
	rm -rf $(BUILD_DIST)/psutil

.PHONY: psutil psutil-package
