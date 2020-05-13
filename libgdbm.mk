ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libgdbm
DOWNLOAD        += https://ftp.gnu.org/gnu/gdbm/gdbm-$(LIBGDBM_VERSION).tar.gz{,.sig}
LIBGDBM_VERSION := 1.18.1
DEB_LIBGDBM_V   ?= $(LIBGDBM_VERSION)

libgdbm-setup: setup
	$(call PGP_VERIFY,gdbm-$(LIBGDBM_VERSION).tar.gz)
	$(call EXTRACT_TAR,gdbm-$(LIBGDBM_VERSION).tar.gz,gdbm-$(LIBGDBM_VERSION),libgdbm)

ifneq ($(wildcard $(BUILD_WORK)/libgdbm/.build_complete),)
libgdbm:
	@echo "Using previously built libgdbm."
else
libgdbm: libgdbm-setup readline gettext
	cd $(BUILD_WORK)/libgdbm && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libgdbm
	+$(MAKE) -C $(BUILD_WORK)/libgdbm install \
		DESTDIR=$(BUILD_STAGE)/libgdbm
	+$(MAKE) -C $(BUILD_WORK)/libgdbm install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libgdbm/.build_complete
endif

libgdbm-package: libgdbm-stage
	# libgdbm.mk Package Structure
	rm -rf $(BUILD_DIST)/libgdbm
	mkdir -p $(BUILD_DIST)/libgdbm
	
	# libgdbm.mk Prep libgdbm
	cp -a $(BUILD_STAGE)/libgdbm/usr $(BUILD_DIST)/libgdbm
	
	# libgdbm.mk Sign
	$(call SIGN,libgdbm,general.xml)
	
	# libgdbm.mk Make .debs
	$(call PACK,libgdbm,DEB_LIBGDBM_V)
	
	# libgdbm.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgdbm

.PHONY: libgdbm libgdbm-package
