ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS   += openpam
OPENPAM_URL_V   := 38
OPENPAM_VERSION := 20190224
DEB_OPENPAM_V   ?= $(OPENPAM_VERSION)

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

openpam-setup: setup
	-wget -q -nc -O$(BUILD_SOURCE)/openpam-$(OPENPAM_VERSION).tar.gz https://www.openpam.org/downloads/$(OPENPAM_URL_V)
	$(call EXTRACT_TAR,openpam-$(OPENPAM_VERSION).tar.gz,openpam-$(OPENPAM_VERSION),openpam)

ifneq ($(wildcard $(BUILD_WORK)/openpam/.build_complete),)
openpam:
	@echo "Using previously built openpam."
else
openpam: openpam-setup libxcrypt
	cd $(BUILD_WORK)/openpam && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-modules-dir=$(MEMO_PREFX)$(MEMO_SUB_PREFIX)/lib/pam \
		--with-pam-unix
	+$(MAKE) -C $(BUILD_WORK)/openpam install \
		DESTDIR="$(BUILD_STAGE)/openpam" \
		CRYPT_LIBS="-L$(BUILD_BASE)$(MEMO_PREFX)$(MEMO_SUB_PREFIX)/lib -lcrypt"
	+$(MAKE) -C $(BUILD_WORK)/openpam install \
		DESTDIR="$(BUILD_BASE)" \
		CRYPT_LIBS="-L$(BUILD_BASE)$(MEMO_PREFX)$(MEMO_SUB_PREFIX)/lib -lcrypt"
	touch $(BUILD_WORK)/openpam/.build_complete
endif

openpam-package: openpam-stage
	# openpam.mk Package Structure
	rm -rf $(BUILD_DIST)/libpam{2,-dev}
	mkdir -p $(BUILD_DIST)/libpam{2,-dev}/$(MEMO_PREFX)$(MEMO_SUB_PREFIX)/lib

	# openpam.mk Prep libpam2
	cp -a $(BUILD_STAGE)/openpam/$(MEMO_PREFX)$(MEMO_SUB_PREFIX)/lib/libpam.2.dylib $(BUILD_DIST)/libpam2/$(MEMO_PREFX)$(MEMO_SUB_PREFIX)/lib/libpam.2.dylib

	# openpam.mk Prep libpam-dev
	cp -a $(BUILD_STAGE)/openpam/$(MEMO_PREFX)$(MEMO_SUB_PREFIX)/lib/!(libpam.2.dylib|pam) $(BUILD_DIST)/libpam-dev/$(MEMO_PREFX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/openpam/$(MEMO_PREFX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/libpam-dev/$(MEMO_PREFX)$(MEMO_SUB_PREFIX)

	# openpam.mk Sign
	$(call SIGN,libpam2,general.xml)

	# openpam.mk Make .debs
	$(call PACK,libpam2,DEB_OPENPAM_V)
	$(call PACK,libpam-dev,DEB_OPENPAM_V)

	# openpam.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpam{2,-dev}

.PHONY: openpam openpam-package

endif