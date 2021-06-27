ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libbdplus
LIBBDPLUS_VERSION := 0.1.2
DEB_LIBBDPLUS_V   ?= $(LIBBDPLUS_VERSION)

libbdplus-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://download.videolan.org/pub/videolan/libbdplus/$(LIBBDPLUS_VERSION)/libbdplus-$(LIBBDPLUS_VERSION).tar.bz2
	$(call EXTRACT_TAR,libbdplus-$(LIBBDPLUS_VERSION).tar.bz2,libbdplus-$(LIBBDPLUS_VERSION),libbdplus)

# This makes it easier to define dependencies later
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
LIBBDPLUS_DEPS := libgcrypt gnupg libaacs
LIBBDPLUS_OPTS := --with-libaacs
else
LIBBDPLUS_DEPS := libgcrypt gnupg
LIBBDPLUS_OPTS := --without-libaacs
endif

ifneq ($(wildcard $(BUILD_WORK)/libbdplus/.build_complete),)
libbdplus:
	@echo "Using previously built libbdplus."
else
libbdplus: libbdplus-setup $(LIBBDPLUS_DEPS)
	cd $(BUILD_WORK)/libbdplus && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		$(LIBBDPLUS_OPTS) \
		--with-libgcrypt-prefix=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-gpg-error-prefix=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/libbdplus
	+$(MAKE) -C $(BUILD_WORK)/libbdplus install \
		DESTDIR=$(BUILD_STAGE)/libbdplus
	# Build this thing twice so it can be detected by other packages
	+$(MAKE) -C $(BUILD_WORK)/libbdplus install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libbdplus/.build_complete
endif

libbdplus-package: libbdplus-stage
	# libbdplus.mk Package Structure
	rm -rf $(BUILD_DIST)/libbdplus{0,-dev}
	mkdir -p $(BUILD_DIST)/libbdplus{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libbdplus.mk Prep libbdplus0
	cp -a $(BUILD_STAGE)/libbdplus/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libbdplus.0.dylib $(BUILD_DIST)/libbdplus0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libbdplus.mk Prep libbdplus-dev
	cp -a $(BUILD_STAGE)/libbdplus/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libbdplus.{a,dylib},pkgconfig} $(BUILD_DIST)/libbdplus-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libbdplus/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libbdplus-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libbdplus.mk Sign
	$(call SIGN,libbdplus0,general.xml)
	
	# libbdplus.mk Make .debs
	$(call PACK,libbdplus0,DEB_LIBBDPLUS_V)
	$(call PACK,libbdplus-dev,DEB_LIBBDPLUS_V)

	# libbdplus.mk Build cleanup
	rm -rf $(BUILD_DIST)/libbdplus0

.PHONY: libbdplus libbdplus-package
