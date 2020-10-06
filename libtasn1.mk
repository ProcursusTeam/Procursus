ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libtasn1
LIBTASN1_VERSION := 4.16.0
DEB_LIBTASN1_V   ?= $(LIBTASN1_VERSION)-1

libtasn1-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/libtasn1/libtasn1-$(LIBTASN1_VERSION).tar.gz{,.sig}
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
	rm -rf $(BUILD_DIST)/libtasn1-{6{,-dev},bin}
	mkdir -p $(BUILD_DIST)/libtasn1-6/usr/lib \
		$(BUILD_DIST)/libtasn1-6-dev/usr/{lib,share/man} \
		$(BUILD_DIST)/libtasn1-bin/usr/share/man
	
	# libtasn1.mk Prep libtasn1-6
	cp -a $(BUILD_STAGE)/libtasn1/usr/lib/libtasn1.6.dylib $(BUILD_DIST)/libtasn1-6/usr/lib

	# libtasn1.mk Prep libtasn1-dev
	cp -a $(BUILD_STAGE)/libtasn1/usr/lib/!(libtasn1.6.dylib) $(BUILD_DIST)/libtasn1-6-dev/usr/lib
	cp -a $(BUILD_STAGE)/libtasn1/usr/share/man/man3 $(BUILD_DIST)/libtasn1-6-dev/usr/share/man
	cp -a $(BUILD_STAGE)/libtasn1/usr/include $(BUILD_DIST)/libtasn1-6-dev/usr

	# libtasn1.mk Prep libtasn1-bin
	cp -a $(BUILD_STAGE)/libtasn1/usr/share/man/man1 $(BUILD_DIST)/libtasn1-bin/usr/share/man
	cp -a $(BUILD_STAGE)/libtasn1/usr/bin $(BUILD_DIST)/libtasn1-bin/usr
	
	# libtasn1.mk Sign
	$(call SIGN,libtasn1-6,general.xml)
	$(call SIGN,libtasn1-bin,general.xml)
	
	# libtasn1.mk Make .debs
	$(call PACK,libtasn1-6,DEB_LIBTASN1_V)
	$(call PACK,libtasn1-bin,DEB_LIBTASN1_V)
	$(call PACK,libtasn1-6-dev,DEB_LIBTASN1_V)
	
	# libtasn1.mk Build cleanup
	rm -rf $(BUILD_DIST)/libtasn1-{6{,-dev},bin}

.PHONY: libtasn1 libtasn1-package
