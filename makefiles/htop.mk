ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += htop
HTOP_VERSION := 3.3.0
DEB_HTOP_V   ?= $(HTOP_VERSION)

htop-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://github.com/htop-dev/htop/releases/download/$(HTOP_VERSION)/htop-$(HTOP_VERSION).tar.xz{$(comma).sha256})
	$(call CHECKSUM_VERIFY,sha256,htop-$(HTOP_VERSION).tar.xz)
	$(call EXTRACT_TAR,htop-$(HTOP_VERSION).tar.xz,htop-$(HTOP_VERSION),htop)

ifneq ($(wildcard $(BUILD_WORK)/htop/.build_complete),)
htop:
	@echo "Using previously built htop."
else
htop: htop-setup ncurses
	cd $(BUILD_WORK)/htop && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-static \
		--disable-linux-affinity \
		ac_cv_lib_ncursesw_addnwstr=yes \
		ac_cv_have_decl_IOMainPort=no
	+$(MAKE) -C $(BUILD_WORK)/htop install \
		DESTDIR="$(BUILD_STAGE)/htop"
	rm -rf $(BUILD_STAGE)/htop/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{applications,pixmaps}
	$(call AFTER_BUILD)
endif

htop-package: htop-stage
	# htop.mk Package Structure
	rm -rf $(BUILD_DIST)/htop

	# htop.mk Prep htop
	cp -a $(BUILD_STAGE)/htop $(BUILD_DIST)

	# htop.mk Sign
	$(call SIGN,htop,general.xml)

	# htop.mk Make .debs
	$(call PACK,htop,DEB_HTOP_V)

	# htop.mk Build cleanup
	rm -rf $(BUILD_DIST)/htop

.PHONY: htop htop-package
