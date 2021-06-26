ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += libidn2
IDN2_VERSION  := 2.3.0
DEB_IDN2_V    ?= $(IDN2_VERSION)-3

libidn2-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/libidn/libidn2-$(IDN2_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libidn2-$(IDN2_VERSION).tar.gz)
	$(call EXTRACT_TAR,libidn2-$(IDN2_VERSION).tar.gz,libidn2-$(IDN2_VERSION),libidn2)

ifneq ($(wildcard $(BUILD_WORK)/libidn2/.build_complete),)
libidn2:
	@echo "Using previously built libidn2."
else
libidn2: libidn2-setup gettext libunistring
	cd $(BUILD_WORK)/libidn2 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libidn2
	+$(MAKE) -C $(BUILD_WORK)/libidn2 install \
		DESTDIR=$(BUILD_STAGE)/libidn2
	+$(MAKE) -C $(BUILD_WORK)/libidn2 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libidn2/.build_complete
endif

libidn2-package: libidn2-stage
	# libidn2.mk Package Structure
	rm -rf $(BUILD_DIST)/libidn2{-0,-dev} \
		$(BUILD_DIST)/idn2
	mkdir -p $(BUILD_DIST)/libidn2-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{share,lib} \
		$(BUILD_DIST)/libidn2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{share/man,lib} \
		$(BUILD_DIST)/idn2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# libidn2.mk Prep idn2
	cp -a $(BUILD_STAGE)/libidn2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/idn2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libidn2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 $(BUILD_DIST)/idn2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# libidn2.mk Prep libidn2-0
	cp -a $(BUILD_STAGE)/libidn2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libidn2.0.dylib $(BUILD_DIST)/libidn2-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libidn2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale $(BUILD_DIST)/libidn2-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libidn2.mk Prep libidn2-dev
	cp -a $(BUILD_STAGE)/libidn2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libidn2.{dylib,a},pkgconfig} $(BUILD_DIST)/libidn2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libidn2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 $(BUILD_DIST)/libidn2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# libidn2.mk Sign
	$(call SIGN,idn2,general.xml)
	$(call SIGN,libidn2-0,general.xml)

	# libidn2.mk Make .debs
	$(call PACK,idn2,DEB_IDN2_V)
	$(call PACK,libidn2-0,DEB_IDN2_V)
	$(call PACK,libidn2-dev,DEB_IDN2_V)

	# libidn2.mk Build cleanup
	rm -rf $(BUILD_DIST)/libidn2-{0,dev} \
		$(BUILD_DIST)/idn2

.PHONY: libidn2 libidn2-package
