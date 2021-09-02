ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += overb0ard
OVERB0ARD_COMMIT  := ac58a800d9d284499fc5506686d0b2ba004a6d22
OVERB0ARD_VERSION := 1.1+git20210902.$(shell echo $(OVERB0ARD_COMMIT) | cut -c -7)
DEB_OVERB0ARD_V   ?= $(OVERB0ARD_VERSION)

overb0ard-setup: setup
	$(call GITHUB_ARCHIVE,Doregon,overb0ard,$(OVERB0ARD_COMMIT),$(OVERB0ARD_COMMIT))
	$(call EXTRACT_TAR,overb0ard-$(OVERB0ARD_COMMIT).tar.gz,overb0ard-$(OVERB0ARD_COMMIT),overb0ard)
	$(SED) -iE /'API_UNAVAILABLE'/d $(BUILD_WORK)/overb0ard/NSTask.h

ifneq ($(wildcard $(BUILD_WORK)/overb0ard/.build_complete),)
overb0ard:
	@echo "Using previously built overb0ard."
else
overb0ard: overb0ard-setup
	cd $(BUILD_WORK)/overb0ard && \
	$(CC) $(CFLAGS) $(LDFLAGS) -framework CoreFoundation -framework Foundation main.m -o jetsamctl; \
	mkdir -p $(BUILD_STAGE)/overb0ard/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin; \
	$(INSTALL) -m755 jetsamctl $(BUILD_STAGE)/overb0ard/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(call AFTER_BUILD)
endif

overb0ard-package: overb0ard-stage
	# overb0ard.mk Package Structure
	rm -rf $(BUILD_DIST)/overb0ard
	
	# overb0ard.mk Prep overb0ard
	cp -a $(BUILD_STAGE)/overb0ard $(BUILD_DIST)
	
	# overb0ard.mk Sign
	$(call SIGN,overb0ard,general.xml)
	
	# overb0ard.mk Make .debs
	$(call PACK,overb0ard,DEB_OVERB0ARD_V)
	
	# overb0ard.mk Build cleanup
	rm -rf $(BUILD_DIST)/overb0ard

.PHONY: overb0ard overb0ard-package
