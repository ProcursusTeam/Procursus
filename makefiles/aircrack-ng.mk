ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += aircrack-ng
AIRCRACK-NG_COMMIT  := 482f56c5a1433df6b8619f1de6d89d2d5f5ab743
AIRCRACK-NG_VERSION := 1.6~20211007.$(shell echo $(AIRCRACK_COMMIT) | cut -c -7)
DEB_AIRCRACK-NG_V   ?= $(AIRCRACK-NG_VERSION)

aircrack-ng-setup: setup
	$(call GITHUB_ARCHIVE,aircrack-ng,aircrack-ng,$(AIRCRACK-NG_COMMIT),$(AIRCRACK-NG_COMMIT))
	$(call EXTRACT_TAR,aircrack-ng-$(AIRCRACK-NG_COMMIT).tar.gz,aircrack-ng-$(AIRCRACK-NG_COMMIT),aircrack-ng)
	rm $(BUILD_WORK)/aircrack-ng/lib/libac/support/{strlcat.c,strlcpy.c} && touch $(BUILD_WORK)/aircrack-ng/lib/libac/support/{strlcat.c,strlcpy.c}

ifneq ($(wildcard $(BUILD_WORK)/aircrack-ng/.build_complete),)
aircrack-ng:
	@echo "Using previously built aircrack-ng."
else
aircrack-ng: aircrack-ng-setup openssl pcre
	cd $(BUILD_WORK)/aircrack-ng && ./autogen.sh -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-experimental=yes \
		--disable-silent-rules \
		--without-xcode \
		--without-duma \
		--without-gcrypt \
		--with-lto
	+$(MAKE) -C $(BUILD_WORK)/aircrack-ng
	+$(MAKE) -C $(BUILD_WORK)/aircrack-ng install \
		DESTDIR=$(BUILD_STAGE)/aircrack-ng
	touch $(BUILD_WORK)/aircrack-ng/.build_complete
endif

aircrack-ng-package: aircrack-ng-stage
	# aircrack-ng.mk Package Structure
	rm -rf $(BUILD_DIST)/aircrack-ng
	
	# aircrack.mk Prep aircrack
	cp -a $(BUILD_STAGE)/aircrack-ng $(BUILD_DIST)
	
	# aircrack-ng.mk Sign
	$(call SIGN,aircrack-ng,general.xml)
	
	# aircrack-ng.mk Make .debs
	$(call PACK,aircrack-ng,DEB_AIRCRACK-NG_V)
	
	# aircrack-ng.mk Build cleanup
	rm -rf $(BUILD_DIST)/aircrack-ng

.PHONY: aircrack-ng aircrack-ng-package
