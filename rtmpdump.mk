ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += rtmpdump
RTMPDUMP_VERSION  := 2.4
RTMPDUMP_SHORT_V1 := 20151223
RTMPDUMP_SHORT_V2 := gitfa8646d.1
DEB_RTMPDUMP_V    ?= $(RTMPDUMP_VERSION)+$(RTMPDUMP_SHORT_V1).$(RTMPDUMP_SHORT_V2)

rtmpdump-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://deb.debian.org/debian/pool/main/r/rtmpdump/rtmpdump_$(RTMPDUMP_VERSION)+$(RTMPDUMP_SHORT_V1).$(RTMPDUMP_SHORT_V2).orig.tar.gz
	$(call EXTRACT_TAR,rtmpdump_$(RTMPDUMP_VERSION)+$(RTMPDUMP_SHORT_V1).$(RTMPDUMP_SHORT_V2).orig.tar.gz,rtmpdump-$(RTMPDUMP_SHORT_V1),rtmpdump)

ifneq ($(wildcard $(BUILD_WORK)/rtmpdump/.build_complete),)
rtmpdump:
	@echo "Using previously built rtmpdump."
else
rtmpdump: rtmpdump-setup nettle gnutls libgmp10
	mkdir -p $(BUILD_STAGE)/rtmpdump/usr/lib
	+$(MAKE) -C $(BUILD_WORK)/rtmpdump install \
		CC="$(CC)" \
		LD="$(LD)" \
		CRYPTO=GNUTLS \
		XCFLAGS="$(CFLAGS)" \
		XLDFLAGS="$(LDFLAGS)" \
		SYS=darwin \
		prefix="/usr" \
		DESTDIR="$(BUILD_STAGE)/rtmpdump" \
		mandir="/usr/share/man"
	+$(MAKE) -C $(BUILD_WORK)/rtmpdump install \
		CC="$(CC)" \
		LD="$(LD)" \
		CRYPTO=GNUTLS \
		XCFLAGS="$(CFLAGS)" \
		XLDFLAGS="$(LDFLAGS)" \
		SYS=darwin \
		prefix="/usr" \
		DESTDIR="$(BUILD_BASE)" \
		mandir="/usr/share/man"
	touch $(BUILD_WORK)/rtmpdump/.build_complete
endif

rtmpdump-package: rtmpdump-stage
	# rtmpdump.mk Package Structure
	rm -rf $(BUILD_DIST)/rtmpdump \
		$(BUILD_DIST)/librtmp{1,-dev}
	mkdir -p $(BUILD_DIST)/rtmpdump/usr \
		$(BUILD_DIST)/librtmp{1,-dev}/usr/lib
	
	# rtmpdump.mk Prep rtmpdump
	cp -a $(BUILD_STAGE)/rtmpdump/usr/{share,bin,sbin} $(BUILD_DIST)/rtmpdump/usr
	
	# rtmpdump.mk Prep librtmp1
	cp -a $(BUILD_STAGE)/rtmpdump/usr/lib/librtmp.1.dylib $(BUILD_DIST)/librtmp1/usr/lib
	
	# rtmpdump.mk Prep librtmp-dev
	cp -a $(BUILD_STAGE)/rtmpdump/usr/lib/{librtmp.{dylib,a},pkgconfig} $(BUILD_DIST)/librtmp-dev/usr/lib
	cp -a $(BUILD_STAGE)/rtmpdump/usr/include $(BUILD_DIST)/librtmp-dev/usr
	
	# rtmpdump.mk Sign
	$(call SIGN,rtmpdump,general.xml)
	$(call SIGN,librtmp1,general.xml)
	
	# rtmpdump.mk Make .debs
	$(call PACK,rtmpdump,DEB_RTMPDUMP_V)
	$(call PACK,librtmp1,DEB_RTMPDUMP_V)
	$(call PACK,librtmp-dev,DEB_RTMPDUMP_V)
	
	# rtmpdump.mk Build cleanup
	rm -rf $(BUILD_DIST)/rtmpdump \
		$(BUILD_DIST)/librtmp{1,-dev}

.PHONY: rtmpdump rtmpdump-package
