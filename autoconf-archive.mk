ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS              += autoconf-archive
AUTOCONF-ARCHIVE_VERSION := 2021.02.19
DEB_AUTOCONF-ARCHIVE_V   ?= $(AUTOCONF-ARCHIVE_VERSION)

autoconf-archive-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://mirrors.ocf.berkeley.edu/gnu/autoconf-archive/autoconf-archive-$(AUTOCONF-ARCHIVE_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,autoconf-archive-$(AUTOCONF-ARCHIVE_VERSION).tar.xz)
	$(call EXTRACT_TAR,autoconf-archive-$(AUTOCONF-ARCHIVE_VERSION).tar.xz,autoconf-archive-$(AUTOCONF-ARCHIVE_VERSION),autoconf-archive)

ifneq ($(wildcard $(BUILD_WORK)/autoconf-archive/.build_complete),)
autoconf-archive:
	@echo "Using previously built autoconf-archive."
else
autoconf-archive: autoconf-archive-setup
	cd $(BUILD_WORK)/autoconf-archive && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/autoconf-archive
	+$(MAKE) -C $(BUILD_WORK)/autoconf-archive install \
		DESTDIR=$(BUILD_STAGE)/autoconf-archive
	touch $(BUILD_WORK)/autoconf-archive/.build_complete
endif
autoconf-archive-package: autoconf-archive-stage
	# autoconf-archive.mk Package Structure
	rm -rf $(BUILD_DIST)/autoconf-archive

	# autoconf-archive.mk Prep autoconf-archive
	cp -a $(BUILD_STAGE)/autoconf-archive $(BUILD_DIST)

	# autoconf-archive.mk Make .debs
	$(call PACK,autoconf-archive,DEB_AUTOCONF-ARCHIVE_V)

	# autoconf-archive.mk Build cleanup
	rm -rf $(BUILD_DIST)/autoconf-archive

.PHONY: autoconf-archive autoconf-archive-package
