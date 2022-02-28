ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += lrzip-next
LRZIP_NEXT_VERSION := 0.8.10
DEB_LRZIP_NEXT_V   ?= $(LRZIP_NEXT_VERSION)

lrzip-next-setup: setup
	$(call GITHUB_ARCHIVE,pete4abw,lrzip-next,$(LRZIP_NEXT_VERSION),v$(LRZIP_NEXT_VERSION))
	$(call EXTRACT_TAR,lrzip-next-$(LRZIP_NEXT_VERSION).tar.gz,lrzip-next-$(LRZIP_NEXT_VERSION),lrzip-next)
	$(call DO_PATCH,lrzip-next,lrzip-next,-p1)

ifneq ($(wildcard $(BUILD_WORK)/lrzip-next/.build_complete),)
lrzip-next:
	@echo "Using previously built lrzip-next."
else
lrzip-next: lrzip-next-setup lz4 liblzo2 libgcrypt
	cd $(BUILD_WORK)/lrzip-next && ./autogen.sh && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	rm -f $(BUILD_WORK)/lrzip-next/version
	+$(MAKE) -C $(BUILD_WORK)/lrzip-next
	+$(MAKE) -C $(BUILD_WORK)/lrzip-next install \
		DESTDIR=$(BUILD_STAGE)/lrzip-next
	$(call AFTER_BUILD)
endif

lrzip-next-package: lrzip-next-stage
	# lrzip-next.mk Package Structure
	rm -rf $(BUILD_DIST)/lrzip-next

	# lrzip-next.mk Prep lrzip-next
	cp -a $(BUILD_STAGE)/lrzip-next $(BUILD_DIST)

	# lrzip-next.mk Sign
	$(call SIGN,lrzip-next,general.xml)

	# lrzip-next.mk Make .debs
	$(call PACK,lrzip-next,DEB_LRZIP_NEXT_V)

	# lrzip-next.mk Build cleanup
	rm -rf $(BUILD_DIST)/lrzip-next

.PHONY: lrzip-next lrzip-next-package
