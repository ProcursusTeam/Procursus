ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += pcre
PCRE_VERSION  := 8.44
DEB_PCRE_V    ?= $(PCRE_VERSION)-1

pcre-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftp.pcre.org/pub/pcre/pcre-$(PCRE_VERSION).tar.bz2{,.sig}
	$(call PGP_VERIFY,pcre-$(PCRE_VERSION).tar.bz2)
	$(call EXTRACT_TAR,pcre-$(PCRE_VERSION).tar.bz2,pcre-$(PCRE_VERSION),pcre)

ifneq ($(wildcard $(BUILD_WORK)/pcre/.build_complete),)
pcre:
	@echo "Using previously built pcre."
else
pcre: pcre-setup
	cd $(BUILD_WORK)/pcre && unset MACOSX_DEPLOYMENT_TARGET && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking \
		--enable-utf8 \
		--enable-pcre8 \
		--enable-pcre16 \
		--enable-pcre32 \
		--enable-jit \
		--enable-unicode-properties \
		--enable-pcregrep-libz \
		--enable-pcregrep-libbz2
	+$(MAKE) -C $(BUILD_WORK)/pcre
	+$(MAKE) -C $(BUILD_WORK)/pcre install \
		DESTDIR=$(BUILD_STAGE)/pcre
	+$(MAKE) -C $(BUILD_WORK)/pcre install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/pcre/.build_complete
endif

pcre-package: pcre-stage
	# pcre.mk Package Structure
	rm -rf $(BUILD_DIST)/libpcre{1{,-dev},16-0,32-0,posix0,cpp0} $(BUILD_DIST)/pcregrep
	mkdir -p $(BUILD_DIST)/libpcre{1,16-0,32-0,posix0,cpp0}/usr/lib \
		$(BUILD_DIST)/libpcre1-dev/usr/{bin,lib,share/man/man1} \
		$(BUILD_DIST)/pcregrep/usr/{bin,share/man/man1}
	
	# pcre.mk Prep libpcre1
	cp -a $(BUILD_STAGE)/pcre/usr/lib/libpcre.1.dylib $(BUILD_DIST)/libpcre1/usr/lib

	# pcre.mk Prep libpcre{16-0,32-0}
	for ver in {16,32}; do \
		cp -a $(BUILD_STAGE)/pcre/usr/lib/libpcre$${ver}.0.dylib $(BUILD_DIST)/libpcre$${ver}-0/usr/lib; \
	done

	# pcre.mk Prep libpcre{posix0,cpp0}
	for ver in {posix,cpp}; do \
		cp -a $(BUILD_STAGE)/pcre/usr/lib/libpcre$${ver}.0.dylib $(BUILD_DIST)/libpcre$${ver}0/usr/lib; \
	done

	# pcre.mk Prep libpcre1-dev
	cp -a $(BUILD_STAGE)/pcre/usr/lib/!(*.1*|*.0*|*.0*) $(BUILD_DIST)/libpcre1-dev/usr/lib
	cp -a $(BUILD_STAGE)/pcre/usr/bin/pcre-config $(BUILD_DIST)/libpcre1-dev/usr/bin
	cp -a $(BUILD_STAGE)/pcre/usr/share/man/man1/pcre-config.1 $(BUILD_DIST)/libpcre1-dev/usr/share/man/man1
	cp -a $(BUILD_STAGE)/pcre/usr/share/man/man3 $(BUILD_DIST)/libpcre1-dev/usr/share/man
	cp -a $(BUILD_STAGE)/pcre/usr/include $(BUILD_DIST)/libpcre1-dev/usr

	# pcre.mk Prep pcregrep
	cp -a $(BUILD_STAGE)/pcre/usr/bin/pcregrep $(BUILD_DIST)/pcregrep/usr/bin
	cp -a $(BUILD_STAGE)/pcre/usr/share/man/man1/pcregrep.1 $(BUILD_DIST)/pcregrep/usr/share/man/man1
	
	# pcre.mk Sign
	$(call SIGN,libpcre1,general.xml)
	$(call SIGN,libpcre16-0,general.xml)
	$(call SIGN,libpcre32-0,general.xml)
	$(call SIGN,libpcreposix0,general.xml)
	$(call SIGN,libpcrecpp0,general.xml)
	$(call SIGN,pcregrep,general.xml)
	
	# pcre.mk Make .debs
	$(call PACK,libpcre1,DEB_PCRE_V)
	$(call PACK,libpcre1-dev,DEB_PCRE_V)
	$(call PACK,libpcre16-0,DEB_PCRE_V)
	$(call PACK,libpcre32-0,DEB_PCRE_V)
	$(call PACK,libpcreposix0,DEB_PCRE_V)
	$(call PACK,libpcrecpp0,DEB_PCRE_V)
	$(call PACK,pcregrep,DEB_PCRE_V)
	
	# pcre.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpcre{1{,-dev},16-0,32-0,posix0,cpp0} $(BUILD_DIST)/pcregrep

.PHONY: pcre pcre-package
