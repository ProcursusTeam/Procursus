ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libc-ares
LIBC-ARES_VERSION := 1.17.1
DEB_LIBC-ARES_V   ?= $(LIBC-ARES_VERSION)

libc-ares-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://c-ares.haxx.se/download/c-ares-$(LIBC-ARES_VERSION).tar.gz{,.asc}
	$(call PGP_VERIFY,c-ares-$(LIBC-ARES_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,c-ares-$(LIBC-ARES_VERSION).tar.gz,c-ares-$(LIBC-ARES_VERSION),libc-ares)

ifneq ($(wildcard $(BUILD_WORK)/libc-ares/.build_complete),)
libc-ares:
	@echo "Using previously built libc-ares."
else
libc-ares: libc-ares-setup
	cd $(BUILD_WORK)/libc-ares && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking \
		--disable-debug \
		--enable-shared
	+$(MAKE) -C $(BUILD_WORK)/libc-ares
	+$(MAKE) -C $(BUILD_WORK)/libc-ares install \
		DESTDIR="$(BUILD_STAGE)/libc-ares"
	+$(MAKE) -C $(BUILD_WORK)/libc-ares install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libc-ares/.build_complete
endif

libc-ares-package: libc-ares-stage
	# libc-ares.mk Package Structure
	rm -rf $(BUILD_DIST)/libc-ares{-dev,2}
	mkdir -p $(BUILD_DIST)/libc-ares-dev/usr/{include,lib/pkgconfig,share/man/man3} \
			$(BUILD_DIST)/libc-ares2/usr/lib

	# libc-ares.mk Prep libc-ares-dev
	cp -a $(BUILD_STAGE)/libc-ares/usr/include/ares{,_build,_dns,_rules,_version}.h $(BUILD_DIST)/libc-ares-dev/usr/include
	cp -a $(BUILD_STAGE)/libc-ares/usr/lib/libcares.{a,dylib} $(BUILD_DIST)/libc-ares-dev/usr/lib
	cp -a $(BUILD_STAGE)/libc-ares/usr/lib/pkgconfig/libcares.pc $(BUILD_DIST)/libc-ares-dev/usr/lib/pkgconfig
	cp -a $(BUILD_STAGE)/libc-ares/usr/share/man/man3/ares_*.3 $(BUILD_DIST)/libc-ares-dev/usr/share/man/man3

	# libc-ares.mk Prep libc-ares2
	cp -a $(BUILD_STAGE)/libc-ares/usr/lib/libcares.2.dylib $(BUILD_DIST)/libc-ares2/usr/lib

	# libc-ares.mk Sign
	$(call SIGN,libc-ares2,general.xml)

	# libc-ares.mk Make .debs
	$(call PACK,libc-ares-dev,DEB_LIBC-ARES_V)
	$(call PACK,libc-ares2,DEB_LIBC-ARES_V)

	# libc-ares.mk Build cleanup
	rm -rf $(BUILD_DIST)/libc-ares{-dev,2}

.PHONY: libc-ares libc-ares-package
