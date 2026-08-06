ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += icecream
ICECREAM_VERSION := 1.3.1
DEB_ICECREAM_V   ?= $(ICECREAM_VERSION)-1

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
ICECREAM_LDFLAGS := -Wl,-flat_namespace -Wl,-undefined -Wl,suppress
endif

icecream-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/icecc/icecream/releases/download/$(ICECREAM_VERSION)/icecc-$(ICECREAM_VERSION).tar.xz
	$(call EXTRACT_TAR,icecc-$(ICECREAM_VERSION).tar.xz,icecc-$(ICECREAM_VERSION),icecream)

ifneq ($(wildcard $(BUILD_WORK)/icecream/.build_complete),)
icecream:
	@echo "Using previously built icecream."
else
icecream: icecream-setup liblzo2 zstd libarchive
	cd $(BUILD_WORK)/icecream && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
		+$(MAKE) -C $(BUILD_WORK)/icecream
	+$(MAKE) -C $(BUILD_WORK)/icecream install \
		DESTDIR="$(BUILD_STAGE)/icecream"
		touch $(BUILD_WORK)/icecream/.build_complete
endif

icecream-package: icecream-stage
	# icecream.mk Package Structure
	rm -rf $(BUILD_DIST)/icecream
	mkdir -p $(BUILD_DIST)/icecream
	# icecream.mk Prep icecream
	cp -a $(BUILD_STAGE)/icecream $(BUILD_DIST)/icecream
	# icecream.mk Sign
	$(call SIGN,icecream,general.xml)
	
	# icecream.mk Make .debs
	$(call PACK,icecream,DEB_ICECREAM_V)
	# icecream.mk Build cleanup
	rm -rf $(BUILD_DIST)/icecream

	.PHONY: icecream icecream-package
