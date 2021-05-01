ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

STRAPPROJECTS   += openpam
OPENPAM_URL_V   := 38
OPENPAM_VERSION := 20190224
DEB_OPENPAM_V   ?= $(OPENPAM_VERSION)

openpam-setup: setup
	-wget -q -nc -O $(BUILD_SOURCE)/openpam-$(OPENPAM_VERSION).tar.gz https://www.openpam.org/downloads/$(OPENPAM_URL_V)
	$(call EXTRACT_TAR,openpam-$(OPENPAM_VERSION).tar.gz,openpam-$(OPENPAM_VERSION),openpam)
	$(call DO_PATCH,openpam,openpam,-p0)
	# The below line is only if you need to debug PAM with detailed syslogs.
	# $(SED) -i -e 's/openpam_debug = 0/openpam_debug = 1/' -e 's/priority = LOG_DEBUG/priority = LOG_ERR/' $(BUILD_WORK)/openpam/lib/libpam/openpam_log.c

###
# For some reason here, libSystem's crypt() really likes being dominant. Static link to fix the issue!
# TODO: Add pam_sm_chauthtok() to pam_unix.so
###

ifneq ($(wildcard $(BUILD_WORK)/openpam/.build_complete),)
openpam:
	@echo "Using previously built openpam."
else
openpam: openpam-setup libxcrypt
	cd $(BUILD_WORK)/openpam && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-modules-dir=$(MEMO_PREFX)$(MEMO_SUB_PREFIX)/lib/pam \
		--with-pam-unix \
		CPPFLAGS="$(CPPFLAGS) -DSYSCONFDIR=\\\"$(MEMO_PREFIX)/etc\\\""
	+$(MAKE) -C $(BUILD_WORK)/openpam install \
		DESTDIR="$(BUILD_STAGE)/openpam"
	+$(MAKE) -C $(BUILD_WORK)/openpam install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/openpam/.build_complete
endif

openpam-package: openpam-stage
	# openpam.mk Package Structure
	rm -rf $(BUILD_DIST)/libpam{2,-dev}
	mkdir -p $(BUILD_DIST)/libpam{2,-dev}/$(MEMO_PREFX)/{$(MEMO_SUB_PREFIX)/lib,/etc/pam.d}

	# openpam.mk Prep libpam2
	cp -a $(BUILD_STAGE)/openpam/$(MEMO_PREFX)$(MEMO_SUB_PREFIX)/lib/libpam.2.dylib $(BUILD_DIST)/libpam2/$(MEMO_PREFX)$(MEMO_SUB_PREFIX)/lib/libpam.2.dylib
	cp -a $(BUILD_MISC)/pam/other $(BUILD_DIST)/libpam2/$(MEMO_PREFX)/etc/pam.d

	# openpam.mk Prep libpam-dev
	cp -a $(BUILD_STAGE)/openpam/$(MEMO_PREFX)$(MEMO_SUB_PREFIX)/lib/!(libpam.2.dylib|pam) $(BUILD_DIST)/libpam-dev/$(MEMO_PREFX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/openpam/$(MEMO_PREFX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/libpam-dev/$(MEMO_PREFX)$(MEMO_SUB_PREFIX)

	# openpam.mk Sign
	$(call SIGN,libpam2,general.xml)

	# openpam.mk Make .debs
	$(call PACK,libpam2,DEB_OPENPAM_V)
	$(call PACK,libpam-dev,DEB_OPENPAM_V)

	# openpam.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpam{2,-dev,}

.PHONY: openpam openpam-package

endif