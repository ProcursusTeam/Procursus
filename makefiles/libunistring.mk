ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS     += libunistring
UNISTRING_VERSION := 0.9.10
DEB_UNISTRING_V   ?= $(UNISTRING_VERSION)-2

libunistring-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/libunistring/libunistring-$(UNISTRING_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,libunistring-$(UNISTRING_VERSION).tar.gz)
	$(call EXTRACT_TAR,libunistring-$(UNISTRING_VERSION).tar.gz,libunistring-$(UNISTRING_VERSION),libunistring)

ifneq ($(wildcard $(BUILD_WORK)/libunistring/.build_complete),)
libunistring:
	@echo "Using previously built libunistring."
else
libunistring: libunistring-setup
	cd $(BUILD_WORK)/libunistring && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libunistring
	+$(MAKE) -C $(BUILD_WORK)/libunistring install \
		DESTDIR=$(BUILD_STAGE)/libunistring
	+$(MAKE) -C $(BUILD_WORK)/libunistring install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libunistring/.build_complete
endif

libunistring-package: libunistring-stage
	# libunistring.mk Package Structure
	rm -rf $(BUILD_DIST)/libunistring{2,-dev}
	mkdir -p $(BUILD_DIST)/libunistring{2,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libunistring.mk Prep libunistring2
	cp -a $(BUILD_STAGE)/libunistring/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libunistring.2.dylib $(BUILD_DIST)/libunistring2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libunistring.mk Prep libunistring-dev
	cp -a $(BUILD_STAGE)/libunistring/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libunistring.{dylib,a} $(BUILD_DIST)/libunistring-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libunistring/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libunistring-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libunistring.mk Sign
	$(call SIGN,libunistring2,general.xml)

	# libunistring.mk Make .debs
	$(call PACK,libunistring2,DEB_UNISTRING_V)
	$(call PACK,libunistring-dev,DEB_UNISTRING_V)

	# libunistring.mk Build cleanup
	rm -rf $(BUILD_DIST)/libunistring{2,-dev}

.PHONY: libunistring libunistring-package
