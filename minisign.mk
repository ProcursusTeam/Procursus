ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += minisign
MINISIGN_VERSION := 0.9
DEB_MINISIGN_V   ?= $(MINISIGN_VERSION)

minisign-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/jedisct1/minisign/releases/download/$(MINISIGN_VERSION)/minisign-$(MINISIGN_VERSION).tar.gz
	$(call EXTRACT_TAR,minisign-$(MINISIGN_VERSION).tar.gz,minisign-$(MINISIGN_VERSION),minisign)
	mkdir -p $(BUILD_WORK)/minisign/build

ifneq ($(wildcard $(BUILD_WORK)/minisign/.build_complete),)
minisign:
	@echo "Using previously built minisign."
else
minisign: minisign-setup libsodium
	mkdir -p $(BUILD_STAGE)/minisign/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}
	cd $(BUILD_WORK)/minisign/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DSODIUM_INCLUDE_DIR:FILEPATH="$(BUILD_STAGE)/libsodium/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include" \
		-DSODIUM_LIBRARY:FILEPATH="$(BUILD_STAGE)/libsodium/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libsodium.dylib" \
		..
	+$(MAKE) -C $(BUILD_WORK)/minisign/build
	cp $(BUILD_WORK)/minisign/build/minisign $(BUILD_STAGE)/minisign/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
	cp $(BUILD_WORK)/minisign/share/man/man1/* $(BUILD_STAGE)/minisign/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	touch $(BUILD_WORK)/minisign/.build_complete
endif

minisign-package: minisign-stage
	# minisign.mk Package Structure
	rm -rf $(BUILD_DIST)/minisign

	# minisign.mk Prep minisign
	cp -a $(BUILD_STAGE)/minisign $(BUILD_DIST)

	# minisign.mk Sign
	$(call SIGN,minisign,general.xml)

	# minisign.mk Make .debs
	$(call PACK,minisign,DEB_MINISIGN_V)

	# minisign.mk Build cleanup
	rm -rf $(BUILD_DIST)/minisign

.PHONY: minisign minisign-package
