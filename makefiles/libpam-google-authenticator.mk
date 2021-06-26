ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                         += libpam-google-authenticator
LIBPAM-GOOGLE-AUTHENTICATOR_COMMIT  := 0b02aadc28ac261b6c7f5785d2f7f36b3e199d97
LIBPAM-GOOGLE-AUTHENTICATOR_VERSION := 0~20210222.$(shell echo $(LIBPAM-GOOGLE-AUTHENTICATOR_COMMIT) | cut -c -7)
DEB_LIBPAM-GOOGLE-AUTHENTICATOR_V   := $(LIBPAM-GOOGLE-AUTHENTICATOR_VERSION)

libpam-google-authenticator-setup: setup
	$(call GITHUB_ARCHIVE,google,google-authenticator-libpam,$(LIBPAM-GOOGLE-AUTHENTICATOR_COMMIT),$(LIBPAM-GOOGLE-AUTHENTICATOR_COMMIT))
	$(call EXTRACT_TAR,google-authenticator-libpam-$(LIBPAM-GOOGLE-AUTHENTICATOR_COMMIT).tar.gz,google-authenticator-libpam-$(LIBPAM-GOOGLE-AUTHENTICATOR_COMMIT),libpam-google-authenticator)

ifneq ($(wildcard $(BUILD_WORK)/libpam-google-authenticator/.build_complete),)
libpam-google-authenticator:
	@echo "Using previously built libpam-google-authenticator."
else
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
libpam-google-authenticator: libpam-google-authenticator-setup openpam
else # (,$(findstring darwin,$(MEMO_TARGET)))
libpam-google-authenticator: libpam-google-authenticator-setup
endif # (,$(findstring darwin,$(MEMO_TARGET)))
	cd $(BUILD_WORK)/libpam-google-authenticator && ./bootstrap.sh && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libpam-google-authenticator
	+$(MAKE) -C $(BUILD_WORK)/libpam-google-authenticator install \
		DESTDIR="$(BUILD_STAGE)/libpam-google-authenticator"
	touch $(BUILD_WORK)/libpam-google-authenticator/.build_complete
endif

libpam-google-authenticator-package: libpam-google-authenticator-stage
	# libpam-google-authenticator.mk Package Structure
	rm -rf $(BUILD_DIST)/libpam-google-authenticator
	mkdir -p $(BUILD_DIST)/libpam-google-authenticator

	# libpam-google-authenticator.mk Prep libpam-google-authenticator
	cp -a $(BUILD_STAGE)/libpam-google-authenticator $(BUILD_DIST)
	mv -f $(BUILD_DIST)/libpam-google-authenticator/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/security $(BUILD_DIST)/libpam-google-authenticator/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pam
	# libpam-google-authenticator.mk Sign
	$(call SIGN,libpam-google-authenticator,general.xml)

	# libpam-google-authenticator.mk Make .debs
	$(call PACK,libpam-google-authenticator,DEB_LIBPAM-GOOGLE-AUTHENTICATOR_V)

	# libpam-google-authenticator.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpam-google-authenticator

.PHONY: libpam-google-authenticator libpam-google-authenticator-package

