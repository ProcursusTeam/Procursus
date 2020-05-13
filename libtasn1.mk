ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libtasn1
DOWNLOAD         += https://ftp.gnu.org/gnu/libtasn1/libtasn1-$(LIBTASN1_VERSION).tar.gz{,.sig}
LIBTASN1_VERSION := 4.16.0
DEB_LIBTASN1_V   ?= $(LIBTASN1_VERSION)

libtasn1-setup: setup
	$(call PGP_VERIFY,libtasn1-$(LIBTASN1_VERSION).tar.gz)
	$(call EXTRACT_TAR,libtasn1-$(LIBTASN1_VERSION).tar.gz,libtasn1-$(LIBTASN1_VERSION),libtasn1)

ifneq ($(wildcard $(BUILD_WORK)/libtasn1/.build_complete),)
libtasn1:
	@echo "Using previously built libtasn1."
else
libtasn1: libtasn1-setup
	cd $(BUILD_WORK)/libtasn1 && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libtasn1
	+$(MAKE) -C $(BUILD_WORK)/libtasn1 install \
		DESTDIR=$(BUILD_STAGE)/libtasn1
	+$(MAKE) -C $(BUILD_WORK)/libtasn1 install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libtasn1/.build_complete
endif

libtasn1-package: libtasn1-stage
	# libtasn1.mk Package Structure
	rm -rf $(BUILD_DIST)/libtasn1
	mkdir -p $(BUILD_DIST)/libtasn1
	
	# libtasn1.mk Prep libtasn1
	cp -a $(BUILD_STAGE)/libtasn1/usr $(BUILD_DIST)/libtasn1
	
	# libtasn1.mk Sign
	$(call SIGN,libtasn1,general.xml)
	
	# libtasn1.mk Make .debs
	$(call PACK,libtasn1,DEB_LIBTASN1_V)
	
	# libtasn1.mk Build cleanup
	rm -rf $(BUILD_DIST)/libtasn1

.PHONY: libtasn1 libtasn1-package
