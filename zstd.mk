ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

ZSTD_VERSION := 1.4.4

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

zstd-stage: zstd
	# zstd.mk Package Structure
	rm -rf $(BUILD_DIST)/zstd
	mkdir -p $(BUILD_DIST)/zstd
	
	# zstd.mk Prep zstd
	cp -ar $(BUILD_STAGE)/zstd/usr $(BUILD_DIST)/zstd
	
	# zstd.mk Sign
	find $(BUILD_DIST)/zstd -type f -exec $(LDID) -S$(BUILD_INFO)/general.xml {} \; &> /dev/null
	find $(BUILD_DIST)/zstd -name .ldid* -exec rm -f {} \; &> /dev/null
	
	# zstd.mk Make .debs
	mkdir -p $(BUILD_DIST)/zstd/DEBIAN
	cp $(BUILD_INFO)/zstd.control $(BUILD_DIST)/zstd/DEBIAN/control
	$(SED) -i ':a; s/$$ZSTD_VERSION/$(ZSTD_VERSION)/g; ta' $(BUILD_DIST)/zstd/DEBIAN/control
	$(SED) -i ':a; s/$$DEB_MAINTAINER/$(DEB_MAINTAINER)/g; ta' $(BUILD_DIST)/zstd/DEBIAN/control
	$(SED) -i ':a; s/$$DEB_ARCH/$(DEB_ARCH)/g; ta' $(BUILD_DIST)/zstd/DEBIAN/control
	$(DPKG_DEB) -b $(BUILD_DIST)/zstd $(BUILD_DIST)/zstd_$(ZSTD_VERSION)_$(DEB_ARCH).deb
	
	# zstd.mk Build cleanup
	rm -rf $(BUILD_DIST)/zstd

.PHONY: zstd zstd-stage
