ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += lz4
LZ4_VERSION   := 1.9.2
DEB_LZ4_V     ?= $(LZ4_VERSION)-2

lz4-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/lz4/lz4/archive/v$(LZ4_VERSION).tar.gz
	$(call EXTRACT_TAR,v$(LZ4_VERSION).tar.gz,lz4-$(LZ4_VERSION),lz4)

ifneq ($(wildcard $(BUILD_WORK)/lz4/.build_complete),)
lz4:
	@echo "Using previously built lz4."
else
lz4: lz4-setup
	$(SED) -i 's/\<ln -s\>/ln -sf/g' $(BUILD_WORK)/lz4/Makefile.inc
	TARGET_OS=Darwin \
		$(MAKE) -C $(BUILD_WORK)/lz4 install \
		PREFIX=/usr \
		DESTDIR=$(BUILD_STAGE)/lz4 \
		CFLAGS="$(CFLAGS)"
	TARGET_OS=Darwin \
		$(MAKE) -C $(BUILD_WORK)/lz4 install \
		PREFIX=/usr \
		DESTDIR=$(BUILD_BASE) \
		CFLAGS="$(CFLAGS)"
	touch $(BUILD_WORK)/lz4/.build_complete
endif

lz4-package: lz4-stage
	# lz4.mk Package Structure
	rm -rf $(BUILD_DIST)/liblz4-{1,dev} \
		$(BUILD_DIST)/lz4
	mkdir -p $(BUILD_DIST)/liblz4-{1,dev}/usr/lib \
		$(BUILD_DIST)/lz4/usr
	
	# lz4.mk Prep lz4
	cp -a $(BUILD_STAGE)/lz4/usr/bin $(BUILD_DIST)/lz4/usr
	cp -a $(BUILD_STAGE)/lz4/usr/share $(BUILD_DIST)/lz4/usr
	
	# lz4.mk Prep liblz4
	cp -a $(BUILD_STAGE)/lz4/usr/lib/liblz4.{1,1.9.2}.dylib $(BUILD_DIST)/liblz4-1/usr/lib
	
	# lz4
	cp -a $(BUILD_STAGE)/lz4/usr/lib/{liblz4.{a,dylib},pkgconfig} $(BUILD_DIST)/liblz4-dev/usr/lib
	cp -a $(BUILD_STAGE)/lz4/usr/include $(BUILD_DIST)/liblz4-dev/usr
	
	# lz4.mk Sign
	$(call SIGN,lz4,general.xml)
	$(call SIGN,liblz4-1,general.xml)
	
	# lz4.mk Make .debs
	$(call PACK,lz4,DEB_LZ4_V)
	$(call PACK,liblz4-1,DEB_LZ4_V)
	$(call PACK,liblz4-dev,DEB_LZ4_V)
	
	# lz4.mk Build cleanup
	rm -rf $(BUILD_DIST)/liblz4-{1,dev} \
		$(BUILD_DIST)/lz4

.PHONY: lz4 lz4-package
