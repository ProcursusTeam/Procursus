ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += mozjs78
MOZJS78_VERSION := 78.11.0
DEB_MOZJS78_V   ?= $(MOZJS78_VERSION)

mozjs78-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://download.gnome.org/teams/releng/tarballs-needing-help/mozjs/mozjs-$(MOZJS78_VERSION).tar.bz2
	$(call EXTRACT_TAR,mozjs-$(MOZJS78_VERSION).tar.bz2,mozjs-$(MOZJS78_VERSION),mozjs78)
	$(call DO_PATCH,mozjs78,mozjs78,-p1)
	sed -i 's/10.15.4/99/g' $(BUILD_WORK)/mozjs78/build/moz.configure/toolchain.configure
	
ifneq ($(wildcard $(BUILD_WORK)/mozjs78/.build_complete),)
mozjs78:
	@echo "Using previously built mozjs78."
else
mozjs78: mozjs78-setup
	mkdir -p $(BUILD_WORK)/mozjs78/js/src/obj
	cd $(BUILD_WORK)/mozjs78/js/src/obj && \
	$(DEFAULT_SETUP_PY_ENV) && $(DEFAULT_RUST_FLAGS) RUST_TARGET=$(RUST_TARGET) sh ../configure \
		--host=$$($(BUILD_MISC)/config.guess) \
		--target=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-system-zlib \
		--disable-strip \
		--with-intl-api \
		--with-system-icu \
		--enable-readline \
		--disable-jemalloc \
		RUSTFLAGS='-L $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib' \
		LDFLAGS='$(LDFLAGS) -framework Security'
	sed -i 's|HOST_CC = $(CC) -isysroot $(TARGET_SYSROOT)|HOST_CC = $(CC) -isysroot $(MACOSX_SYSROOT)|g' $(BUILD_WORK)/mozjs78/js/src/obj/config/autoconf.mk
	sed -i 's|HOST_CXX = $(CXX)-isysroot $(TARGET_SYSROOT)|HOST_CXX = $(CXX) -isysroot $(MACOSX_SYSROOT)|g' $(BUILD_WORK)/mozjs78/js/src/obj/config/autoconf.mk
	sed -i 's|HOST_CC_BASE_FLAGS = -isysroot $(TARGET_SYSROOT)|HOST_CC_BASE_FLAGS = -isysroot $(MACOSX_SYSROOT)|g' $(BUILD_WORK)/mozjs78/js/src/obj/config/autoconf.mk
	sed -i 's|HOST_CXX_BASE_FLAGS = -isysroot $(TARGET_SYSROOT)|HOST_CXX_BASE_FLAGS = -isysroot $(MACOSX_SYSROOT)|g' $(BUILD_WORK)/mozjs78/js/src/obj/config/autoconf.mk
	+$(DEFAULT_RUST_FLAGS) RUST_TARGET=$(RUST_TARGET) $(MAKE) -C $(BUILD_WORK)/mozjs78/js/src/obj
	+$(MAKE) -C $(BUILD_WORK)/mozjs78/js/src/obj install \
		DESTDIR=$(BUILD_STAGE)/mozjs78
	$(call AFTER_BUILD,copy)
endif

mozjs78-package: mozjs78-stage
	# mozjs78.mk Package Structure
	rm -rf $(BUILD_DIST)/mozjs78

	# mozjs78.mk Prep mozjs78
	cp -a $(BUILD_STAGE)/mozjs78 $(BUILD_DIST)

	# mozjs78.mk Sign
	$(call SIGN,mozjs78,general.xml)

	# mozjs78.mk Make .debs
	$(call PACK,mozjs78,DEB_MOZJS78_V)

	# mozjs78.mk Build cleanup
	rm -rf $(BUILD_DIST)/mozjs78

.PHONY: mozjs78 mozjs78-package
