ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += mtr
MTR_VERSION := 0.94
DEB_MTR_V   ?= $(MTR_VERSION)

mtr-setup: setup
	$(call GITHUB_ARCHIVE,traviscross,mtr,$(MTR_VERSION),v$(MTR_VERSION))
	$(call EXTRACT_TAR,mtr-$(MTR_VERSION).tar.gz,mtr-$(MTR_VERSION),mtr)

ifneq ($(wildcard $(BUILD_WORK)/mtr/.build_complete),)
mtr:
	@echo "Using previously built mtr."
else
mtr: mtr-setup ncurses jansson
	cd $(BUILD_WORK)/mtr && ./bootstrap.sh && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--without-gtk \
		--with-jansson
	+$(MAKE) -C $(BUILD_WORK)/mtr \
		LIBS="-lncursesw -lm"
	+$(MAKE) -C $(BUILD_WORK)/mtr install \
		DESTDIR=$(BUILD_STAGE)/mtr
	touch $(BUILD_WORK)/mtr/.build_complete
endif

mtr-package: mtr-stage
	# mtr.mk Package Structure
	rm -rf $(BUILD_DIST)/mtr
	mkdir -p $(BUILD_DIST)/mtr

	# mtr.mk Prep mtr
	cp -a $(BUILD_STAGE)/mtr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) $(BUILD_DIST)/mtr

	# mtr.mk Sign
	$(call SIGN,mtr,general.xml)

	# mtr.mk Make .debs
	$(call PACK,mtr,DEB_MTR_V)

	# mtr.mk Build cleanup
	rm -rf $(BUILD_DIST)/mtr

.PHONY: mtr mtr-package
