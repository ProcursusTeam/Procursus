ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libpipeline
LIBPIPELINE_VERSION := 1.5.2
DEB_LIBPIPELINE_V   ?= $(LIBPIPELINE_VERSION)-1

libpipeline-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://mirrors.sarata.com/non-gnu/libpipeline/libpipeline-$(LIBPIPELINE_VERSION).tar.gz{,.asc}
	$(call PGP_VERIFY,libpipeline-$(LIBPIPELINE_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,libpipeline-$(LIBPIPELINE_VERSION).tar.gz,libpipeline-$(LIBPIPELINE_VERSION),libpipeline)

ifneq ($(wildcard $(BUILD_WORK)/libpipeline/.build_complete),)
libpipeline:
	@echo "Using previously built libpipeline."
else
libpipeline: libpipeline-setup
	cd $(BUILD_WORK)/libpipeline && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libpipeline
	+$(MAKE) -C $(BUILD_WORK)/libpipeline install \
		DESTDIR=$(BUILD_STAGE)/libpipeline
	+$(MAKE) -C $(BUILD_WORK)/libpipeline install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libpipeline/.build_complete
endif

libpipeline-package: libpipeline-stage
	# libpipeline.mk Package Structure
	rm -rf $(BUILD_DIST)/libpipeline{1,-dev}
	mkdir -p $(BUILD_DIST)/libpipeline{1,-dev}/usr/lib
	
	# libpipeline.mk Prep libpipeline1
	cp -a $(BUILD_STAGE)/libpipeline/usr/lib/libpipeline.1.dylib $(BUILD_DIST)/libpipeline1/usr/lib
	
	# libpipeline.mk Prep libpipeline-dev
	cp -a $(BUILD_STAGE)/libpipeline/usr/lib/{libpipeline.dylib,pkgconfig} $(BUILD_DIST)/libpipeline-dev/usr/lib
	cp -a $(BUILD_STAGE)/libpipeline/usr/{include,share} $(BUILD_DIST)/libpipeline-dev/usr
	
	# libpipeline.mk Sign
	$(call SIGN,libpipeline1,general.xml)
	
	# libpipeline.mk Make .debs
	$(call PACK,libpipeline1,DEB_LIBPIPELINE_V)
	$(call PACK,libpipeline-dev,DEB_LIBPIPELINE_V)
	
	# libpipeline.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpipeline{1,-dev}

.PHONY: libpipeline libpipeline-package
