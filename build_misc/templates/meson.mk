ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += @pkg@
@PKG@_VERSION := @PKG_VERSION@
DEB_@PKG@_V   ?= $(@PKG@_VERSION)

@pkg@-setup: setup
@download@
	$(call EXTRACT_TAR,@pkg@-$(@PKG@_VERSION).tar.@compression@,@pkg@-$(@PKG@_VERSION),@pkg@)
	$(call DO_PATCH,@pkg@,@pkg@,-p1)
	mkdir -p $(BUILD_WORK)/@pkg@/build
	echo -e "$(DEFAULT_MESON_CROSS_TXT" > $(BUILD_WORK)/@pkg@/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/@pkg@/.build_complete),)
@pkg@:
	@echo "Using previously built @pkg@."
else
@pkg@: @pkg@-setup
	cd $(BUILD_WORK)/@pkg@/build && meson \
		--cross-file cross.txt \
		..
	+ninja -C $(BUILD_WORK)/@pkg@/build
	+ninja -C $(BUILD_WORK)/@pkg@/build install \
		DESTDIR="$(BUILD_STAGE)/@pkg@"
	$(call AFTER_BUILD)
endif

@pkg@-package: @pkg@-stage
	# @pkg@.mk Package Structure
	rm -rf $(BUILD_DIST)/@pkg@
	
	# @pkg@.mk Prep @pkg@
	cp -a $(BUILD_STAGE)/@pkg@ $(BUILD_DIST)
	
	# @pkg@.mk Sign
	$(call SIGN,@pkg@,general.xml)
	
	# @pkg@.mk Make .debs
	$(call PACK,@pkg@,DEB_@PKG@_V)
	
	# @pkg@.mk Build cleanup
	rm -rf $(BUILD_DIST)/@pkg@

.PHONY: @pkg@ @pkg@-package
