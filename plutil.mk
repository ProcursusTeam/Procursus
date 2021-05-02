ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += plutil
PLUTIL_VERSION  := 0.2.2
DEB_PLUTIL_V    ?= $(PLUTIL_VERSION)

plutil-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/Diatrus/plutil/releases/download/v$(PLUTIL_VERSION)/plutil-$(PLUTIL_VERSION).tar.xz
	$(call EXTRACT_TAR,plutil-$(PLUTIL_VERSION).tar.xz,plutil-$(PLUTIL_VERSION),plutil)

ifneq ($(wildcard $(BUILD_WORK)/plutil/.build_complete),)
plutil:
	@echo "Using previously built plutil."
else
plutil: plutil-setup
	+$(MAKE) -C $(BUILD_WORK)/plutil install \
		CC="$(CC)" \
		DESTDIR="$(BUILD_STAGE)/plutil/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"
	touch $(BUILD_WORK)/plutil/.build_complete
endif

plutil-package: plutil-stage
	# plutil.mk Package Structure
	rm -rf $(BUILD_DIST)/plutil
	mkdir -p $(BUILD_DIST)/plutil

	# plutil.mk Prep plutil
	cp -a $(BUILD_STAGE)/plutil/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) $(BUILD_DIST)/plutil

	# plutil.mk Sign
	$(call SIGN,plutil,general.xml)

	# plutil.mk Make .debs
	$(call PACK,plutil,DEB_PLUTIL_V)

	# plutil.mk Build cleanup
	rm -rf $(BUILD_DIST)/plutil

.PHONY: plutil plutil-package
