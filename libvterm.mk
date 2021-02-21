ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libvterm
LIBVTERM_VERSION := 0.1.4
DEB_LIBVTERM_V   ?= $(LIBVTERM_VERSION)

libvterm-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://deb.debian.org/debian/pool/main/libv/libvterm/libvterm_$(LIBVTERM_VERSION).orig.tar.gz
	$(call EXTRACT_TAR,libvterm_$(LIBVTERM_VERSION).orig.tar.gz,libvterm-$(LIBVTERM_VERSION),libvterm)
	mkdir -p $(BUILD_WORK)/libvterm/libtool
	echo -e "AC_INIT([dummy],[1.0])\n\
LT_INIT\n\
AC_PROG_LIBTOOL\n\
AC_OUTPUT" > $(BUILD_WORK)/libvterm/libtool/configure.ac

ifneq ($(wildcard $(BUILD_WORK)/libvterm/.build_complete),)
libvterm:
	@echo "Using previously built libvterm."
else
libvterm: libvterm-setup
	cd $(BUILD_WORK)/libvterm/libtool && LIBTOOLIZE="$(LIBTOOLIZE) -i" autoreconf -fi
	cd $(BUILD_WORK)/libvterm/libtool && ./configure -C \
		--host=$(GNU_HOST_TRIPLE)
	+$(MAKE) -C $(BUILD_WORK)/libvterm \
		PREFIX=/usr \
		LIBTOOL="$(BUILD_WORK)/libvterm/libtool/libtool"
	+$(MAKE) -C $(BUILD_WORK)/libvterm install PREFIX=/usr \
		DESTDIR="$(BUILD_STAGE)/libvterm"
	+$(MAKE) -C $(BUILD_WORK)/libvterm install PREFIX=/usr \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libvterm/.build_complete
endif

libvterm-package: libvterm-stage
	# libvterm.mk Package Structure
	rm -rf $(BUILD_DIST)/libvterm{-dev,0,-bin}
	mkdir -p $(BUILD_DIST)/libvterm{0,-dev}/usr/lib \
		$(BUILD_DIST)/libvterm-bin/usr
	
	# libvterm.mk Prep libvterm-dev
	cp -a $(BUILD_STAGE)/libvterm/usr/include $(BUILD_DIST)/libvterm-dev/usr
	cp -a $(BUILD_STAGE)/libvterm/usr/lib/{pkgconfig,libvterm.{a,dylib}} $(BUILD_DIST)/libvterm-dev/usr/lib
	
	# libvterm.mk Prep libvterm0
	cp -a $(BUILD_STAGE)/libvterm/usr/lib/libvterm.0.dylib $(BUILD_DIST)/libvterm0/usr/lib
	
	# libvterm.mk Prep libvterm-bin
	cp -a $(BUILD_STAGE)/libvterm/usr/bin $(BUILD_DIST)/libvterm-bin/usr
	
	# libvterm.mk Sign
	$(call SIGN,libvterm0,general.xml)
	$(call SIGN,libvterm-bin,general.xml)
	
	# libvterm.mk Make .debs
	$(call PACK,libvterm-dev,DEB_LIBVTERM_V)
	$(call PACK,libvterm0,DEB_LIBVTERM_V)
	$(call PACK,libvterm-bin,DEB_LIBVTERM_V)
	
	# libvterm.mk Build cleanup
	rm -rf $(BUILD_DIST)/libvterm{-dev,0,-bin}
	
.PHONY: libvterm libvterm-package
