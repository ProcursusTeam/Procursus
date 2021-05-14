ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
SUBPROJECTS     += libaacs
LIBAACS_VERSION := 0.11.0
DEB_LIBAACS_V   ?= $(LIBAACS_VERSION)

libaacs-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://download.videolan.org/pub/videolan/libaacs/$(LIBAACS_VERSION)/libaacs-$(LIBAACS_VERSION).tar.bz2
	$(call EXTRACT_TAR,libaacs-$(LIBAACS_VERSION).tar.bz2,libaacs-$(LIBAACS_VERSION),libaacs)
	$(SED) -i 's/-framework,Cocoa,/-framework,CoreFoundation,/g' $(BUILD_WORK)/libaacs/configure.ac

ifneq ($(wildcard $(BUILD_WORK)/libaacs/.build_complete),)
libaacs:
	@echo "Using previously built libaacs."
else
libaacs: libgcrypt gnupg libaacs-setup
	cd $(BUILD_WORK)/libaacs && ./bootstrap && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
	--with-libgcrypt-prefix=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
	--with-libgpg-error-prefix=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/libaacs
	+$(MAKE) -C $(BUILD_WORK)/libaacs install \
		DESTDIR=$(BUILD_STAGE)/libaacs
	+$(MAKE) -C $(BUILD_WORK)/libaacs install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libaacs/.build_complete
endif

libaacs-package: libaacs-stage
	# libaacs.mk Package Structure
	rm -rf $(BUILD_DIST)/libaacs
	mkdir -p $(BUILD_DIST)/libaacs{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libaacs.mk Prep libaacs0
	cp -a $(BUILD_STAGE)/libaacs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libaacs.0.dylib $(BUILD_DIST)/libaacs0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libaacs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/libaacs0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libaacs.mk Prep libaacs-dev
	cp -a $(BUILD_STAGE)/libaacs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libaacs.{a,la,dylib},pkgconfig} $(BUILD_DIST)/libaacs-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libaacs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libaacs-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# libaacs.mk Sign
	$(call SIGN,libaacs0,general.xml)
	
	# libaacs.mk Make .debs
	$(call PACK,libaacs0,DEB_LIBAACS_V)
	$(call PACK,libaacs-dev,DEB_LIBAACS_V)
	
	# libaacs.mk Build cleanup
	rm -rf $(BUILD_DIST)/libaacs{0,-dev}

.PHONY: libaacs libaacs-package
endif
