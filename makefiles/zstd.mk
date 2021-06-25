ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += zstd
ZSTD_VERSION  := 1.5.0
DEB_ZSTD_V    ?= $(ZSTD_VERSION)

zstd-setup: setup
	$(call GITHUB_ARCHIVE,facebook,zstd,$(ZSTD_VERSION),v$(ZSTD_VERSION))
	$(call EXTRACT_TAR,zstd-$(ZSTD_VERSION).tar.gz,zstd-$(ZSTD_VERSION),zstd)

ifneq ($(wildcard $(BUILD_WORK)/zstd/.build_complete),)
zstd:
	@echo "Using previously built zstd."
else
zstd: zstd-setup lz4 xz
	$(SED) -i s/'UNAME := $$(shell uname)'/'UNAME := Darwin'/ $(BUILD_WORK)/zstd/lib/Makefile
	+$(MAKE) -C $(BUILD_WORK)/zstd install \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR=$(BUILD_STAGE)/zstd
	+$(MAKE) -C $(BUILD_WORK)/zstd install \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR=$(BUILD_BASE)
	+$(MAKE) -C $(BUILD_WORK)/zstd/contrib/pzstd install \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR=$(BUILD_STAGE)/zstd
	touch $(BUILD_WORK)/zstd/.build_complete
endif

zstd-package: zstd-stage
	# zstd.mk Package Structure
	rm -rf $(BUILD_DIST)/zstd \
		$(BUILD_DIST)/libzstd{1,-dev}
	mkdir -p $(BUILD_DIST)/zstd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(BUILD_DIST)/libzstd{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# zstd.mk Prep zstd
	cp -a $(BUILD_STAGE)/zstd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/zstd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/zstd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/zstd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# zstd.mk Prep libzstd1
	cp -a $(BUILD_STAGE)/zstd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libzstd.1*.dylib $(BUILD_DIST)/libzstd1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# zstd.mk Prep libzstd-dev
	cp -a $(BUILD_STAGE)/zstd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libzstd.{a,dylib}} $(BUILD_DIST)/libzstd-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/zstd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libzstd-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# zstd.mk Sign
	$(call SIGN,zstd,general.xml)
	$(call SIGN,libzstd1,general.xml)

	# zstd.mk Make .debs
	$(call PACK,zstd,DEB_ZSTD_V)
	$(call PACK,libzstd1,DEB_ZSTD_V)
	$(call PACK,libzstd-dev,DEB_ZSTD_V)

	# zstd.mk Build cleanup
	rm -rf $(BUILD_DIST)/zstd \
		$(BUILD_DIST)/libzstd{1,-dev}

.PHONY: zstd zstd-package
