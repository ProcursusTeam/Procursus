ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += zstd
ZSTD_VERSION  := 1.4.7
DEB_ZSTD_V    ?= $(ZSTD_VERSION)

zstd-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/zstd-$(ZSTD_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/zstd-$(ZSTD_VERSION).tar.gz \
			https://github.com/facebook/zstd/archive/v$(ZSTD_VERSION).tar.gz
	$(call EXTRACT_TAR,zstd-$(ZSTD_VERSION).tar.gz,zstd-$(ZSTD_VERSION),zstd)

ifneq ($(wildcard $(BUILD_WORK)/zstd/.build_complete),)
zstd:
	@echo "Using previously built zstd."
else
zstd: zstd-setup lz4 xz
	$(SED) -i s/'UNAME := $$(shell uname)'/'UNAME := Darwin'/ $(BUILD_WORK)/zstd/lib/Makefile
	+$(MAKE) -C $(BUILD_WORK)/zstd install \
		PREFIX=/usr \
		DESTDIR=$(BUILD_STAGE)/zstd
	+$(MAKE) -C $(BUILD_WORK)/zstd install \
		PREFIX=/usr \
		DESTDIR=$(BUILD_BASE)
	+$(MAKE) -C $(BUILD_WORK)/zstd/contrib/pzstd install \
		PREFIX=/usr \
		DESTDIR=$(BUILD_STAGE)/zstd
	touch $(BUILD_WORK)/zstd/.build_complete
endif

zstd-package: zstd-stage
	# zstd.mk Package Structure
	rm -rf $(BUILD_DIST)/zstd \
		$(BUILD_DIST)/libzstd{1,-dev}
	mkdir -p $(BUILD_DIST)/zstd/usr \
		$(BUILD_DIST)/libzstd{1,-dev}/usr/lib
	
	# zstd.mk Prep zstd
	cp -a $(BUILD_STAGE)/zstd/usr/bin $(BUILD_DIST)/zstd/usr
	cp -a $(BUILD_STAGE)/zstd/usr/share $(BUILD_DIST)/zstd/usr
	
	# zstd.mk Prep libzstd1
	cp -a $(BUILD_STAGE)/zstd/usr/lib/libzstd.1*.dylib $(BUILD_DIST)/libzstd1/usr/lib
	
	# zstd.mk Prep libzstd-dev
	cp -a $(BUILD_STAGE)/zstd/usr/lib/{pkgconfig,libzstd.{a,dylib}} $(BUILD_DIST)/libzstd-dev/usr/lib
	cp -a $(BUILD_STAGE)/zstd/usr/include $(BUILD_DIST)/libzstd-dev/usr
	
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
