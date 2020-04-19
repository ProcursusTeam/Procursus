ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libpipeline
DOWNLOAD            += https://mirrors.sarata.com/non-gnu/libpipeline/libpipeline-$(LIBPIPELINE_VERSION).tar.gz{,.asc}
LIBPIPELINE_VERSION := 1.5.2
DEB_LIBPIPELINE_V   ?= $(LIBPIPELINE_VERSION)

libpipeline-setup: setup
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
	rm -rf $(BUILD_DIST)/libpipeline
	mkdir -p $(BUILD_DIST)/libpipeline
	
	# libpipeline.mk Prep libpipeline
	cp -a $(BUILD_STAGE)/libpipeline/usr $(BUILD_DIST)/libpipeline
	
	# libpipeline.mk Sign
	$(call SIGN,libpipeline,general.xml)
	
	# libpipeline.mk Make .debs
	$(call PACK,libpipeline,DEB_LIBPIPELINE_V)
	
	# libpipeline.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpipeline

.PHONY: libpipeline libpipeline-package
