ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += p7zip
P7ZIP_VERSION  := 17.04
DEB_P7ZIP_V    ?= $(P7ZIP_VERSION)

p7zip-setup: setup
	$(call GITHUB_ARCHIVE,jinfeihan57,p7zip,$(P7ZIP_VERSION),v$(P7ZIP_VERSION))
	$(call EXTRACT_TAR,p7zip-$(P7ZIP_VERSION).tar.gz,p7zip-$(P7ZIP_VERSION),p7zip)
	chmod 0755 $(BUILD_WORK)/p7zip/install.sh

ifneq ($(wildcard $(BUILD_WORK)/p7zip/.build_complete),)
p7zip:
	@echo "Using previously built p7zip."
else
p7zip: p7zip-setup
	$(SED) -i 's/ifdef __APPLE_CC__/if 0\/\/__APPLE_CC__/g' $(BUILD_WORK)/p7zip/CPP/Windows/DLL.cpp
	cd $(BUILD_WORK)/p7zip && mv -f makefile.macosx_gcc_64bits makefile.machine
	+$(MAKE) -C $(BUILD_WORK)/p7zip all3 \
		CC="$(CC) $(CFLAGS)" \
		CXX="$(CXX) $(CFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/p7zip install \
		DEST_DIR=$(BUILD_STAGE)/p7zip \
		DEST_HOME=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DEST_MAN=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
	touch $(BUILD_WORK)/p7zip/.build_complete
endif

p7zip-package: p7zip-stage
	# p7zip.mk Package Structure
	rm -rf $(BUILD_DIST)/p7zip

	# p7zip.mk Prep p7zip
	cp -a $(BUILD_STAGE)/p7zip $(BUILD_DIST)

	# p7zip.mk Sign
	$(call SIGN,p7zip,general.xml)

	# p7zip.mk Make .debs
	$(call PACK,p7zip,DEB_P7ZIP_V)

	# p7zip.mk Build cleanup
	rm -rf $(BUILD_DIST)/p7zip

.PHONY: p7zip p7zip-package
