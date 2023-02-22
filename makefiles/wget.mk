ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += wget
WGET_VERSION := 1.21.3
DEB_WGET_V   ?= $(WGET_VERSION)-1

wget-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://ftpmirror.gnu.org/wget/wget-$(WGET_VERSION).tar.gz{$(comma).sig})
	$(call PGP_VERIFY,wget-$(WGET_VERSION).tar.gz)
	$(call EXTRACT_TAR,wget-$(WGET_VERSION).tar.gz,wget-$(WGET_VERSION),wget)

ifneq ($(wildcard $(BUILD_WORK)/wget/.build_complete),)
wget:
	@echo "Using previously built wget."
else
wget: wget-setup openssl pcre2 gettext libunistring libidn2
	cd $(BUILD_WORK)/wget && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-ssl=openssl \
		--with-openssl \
		--without-libpsl
	+$(MAKE) -C $(BUILD_WORK)/wget
	+$(MAKE) -C $(BUILD_WORK)/wget install \
		DESTDIR="$(BUILD_STAGE)/wget"
	$(call AFTER_BUILD)
endif

wget-package: wget-stage
	# wget.mk Package Structure
	rm -rf $(BUILD_DIST)/wget
	mkdir -p $(BUILD_DIST)/wget/$(MEMO_PREFIX)/{etc,$(MEMO_SUB_PREFIX)/{bin,share/man/man1}}

	# wget.mk Prep wget
	cp -a $(BUILD_STAGE)/wget/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/wget $(BUILD_DIST)/wget/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/wget/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/wget.1$(MEMO_MANPAGE_SUFFIX) $(BUILD_DIST)/wget/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/wget/$(MEMO_PREFIX)/etc/wgetrc $(BUILD_DIST)/wget/$(MEMO_PREFIX)/etc
	# wget.mk Sign
	$(call SIGN,wget,general.xml)

	# wget.mk Make .debs
	$(call PACK,wget,DEB_WGET_V)

	# wget.mk Build cleanup
	rm -rf $(BUILD_DIST)/wget

.PHONY: wget wget-package
