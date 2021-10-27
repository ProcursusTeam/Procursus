ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += mozjs78
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
mozjs78: mozjs78-setup icu4c readline
	mkdir -p $(BUILD_WORK)/mozjs78/js/src/obj
	cd $(BUILD_WORK)/mozjs78/js/src/obj && \
	$(DEFAULT_SETUP_PY_ENV) && $(DEFAULT_RUST_FLAGS) RUST_TARGET=$(RUST_TARGET) \
	LDFLAGS='$(LDFLAGS) -framework Security' sh ../configure \
		--host=$$($(BUILD_MISC)/config.guess) \
		--target=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-system-zlib \
		--disable-strip \
		--with-intl-api \
		--with-system-icu \
		--enable-readline \
		--disable-jemalloc \
		--disable-tests \
		--enable-jit \
		RUSTFLAGS='-L $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib'
	sed -i 's|HOST_CC = $(CC) -isysroot $(TARGET_SYSROOT)|HOST_CC = $(CC) -isysroot $(MACOSX_SYSROOT)|g' $(BUILD_WORK)/mozjs78/js/src/obj/config/autoconf.mk
	sed -i 's|HOST_CXX = $(CXX)-isysroot $(TARGET_SYSROOT)|HOST_CXX = $(CXX) -isysroot $(MACOSX_SYSROOT)|g' $(BUILD_WORK)/mozjs78/js/src/obj/config/autoconf.mk
	sed -i 's|HOST_CC_BASE_FLAGS = -isysroot $(TARGET_SYSROOT)|HOST_CC_BASE_FLAGS = -isysroot $(MACOSX_SYSROOT)|g' $(BUILD_WORK)/mozjs78/js/src/obj/config/autoconf.mk
	sed -i 's|HOST_CXX_BASE_FLAGS = -isysroot $(TARGET_SYSROOT)|HOST_CXX_BASE_FLAGS = -isysroot $(MACOSX_SYSROOT)|g' $(BUILD_WORK)/mozjs78/js/src/obj/config/autoconf.mk
	+$(DEFAULT_RUST_FLAGS) RUST_TARGET=$(RUST_TARGET) $(MAKE) -C $(BUILD_WORK)/mozjs78/js/src/obj
	+$(MAKE) -C $(BUILD_WORK)/mozjs78/js/src/obj install \
		DESTDIR=$(BUILD_STAGE)/mozjs78
	rm -rf $(BUILD_STAGE)/mozjs78/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libjs_static.ajs
	$(call AFTER_BUILD,copy)
endif

mozjs78-package: mozjs78-stage
	# mozjs78.mk Package Structure
	rm -rf $(BUILD_DIST)/libmozjs-78-{0,dev}
	mkdir -p $(BUILD_DIST)/libmozjs-78-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
	mkdir -p $(BUILD_DIST)/libmozjs-78-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include,bin}

	# mozjs78.mk Prep libmozjs-78-0
	cp -a $(BUILD_STAGE)/mozjs78/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmozjs-78.dylib $(BUILD_DIST)/libmozjs-78-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# mozjs78.mk Prep libmozjs-78-dev
	cp -a $(BUILD_STAGE)/mozjs78/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/mozjs-78.pc  $(BUILD_DIST)/libmozjs-78-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/mozjs78/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/mozjs-78  $(BUILD_DIST)/libmozjs-78-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/mozjs78/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{js78,js78-config}  $(BUILD_DIST)/libmozjs-78-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# mozjs78.mk Sign
	$(call SIGN,libmozjs-78-0,qemu-ios.xml)
	$(call SIGN,libmozjs-78-dev,qemu-ios.xml)

	# mozjs78.mk Make .debs
	$(call PACK,libmozjs-78-0,DEB_MOZJS78_V)
	$(call PACK,libmozjs-78-dev,DEB_MOZJS78_V)

	# mozjs78.mk Build cleanup
	rm -rf $(BUILD_DIST)/libmozjs-78-{0,dev}

.PHONY: mozjs78 mozjs78-package
