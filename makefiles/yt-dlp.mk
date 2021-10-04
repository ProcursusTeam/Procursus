ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += yt-dlp
YT-DLP_VERSION := 2021.09.25
DEB_YT-DLP_V   ?= $(YT-DLP_VERSION)

yt-dlp-setup: setup
	$(call GITHUB_ARCHIVE,yt-dlp,yt-dlp,$(YT-DLP_VERSION),$(YT-DLP_VERSION))
	$(call EXTRACT_TAR,yt-dlp-$(YT-DLP_VERSION).tar.gz,yt-dlp-$(YT-DLP_VERSION),yt-dlp)
	$(call DO_PATCH,yt-dlp,yt-dlp,-p1)
	mkdir -p $(BUILD_STAGE)/yt-dlp/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/yt-dlp/.build_complete),)
yt-dlp:
	@echo "Using previously built yt-dlp."
else
yt-dlp: yt-dlp-setup
	+$(MAKE) -C $(BUILD_WORK)/yt-dlp install \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		MANDIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man \
		SYSCONFDIR=$(MEMO_PREFIX)/etc \
		DESTDIR=$(BUILD_STAGE)/yt-dlp \
		PYTHON=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3
	$(call AFTER_BUILD)
endif

yt-dlp-package: yt-dlp-stage
	# yt-dlp.mk Package Structure
	rm -rf $(BUILD_DIST)/yt-dlp
	cp -a $(BUILD_STAGE)/yt-dlp $(BUILD_DIST)

	# yt-dlp.mk Sign
	$(call SIGN,yt-dlp,general.xml)

	# yt-dlp.mk Make .debs
	$(call PACK,yt-dlp,DEB_YT-DLP_V)

	# yt-dlp.mk Build cleanup
	rm -rf $(BUILD_DIST)/yt-dlp

.PHONY: yt-dlp yt-dlp-package
