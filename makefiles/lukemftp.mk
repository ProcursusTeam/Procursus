ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += lukemftp
LUKEMFTP_VERSION := 16
DEB_LUKEMFTP_V   ?= $(LUKEMFTP_VERSION)

lukemftp-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://opensource.apple.com/tarballs/lukemftp/lukemftp-$(LUKEMFTP_VERSION).tar.gz
	$(call EXTRACT_TAR,lukemftp-$(LUKEMFTP_VERSION).tar.gz,lukemftp-$(LUKEMFTP_VERSION),lukemftp)

ifneq ($(wildcard $(BUILD_WORK)/lukemftp/.build_complete),)
lukemftp:
	@echo "Using previously built lukemftp."
else
lukemftp: lukemftp-setup ncurses
	cd $(BUILD_WORK)/lukemftp/tnftp && autoreconf -fiv
	cd $(BUILD_WORK)/lukemftp && ./tnftp/configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--without-socks
	+$(MAKE) -C $(BUILD_WORK)/lukemftp
	mkdir -p $(BUILD_STAGE)/lukemftp/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_WORK)/lukemftp/src/ftp $(BUILD_STAGE)/lukemftp/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin
	$(call AFTER_BUILD)
endif

lukemftp-package: lukemftp-stage
	# lukemftp.mk Package Structure
	rm -rf $(BUILD_DIST)/lukemftp

	# lukemftp.mk Prep lukemftp
	cp -a $(BUILD_STAGE)/lukemftp $(BUILD_DIST)

	# lukemftp.mk Make .debs
	$(call PACK,lukemftp,DEB_LUKEMFTP_V)

	# lukemftp.mk Build cleanup
	rm -rf $(BUILD_DIST)/lukemftp

.PHONY: lukemftp lukemftp-package
