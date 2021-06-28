ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += most
MOST_VERSION := 5.1.0
DEB_MOST_V   ?= $(MOST_VERSION)

most-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.jedsoft.org/releases/most/most-$(MOST_VERSION).tar.gz{,.asc}
	$(call PGP_VERIFY,most-$(MOST_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,most-$(MOST_VERSION).tar.gz,most-$(MOST_VERSION),most)

ifneq ($(wildcard $(BUILD_WORK)/most/.build_complete),)
most:
	@echo "Using previously built most."
else
most: most-setup slang2
	cd $(BUILD_WORK)/most && ./configure \
			$(DEFAULT_CONFIGURE_FLAGS) \
			--with-slang=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	mkdir -p $(BUILD_WORK)/most/src/objs
	$(SED) -i '/slangversion:/{n;d}' $(BUILD_WORK)/most/src/Makefile
	+$(MAKE) -C $(BUILD_WORK)/most
	+$(MAKE) -C $(BUILD_WORK)/most install \
		DESTDIR=$(BUILD_STAGE)/most prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	touch $(BUILD_WORK)/most/.build_complete
endif

most-package: most-stage
	# most.mk Package Structure
	rm -rf $(BUILD_DIST)/most

	# most.mk Prep most-utils
	cp -a $(BUILD_STAGE)/most $(BUILD_DIST)

	# most.mk Sign
	$(call SIGN,most,general.xml)

	# most.mk Make .debs
	$(call PACK,most,DEB_MOST_V)

	# most.mk Build cleanup
	rm -rf $(BUILD_DIST)/most

.PHONY: most most-package
