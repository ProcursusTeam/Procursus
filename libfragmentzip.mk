ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS            += libfragmentzip
LIBFRAGMENTZIP_VERSION := 60
DEB_LIBFRAGMENTZIP_V   ?= $(LIBFRAGMENTZIP_VERSION)-1

libfragmentzip-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/tihmstar/libfragmentzip/archive/$(LIBFRAGMENTZIP_VERSION).tar.gz
	$(call EXTRACT_TAR,$(LIBFRAGMENTZIP_VERSION).tar.gz,libfragmentzip-$(LIBFRAGMENTZIP_VERSION),libfragmentzip)

ifneq ($(wildcard $(BUILD_WORK)/libfragmentzip/.build_complete),)
libfragmentzip:
	@echo "Using previously built libfragmentzip."
else
libfragmentzip: libfragmentzip-setup libgeneral libzip curl
	cd $(BUILD_WORK)/libfragmentzip && ./autogen.sh \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) 
	+$(MAKE) -C $(BUILD_WORK)/libfragmentzip
	+$(MAKE) -C $(BUILD_WORK)/libfragmentzip install \
		DESTDIR="$(BUILD_STAGE)/libfragmentzip"
	+$(MAKE) -C $(BUILD_WORK)/libfragmentzip install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libfragmentzip/.build_complete
endif

libfragmentzip-package: libfragmentzip-stage
	# libfragmentzip.mk Package Structure
	rm -rf $(BUILD_DIST)/libfragmentzip{0,-dev}
	mkdir -p $(BUILD_DIST)/libfragmentzip{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libfragmentzip.mk Prep libfragmentzip0
	cp -a $(BUILD_STAGE)/libfragmentzip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libfragmentzip.0.dylib $(BUILD_DIST)/libfragmentzip0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libfragmentzip.mk Prep libfragmentzip-dev
	cp -a $(BUILD_STAGE)/libfragmentzip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libfragmentzip.0.dylib) $(BUILD_DIST)/libfragmentzip-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libfragmentzip/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libfragmentzip-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# libfragmentzip.mk Sign
	$(call SIGN,libfragmentzip0,general.xml)
	
	# libfragmentzip.mk Make .debs
	$(call PACK,libfragmentzip0,DEB_LIBFRAGMENTZIP_V)
	$(call PACK,libfragmentzip-dev,DEB_LIBFRAGMENTZIP_V)
	
	# libfragmentzip.mk Build cleanup
	rm -rf $(BUILD_DIST)/libfragmentzip{0,-dev}

.PHONY: libfragmentzip libfragmentzip-package
