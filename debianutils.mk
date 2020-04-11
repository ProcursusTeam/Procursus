ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

DEBIANUTILS_VERSION := 4.9.1
DEB_DEBIANUTILS_V   ?= $(DEBIANUTILS_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/debianutils/.build_complete),)
debianutils:
	@echo "Using previously built debianutils."
else
debianutils: setup
	cd $(BUILD_WORK)/debianutils && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking
	+$(MAKE) -C $(BUILD_WORK)/debianutils install \
		DESTDIR=$(BUILD_STAGE)/debianutils
	rm -rf $(BUILD_STAGE)/debianutils/usr/{sbin,share}
	rm -f $(BUILD_STAGE)/debianutils/usr/bin/{ischroot,which,tempfile,savelog}
	touch $(BUILD_WORK)/debianutils/.build_complete
endif

debianutils-package: debianutils-stage
	# debianutils.mk Package Structure
	rm -rf $(BUILD_DIST)/debianutils
	mkdir -p $(BUILD_DIST)/debianutils/bin
	
	# debianutils.mk Prep debianutils
	$(FAKEROOT) cp -a $(BUILD_STAGE)/debianutils/usr $(BUILD_DIST)/debianutils
	ln -s /usr/bin/run-parts $(BUILD_DIST)/debianutils/bin
	
	# debianutils.mk Sign
	$(call SIGN,debianutils,general.xml)
	
	# debianutils.mk Make .debs
	$(call PACK,debianutils,DEB_DEBIANUTILS_V)
	
	# debianutils.mk Build cleanup
	rm -rf $(BUILD_DIST)/debianutils

.PHONY: debianutils debianutils-package
