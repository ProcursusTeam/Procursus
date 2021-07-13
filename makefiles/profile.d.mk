ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS    += profile.d
PROFILED_VERSION := 0-8
DEB_PROFILED_V   ?= $(PROFILED_VERSION)

ifneq ($(wildcard $(BUILD_STAGE)/profile.d/.build_complete),)
profile.d:
	@echo "Using previously built profile.d."
else
profile.d:
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	mkdir -p $(BUILD_STAGE)/profile.d/$(MEMO_PREFIX)/etc/profile.d
	cp $(BUILD_MISC)/profile.d/{,z}profile $(BUILD_STAGE)/profile.d/$(MEMO_PREFIX)/etc
	cp $(BUILD_MISC)/profile.d/terminal.sh $(BUILD_STAGE)/profile.d/$(MEMO_PREFIX)/etc/profile.d
endif # ($(MEMO_TARGET),darwin-\*)
	# This goes in /etc no matter what because it is guaranteed to be included
	# automatically on MacOS targets, which other prefixes are not
	mkdir -p $(BUILD_STAGE)/profile.d/etc/profile.d
	$(SED) -e 's|@MEMO_ALL_LIBDIR@|$(MEMO_ALL_LIBDIR)|g' \
		-e 's|@MEMO_LIBDIR@|$(MEMO_LIBDIR)|' \
		$(BUILD_MISC)/profile.d/multiarch.sh \
		> $(BUILD_STAGE)/profile.d/etc/profile.d/multiarch.sh
	touch $(BUILD_STAGE)/profile.d/.build_complete
endif

profile.d-package: profile.d-stage
	# profile.d.mk Package Structure
	rm -rf $(BUILD_DIST)/profile.d
	mkdir -p $(BUILD_DIST)/profile.d/$(MEMO_PREFIX)
	
	# profile.d.mk Prep profile.d
	cp -a $(BUILD_STAGE)/profile.d/$(MEMO_PREFIX)/etc $(BUILD_DIST)/profile.d/$(MEMO_PREFIX)
	mkdir -p $(BUILD_DIST)/profile.d/etc/profile.d/
	cp -a $(BUILD_STAGE)/profile.d/etc/profile.d/multiarch.sh $(BUILD_DIST)/profile.d/etc/profile.d/
	
	# profile.d.mk Permissions
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(FAKEROOT) chmod a+x $(BUILD_DIST)/profile.d/$(MEMO_PREFIX)/etc/profile.d/terminal.sh
endif
	$(FAKEROOT) chmod a+x $(BUILD_DIST)/profile.d/etc/profile.d/multiarch.sh
	
	# profile.d.mk Make .debs
	$(call PACK,profile.d,DEB_PROFILED_V)
	
	# profile.d.mk Build cleanup
	rm -rf $(BUILD_DIST)/profile.d

.PHONY: profile.d profile.d-package
