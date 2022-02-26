ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS             += siguza-utils
SIGUZA_UTILS_COMMIT     := cb73706e410a053148ee6407201daeb99a447470
SIGUZA_UTILS_VERSION    := 1.0+git20220225.$(shell echo $(SIGUZA_UTILS_COMMIT) | cut -c -7)
DEB_SIGUZA_UTILS_V      ?= $(SIGUZA_UTILS_VERSION)

siguza-utils-setup: setup
	$(call GITHUB_ARCHIVE,Siguza,misc,$(SIGUZA_UTILS_COMMIT),$(SIGUZA_UTILS_COMMIT),siguza-utils)
	$(call EXTRACT_TAR,siguza-utils-$(SIGUZA_UTILS_COMMIT).tar.gz,misc-$(SIGUZA_UTILS_COMMIT),siguza-utils)
	mkdir -p $(BUILD_STAGE)/siguza-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/siguza-utils/.build_complete),)
siguza-utils:
	@echo "Using previously built siguza-utils."
else
siguza-utils: siguza-utils-setup
	+$(MAKE) -C $(BUILD_WORK)/siguza-utils install \
		CFLAGS="$(CFLAGS)" \
		LDFLAGS="$(LDFLAGS)" \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		DESTDIR="$(BUILD_STAGE)/siguza-utils"
	# Delete mesu, it's broken afaik
	rm -rf $(BUILD_STAGE)/siguza-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/mesu
	$(call AFTER_BUILD)
endif

siguza-utils-package: siguza-utils-stage
	# siguza-utils.mk Package Structure
	cp -a $(BUILD_STAGE)/siguza-utils $(BUILD_DIST)

	# siguza-utils.mk Sign
	$(call SIGN,siguza-utils,general.xml)

	# siguza-utils.mk Make .debs
	$(call PACK,siguza-utils,DEB_SIGUZA_UTILS_V)

	# siguza-utils.mk Build cleanup
	rm -rf $(BUILD_DIST)/siguza-utils

.PHONY: siguza-utils siguza-utils-package
