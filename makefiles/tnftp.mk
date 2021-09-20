ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += tnftp
TNFTP_VERSION := 20210827
DEB_TNFTP_V   ?= $(TNFTP_VERSION)

tnftp-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftp.netbsd.org/pub/NetBSD/misc/tnftp/tnftp-$(TNFTP_VERSION).tar.gz
	$(call EXTRACT_TAR,tnftp-$(TNFTP_VERSION).tar.gz,tnftp-$(TNFTP_VERSION),tnftp)
	sed -i '1 i\#define\ SSL_get_peer_certificate\ SSL_get1_peer_certificate' $(BUILD_WORK)/tnftp/src/ssl.c
ifneq ($(wildcard $(BUILD_WORK)/tnftp/.build_complete),)
tnftp:
	@echo "Using previously built tnftp."
else
tnftp: tnftp-setup openpam
	cd $(BUILD_WORK)/tnftp && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-ssl
	+$(MAKE) -C $(BUILD_WORK)/tnftp
	+$(MAKE) -C $(BUILD_WORK)/tnftp install \
	DESTDIR=$(BUILD_STAGE)/tnftp
	$(call AFTER_BUILD)
endif

tnftp-package: tnftp-stage
	# tnftp.mk Package Structure
	rm -rf $(BUILD_DIST)/tnftp

	# tnftp.mk Prep tnftp
	cp -a $(BUILD_STAGE)/tnftp $(BUILD_DIST)

	# tnftp.mk Sign
	$(call SIGN,tnftp,general.xml)

	# tnftp.mk Make .debs
	$(call PACK,tnftp,DEB_TNFTP_V)

	# tnftp.mk Build cleanup
	rm -rf $(BUILD_DIST)/tnftp

.PHONY: tnftp tnftp-package
