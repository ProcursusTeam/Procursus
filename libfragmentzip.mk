ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS            += libfragmentzip
LIBFRAGMENTZIP_VERSION := 60
DEB_LIBFRAGMENTZIP_V   ?= $(LIBFRAGMENTZIP_VERSION)

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
		--prefix=/usr 
	+$(MAKE) -C $(BUILD_WORK)/libfragmentzip
	+$(MAKE) -C $(BUILD_WORK)/libfragmentzip install \
		DESTDIR="$(BUILD_STAGE)/libfragmentzip"
	+$(MAKE) -C $(BUILD_WORK)/libfragmentzip install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libfragmentzip/.build_complete
endif

libfragmentzip-package: libfragmentzip-stage
	# libfragmentzip.mk Package Structure
	rm -rf $(BUILD_DIST)/libfragmentzip
	mkdir -p $(BUILD_DIST)/libfragmentzip
	
	# libfragmentzip.mk Prep libfragmentzip
	cp -a $(BUILD_STAGE)/libfragmentzip/usr $(BUILD_DIST)/libfragmentzip
	
	# libfragmentzip.mk Sign
	$(call SIGN,libfragmentzip,general.xml)
	
	# libfragmentzip.mk Make .debs
	$(call PACK,libfragmentzip,DEB_LIBFRAGMENTZIP_V)
	
	# libfragmentzip.mk Build cleanup
	rm -rf $(BUILD_DIST)/libfragmentzip

.PHONY: libfragmentzip libfragmentzip-package
