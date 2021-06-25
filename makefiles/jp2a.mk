ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += jp2a
JP2A_VERSION := 1.1.0
DEB_JP2A_V   ?= $(JP2A_VERSION)

jp2a-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/Talinx/jp2a/releases/download/v$(JP2A_VERSION)/jp2a-$(JP2A_VERSION).tar.gz
	$(call EXTRACT_TAR,jp2a-$(JP2A_VERSION).tar.gz,jp2a-$(JP2A_VERSION),jp2a)
	$(SED) -i s/ncurses/ncursesw/ $(BUILD_WORK)/jp2a/configure

ifneq ($(wildcard $(BUILD_WORK)/jp2a/.build_complete),)
jp2a:
	@echo "Using previously built jp2a."
else
jp2a: jp2a-setup curl libjpeg-turbo libpng16 ncurses
	cd $(BUILD_WORK)/jp2a && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-dependency-tracking
	+$(MAKE) -C $(BUILD_WORK)/jp2a
	+$(MAKE) -C $(BUILD_WORK)/jp2a install \
		DESTDIR=$(BUILD_STAGE)/jp2a
	touch $(BUILD_WORK)/jp2a/.build_complete
endif

jp2a-package: jp2a-stage
	# jp2a.mk Package Structure
	rm -rf $(BUILD_DIST)/jp2a

	# jp2a.mk Prep jp2a
	cp -a $(BUILD_STAGE)/jp2a $(BUILD_DIST)

	# jp2a.mk Sign
	$(call SIGN,jp2a,general.xml)

	# jp2a.mk Make .debs
	$(call PACK,jp2a,DEB_JP2A_V)

	# jp2a.mk Build cleanup
	rm -rf $(BUILD_DIST)/jp2a

.PHONY: jp2a jp2a-package
