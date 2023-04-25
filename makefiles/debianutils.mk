ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

STRAPPROJECTS       += debianutils
DEBIANUTILS_VERSION := 5.7
DEB_DEBIANUTILS_V   ?= $(DEBIANUTILS_VERSION)-1

debianutils-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),http://deb.debian.org/debian/pool/main/d/debianutils/debianutils_$(DEBIANUTILS_VERSION).orig.tar.gz)
	$(call EXTRACT_TAR,debianutils_$(DEBIANUTILS_VERSION).orig.tar.gz,debianutils-$(DEBIANUTILS_VERSION),debianutils)
	sed -i 's|/etc/shells|$(MEMO_PREFIX)/etc/shells|g' $(BUILD_WORK)/debianutils/add-shell
	sed -i 's|/etc/shells|$(MEMO_PREFIX)/etc/shells|g' $(BUILD_WORK)/debianutils/remove-shell

ifneq ($(wildcard $(BUILD_WORK)/debianutils/.build_complete),)
debianutils:
	@echo "Using previously built debianutils."
else
debianutils: debianutils-setup
	cd $(BUILD_WORK)/debianutils && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-dependency-tracking
	+$(MAKE) -C $(BUILD_WORK)/debianutils install \
		DESTDIR=$(BUILD_STAGE)/debianutils
	rm -f $(BUILD_STAGE)/debianutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/installkernel \
		$(BUILD_STAGE)/debianutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{ischroot,which}
	rm -rf $(BUILD_STAGE)/debianutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/{,??}/man1 \
		$(BUILD_STAGE)/debianutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/{,??}/man8/installkernel.8
	mkdir -p $(BUILD_STAGE)/debianutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/debianutils
	echo -e "# /etc/shells: valid login shells\n\
$(MEMO_PREFIX)/bin/sh\n\
$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/sh" > $(BUILD_STAGE)/debianutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/debianutils/shells
	$(call AFTER_BUILD)
endif

debianutils-package: debianutils-stage
	# debianutils.mk Package Structure
	rm -rf $(BUILD_DIST)/debianutils
	mkdir -p $(BUILD_DIST)/debianutils/$(MEMO_PREFIX)/bin

	# debianutils.mk Prep debianutils
	cp -a $(BUILD_STAGE)/debianutils $(BUILD_DIST)
ifneq ($(MEMO_SUB_PREFIX),)
	$(LN_S) $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/run-parts $(BUILD_DIST)/debianutils/$(MEMO_PREFIX)/bin
endif

	# debianutils.mk Sign
	$(call SIGN,debianutils,general.xml)

	# debianutils.mk Make .debs
	$(call PACK,debianutils,DEB_DEBIANUTILS_V)

	# debianutils.mk Build cleanup
	rm -rf $(BUILD_DIST)/debianutils

.PHONY: debianutils debianutils-package

endif
