ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libiconv
LIBICONV_VERSION := 1.16
DEB_LIBICONV_V   ?= $(LIBICONV_VERSION)

libiconv-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) http://ftp.gnu.org/pub/gnu/libiconv/libiconv-$(LIBICONV_VERSION).tar.gz
	$(call EXTRACT_TAR,libiconv-$(LIBICONV_VERSION).tar.gz,libiconv-$(LIBICONV_VERSION),libiconv)


ifneq ($(wildcard $(BUILD_WORK)/libiconv/.build_complete),)
libiconv:
	@echo "Using previously built libiconv."
else
libiconv: libiconv-setup
	cd $(BUILD_WORK)/libiconv && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libiconv
	+$(MAKE) -C $(BUILD_WORK)/libiconv install \
		DESTDIR=$(BUILD_STAGE)/libiconv
	touch $(BUILD_WORK)/libiconv/.build_complete
endif

libiconv-package: libiconv-stage
	# libiconv.mk Package Structure
	rm -rf $(BUILD_DIST)/libiconv
	mkdir -p $(BUILD_DIST)/libiconv
	
	# libiconv.mk Prep libiconv
	cp -a $(BUILD_STAGE)/libiconv $(BUILD_DIST)
	
	# libiconv.mk Sign
	$(call SIGN,libiconv,general.xml)
	
	# libiconv.mk Make .debs
	$(call PACK,libiconv,DEB_LIBICONV_V)
	
	# libiconv.mk Build cleanup
	rm -rf $(BUILD_DIST)/libiconv

	.PHONY: libiconv libiconv-package
