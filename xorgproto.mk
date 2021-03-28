ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += xorgproto
XORGPROTO_VERSION := 2020.1
DEB_XORGPROTO_V   ?= $(XORGPROTO_VERSION)

xorgproto-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/proto/xorgproto-$(XORGPROTO_VERSION).tar.bz2
	$(call EXTRACT_TAR,xorgproto-$(XORGPROTO_VERSION).tar.bz2,xorgproto-$(XORGPROTO_VERSION),xorgproto)

ifneq ($(wildcard $(BUILD_WORK)/xorgproto/.build_complete),)
xorgproto:
	@echo "Using previously built xorgproto."
else
xorgproto: xorgproto-setup
	cd $(BUILD_WORK)/xorgproto && ./configure \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--sysconfdir=$(MEMO_PREFIX)/etc \
		--localstatedir=$(MEMO_PREFIX)/var
	+$(MAKE) -C $(BUILD_WORK)/xorgproto install \
		DESTDIR="$(BUILD_STAGE)/xorgproto"
	+$(MAKE) -C $(BUILD_WORK)/xorgproto install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/xorgproto/.build_complete
endif

xorgproto-package: xorgproto-stage
	# xorgproto.mk Package Structure
	rm -rf $(BUILD_DIST)/x11proto-dev
	mkdir -p $(BUILD_DIST)/x11proto-dev

	# xorgproto.mk Prep xorgproto
	cp -a $(BUILD_STAGE)/xorgproto/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) $(BUILD_DIST)/x11proto-dev

	# xorgproto.mk Make .debs
	$(call PACK,x11proto-dev,DEB_XORGPROTO_V)

	# xorgproto.mk Build cleanup
	rm -rf $(BUILD_DIST)/x11proto-dev

.PHONY: xorgproto xorgproto-package
