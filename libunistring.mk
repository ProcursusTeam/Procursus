ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libunistring
DOWNLOAD          += https://ftp.gnu.org/gnu/libunistring/libunistring-$(UNISTRING_VERSION).tar.gz{,.sig}
UNISTRING_VERSION := 0.9.10
DEB_UNISTRING_V   ?= $(UNISTRING_VERSION)

libunistring-setup: setup
	$(call PGP_VERIFY,libunistring-$(UNISTRING_VERSION).tar.gz)
	$(call EXTRACT_TAR,libunistring-$(UNISTRING_VERSION).tar.gz,libunistring-$(UNISTRING_VERSION),libunistring)

ifneq ($(wildcard $(BUILD_WORK)/libunistring/.build_complete),)
libunistring:
	@echo "Using previously built libunistring."
else
libunistring: libunistring-setup
	cd $(BUILD_WORK)/libunistring && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libunistring
	+$(MAKE) -C $(BUILD_WORK)/libunistring install \
		DESTDIR=$(BUILD_STAGE)/libunistring
	+$(MAKE) -C $(BUILD_WORK)/libunistring install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libunistring/.build_complete
endif

libunistring-package: libunistring-stage
	# libunistring.mk Package Structure
	rm -rf $(BUILD_DIST)/libunistring
	mkdir -p $(BUILD_DIST)/libunistring
	
	# libunistring.mk Prep libunistring
	cp -a $(BUILD_STAGE)/libunistring/usr $(BUILD_DIST)/libunistring
	
	# libunistring.mk Sign
	$(call SIGN,libunistring,general.xml)
	
	# libunistring.mk Make .debs
	$(call PACK,libunistring,DEB_UNISTRING_V)
	
	# libunistring.mk Build cleanup
	rm -rf $(BUILD_DIST)/libunistring

.PHONY: libunistring libunistring-package
