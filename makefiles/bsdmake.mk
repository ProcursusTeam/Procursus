ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += bsdmake
BSDMAKE_VERSION := 24
DEB_BSDMAKE_V   ?= $(BSDMAKE_VERSION)

bsdmake-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://opensource.apple.com/tarballs/bsdmake/bsdmake-$(BSDMAKE_VERSION).tar.gz
	$(call EXTRACT_TAR,bsdmake-$(BSDMAKE_VERSION).tar.gz,bsdmake-$(BSDMAKE_VERSION),bsdmake)
	$(call DO_PATCH,bsdmake,bsdmake,-p0)

ifneq ($(wildcard $(BUILD_WORK)/bsdmake/.build_complete),)
bsdmake:
	@echo "Using previously built bsdmake."
else
bsdmake: bsdmake-setup
	mkdir -p $(BUILD_STAGE)/bsdmake/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}
	cd $(BUILD_WORK)/bsdmake && \
		$(CC_FOR_BUILD) $(CFLAGS_FOR_BUILD) $(LDFLAGS_FOR_BUILD) *.c -o make-native -DDEFSHELLNAME=\"sh\"
	+unset MAKEFLAGS && \
		$(BUILD_WORK)/bsdmake/make-native \
		-m $(BUILD_WORK)/bsdmake/mk \
		-C $(BUILD_WORK)/bsdmake \
		$(DEFAULT_BMAKE_FLAGS) \
		WARNS=0
	+unset MAKEFLAGS && \
		$(BUILD_WORK)/bsdmake/make-native \
		-m $(BUILD_WORK)/bsdmake/mk \
		-C $(BUILD_WORK)/bsdmake \
		install \
		$(DEFAULT_BMAKE_FLAGS) \
		PROGNAME=bsdmake \
		BINDIR="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin" \
		DESTDIR=$(BUILD_STAGE)/bsdmake
	gzip -dc $(BUILD_STAGE)/bsdmake/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/make.1.gz > \
		$(BUILD_STAGE)/bsdmake/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/bsdmake.1
	rm -f $(BUILD_STAGE)/bsdmake/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/make.1.gz
	cp -a $(BUILD_WORK)/bsdmake/mk \
		$(BUILD_STAGE)/bsdmake/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/mk
	rm -f $(BUILD_STAGE)/bsdmake/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/mk/{Makefile,bsd.pkg.mk}
	$(call AFTER_BUILD)
endif

bsdmake-package: bsdmake-stage
	# bsdmake.mk Package Structure
	rm -rf $(BUILD_DIST)/bsdmake
	mkdir -p $(BUILD_DIST)/bsdmake

	# bsdmake.mk Prep bsdmake
	cp -a $(BUILD_STAGE)/bsdmake $(BUILD_DIST)

	# bsdmake.mk Sign
	$(call SIGN,bsdmake,general.xml)

	# bsdmake.mk Make .debs
	$(call PACK,bsdmake,DEB_BSDMAKE_V)

	# bsdmake.mk Build cleanup
	rm -rf $(BUILD_DIST)/bsdmake

.PHONY: bsdmake bsdmake-package
