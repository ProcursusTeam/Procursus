ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += dropbear
DROPBEAR_VERSION := 2020.81
DEB_DROPBEAR_V   ?= $(DROPBEAR_VERSION)

dropbear-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/mkj/dropbear/archive/DROPBEAR_2020.81.tar.gz
	$(call EXTRACT_TAR,DROPBEAR_$(DROPBEAR_VERSION).tar.gz,dropbear-DROPBEAR_$(DROPBEAR_VERSION),dropbear)
	$(call DO_PATCH,dropbear,dropbear,-p1)
	$(SED) -i -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' \
		$(BUILD_WORK)/dropbear/localoptions.h

ifneq ($(wildcard $(BUILD_WORK)/dropbear/.build_complete),)
dropbear:
	@echo "Using previously built dropbear."
else
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
dropbear: dropbear-setup libtommath libtomcrypt libxcrypt openpam
else # (,$(findstring darwin,$(MEMO_TARGET)))
dropbear: dropbear-setup libtommath libtomcrypt
endif # (,$(findstring darwin,$(MEMO_TARGET)))
	if ! [ -f $(BUILD_WORK)/dropbear/configure ]; then \
		cd $(BUILD_WORK)/dropbear && autoreconf -i; \
	fi
	cd $(BUILD_WORK)/dropbear && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-bundled-libtom \
		--enable-pam \
		--disable-lastlog \
		--disable-utmp \
		--disable-utmpx \
		--disable-wtmp \
		--disable-wtmpx \
		--disable-loginfunc \
		--disable-pututline \
		--disable-pututxline \
		LDFLAGS="$(LDFLAGS) -fPIE -pie"
	+$(MAKE) -C $(BUILD_WORK)/dropbear
	+$(MAKE) -C $(BUILD_WORK)/dropbear install \
		DESTDIR=$(BUILD_STAGE)/dropbear
	mkdir -p $(BUILD_STAGE)/dropbear/$(MEMO_PREFIX)/Library/LaunchDaemons
	cp $(BUILD_MISC)/dropbear/com.mkj.dropbear.plist $(BUILD_STAGE)/dropbear/$(MEMO_PREFIX)/Library/LaunchDaemons
	$(SED) -i -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' \
		$(BUILD_STAGE)/dropbear/$(MEMO_PREFIX)/Library/LaunchDaemons/com.mkj.dropbear.plist
	mkdir -p $(BUILD_STAGE)/dropbear/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	cp $(BUILD_MISC)/dropbear/dropbear-wrapper $(BUILD_STAGE)/dropbear/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec
	$(SED) -i -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' -e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' \
		$(BUILD_STAGE)/dropbear/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/dropbear-wrapper
	touch $(BUILD_WORK)/dropbear/.build_complete
endif

dropbear-package: dropbear-stage
	# dropbear.mk Package Structure
	rm -rf $(BUILD_DIST)/dropbear
	
	# dropbear.mk Prep dropbear
	cp -a $(BUILD_STAGE)/dropbear $(BUILD_DIST)
	mkdir -p $(BUILD_DIST)/dropbear/$(MEMO_PREFIX)/etc/dropbear
	
	# dropbear.mk Sign
	$(call SIGN,dropbear,general.xml)
	
	# dropbear.mk Make .debs
	$(call PACK,dropbear,DEB_DROPBEAR_V)
	
	# dropbear.mk Build cleanup
	rm -rf $(BUILD_DIST)/dropbear

.PHONY: dropbear dropbear-package
