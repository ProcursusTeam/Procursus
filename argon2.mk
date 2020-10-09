ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += argon2
ARGON2_VERSION := 20190702
DEB_ARGON2_V   ?= 0~$(ARGON2_VERSION)

argon2-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/argon2-$(ARGON2_VERSION).tar.gz" ] && wget -q -nc -O$(BUILD_SOURCE)/argon2-$(ARGON2_VERSION).tar.gz https://github.com/P-H-C/phc-winner-argon2/archive/$(ARGON2_VERSION).tar.gz
	$(call EXTRACT_TAR,argon2-$(ARGON2_VERSION).tar.gz,phc-winner-argon2-$(ARGON2_VERSION),argon2)
	$(call DO_PATCH,argon2,argon2,-p1)

ifneq ($(wildcard $(BUILD_WORK)/argon2/.build_complete),)
argon2:
	@echo "Using previously built argon2."
else
argon2: argon2-setup
	+$(MAKE) -C $(BUILD_WORK)/argon2 install \
		DESTDIR=$(BUILD_STAGE)/argon2 \
		KERNEL_NAME="Darwin" \
		OPTTARGET="aarch64"
	rm -f $(BUILD_BASE)/usr/lib/libargon2.dylib
	+$(MAKE) -C $(BUILD_WORK)/argon2 install \
		DESTDIR=$(BUILD_BASE) \
		KERNEL_NAME="Darwin" \
		OPTTARGET="aarch64"
	touch $(BUILD_WORK)/argon2/.build_complete
endif

argon2-package: argon2-stage
	# argon2.mk Package Structure
	rm -rf $(BUILD_DIST)/libargon2-{1,dev} $(BUILD_DIST)/argon2
	mkdir -p $(BUILD_DIST)/libargon2-{1,dev}/usr/lib \
		$(BUILD_DIST)/argon2/usr
	
	# argon2.mk Prep libargon2-1
	cp -a $(BUILD_STAGE)/argon2/usr/lib/libargon2.1.dylib $(BUILD_DIST)/libargon2-1/usr/lib

	# argon2.mk Prep libargon2-dev
	cp -a $(BUILD_STAGE)/argon2/usr/include $(BUILD_DIST)/libargon2-dev/usr
	cp -a $(BUILD_STAGE)/argon2/usr/lib/{libargon2.{a,dylib},pkgconfig} $(BUILD_DIST)/libargon2-dev/usr/lib

	# argon2.mk Prep argon2
	cp -a $(BUILD_STAGE)/argon2/usr/bin $(BUILD_DIST)/argon2/usr
	
	# argon2.mk Sign
	$(call SIGN,libargon2-1,general.xml)
	$(call SIGN,argon2,general.xml)
	
	# argon2.mk Make .debs
	$(call PACK,libargon2-1,DEB_ARGON2_V)
	$(call PACK,libargon2-dev,DEB_ARGON2_V)
	$(call PACK,argon2,DEB_ARGON2_V)
	
	# argon2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libargon2-{1,dev} $(BUILD_DIST)/argon2

.PHONY: argon2 argon2-package
