ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

ZSTD_VERSION := 1.4.4
DEB_ZSTD_V   ?= $(ZSTD_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/zstd/.build_complete),)
zstd:
	@echo "Using previously built zstd."
else
zstd: setup lz4 xz
	$(SED) -i s/'($$(shell uname), Darwin)'/'($$(shell test -n),)'/ $(BUILD_WORK)/zstd/lib/Makefile
	$(MAKE) -C $(BUILD_WORK)/zstd install \
		PREFIX=/usr \
		DESTDIR=$(BUILD_STAGE)/zstd
	$(MAKE) -C $(BUILD_WORK)/zstd install \
		PREFIX=/usr \
		DESTDIR=$(BUILD_BASE)
	$(MAKE) -C $(BUILD_WORK)/zstd/contrib/pzstd install \
		PREFIX=/usr \
		DESTDIR=$(BUILD_STAGE)/zstd
	touch $(BUILD_WORK)/zstd/.build_complete
endif

zstd-package: zstd-stage
	# zstd.mk Package Structure
	rm -rf $(BUILD_DIST)/zstd
	mkdir -p $(BUILD_DIST)/zstd
	
	# zstd.mk Prep zstd
	$(FAKEROOT) cp -a $(BUILD_STAGE)/zstd/usr $(BUILD_DIST)/zstd
	
	# zstd.mk Sign
	$(call SIGN,zstd,general.xml)
	
	# zstd.mk Make .debs
	$(call PACK,zstd,DEB_ZSTD_V)
	
	# zstd.mk Build cleanup
	rm -rf $(BUILD_DIST)/zstd

.PHONY: zstd zstd-package
