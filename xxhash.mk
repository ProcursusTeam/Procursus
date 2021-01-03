ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS  += xxhash
XXHASH_VERSION := 0.8.0
DEB_XXHASH_V   ?= $(XXHASH_VERSION)

xxhash-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/xxhash-$(XXHASH_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/xxhash-$(XXHASH_VERSION).tar.gz \
			https://github.com/Cyan4973/xxhash/archive/v$(XXHASH_VERSION).tar.gz
	$(call EXTRACT_TAR,xxhash-$(XXHASH_VERSION).tar.gz,xxHash-$(XXHASH_VERSION),xxhash)
	$(SED) -i 's/UNAME :=/UNAME ?=/' $(BUILD_WORK)/xxhash/Makefile

ifneq ($(wildcard $(BUILD_WORK)/xxhash/.build_complete),)
xxhash:
	@echo "Using previously built xxhash."
else
xxhash: xxhash-setup
	+$(MAKE) -C $(BUILD_WORK)/xxhash \
		UNAME=Darwin \
		PREFIX=/usr
	+$(MAKE) -C $(BUILD_WORK)/xxhash install \
		UNAME=Darwin \
		PREFIX=/usr \
		DESTDIR=$(BUILD_STAGE)/xxhash
	+$(MAKE) -C $(BUILD_WORK)/xxhash install \
		UNAME=Darwin \
		PREFIX=/usr \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/xxhash/.build_complete
endif

xxhash-package: xxhash-stage
	# xxhash.mk Package Structure
	rm -rf $(BUILD_DIST)/libxxhash{0,-dev} $(BUILD_DIST)/xxhash
	mkdir -p $(BUILD_DIST)/libxxhash{0,-dev}/usr/lib \
		$(BUILD_DIST)/xxhash/usr

	# xxhash.mk Prep xxhash
	cp -a $(BUILD_STAGE)/xxhash/usr/{bin,share} $(BUILD_DIST)/xxhash/usr

	# xxhash.mk Prep libxxhash0
	cp -a $(BUILD_STAGE)/xxhash/usr/lib/libxxhash.0*.dylib $(BUILD_DIST)/libxxhash0/usr/lib

	# xxhash.mk Prep libxxhash-dev
	cp -a $(BUILD_STAGE)/xxhash/usr/lib/!(libxxhash.0*.dylib) $(BUILD_DIST)/libxxhash-dev/usr/lib
	cp -a $(BUILD_STAGE)/xxhash/usr/include $(BUILD_DIST)/libxxhash-dev/usr

	# xxhash.mk Sign
	$(call SIGN,xxhash,general.xml)
	$(call SIGN,libxxhash0,general.xml)

	# xxhash.mk Make .debs
	$(call PACK,xxhash,DEB_XXHASH_V)
	$(call PACK,libxxhash0,DEB_XXHASH_V)
	$(call PACK,libxxhash-dev,DEB_XXHASH_V)

	# xxhash.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxxhash{0,-dev} $(BUILD_DIST)/xxhash

.PHONY: xxhash xxhash-package
