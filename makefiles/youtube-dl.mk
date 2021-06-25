ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += youtube-dl
YOUTUBE-DL_VERSION := 2021.05.16
DEB_YOUTUBE-DL_V   ?= $(YOUTUBE-DL_VERSION)

youtube-dl-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/ytdl-org/youtube-dl/releases/download/$(YOUTUBE-DL_VERSION)/youtube-dl-$(YOUTUBE-DL_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,youtube-dl-$(YOUTUBE-DL_VERSION).tar.gz)
	$(call EXTRACT_TAR,youtube-dl-$(YOUTUBE-DL_VERSION).tar.gz,youtube-dl-$(YOUTUBE-DL_VERSION),youtube-dl)
	$(call DO_PATCH,youtube-dl,youtube-dl,-p1)

ifneq ($(wildcard $(BUILD_WORK)/youtube-dl/.build_complete),)
youtube-dl:
	@echo "Using previously built youtube-dl."
else
youtube-dl: youtube-dl-setup
	+$(MAKE) -C $(BUILD_WORK)/youtube-dl install \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		MANDIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man \
		DESTDIR=$(BUILD_STAGE)/youtube-dl \
		PYTHON=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3
	touch $(BUILD_WORK)/youtube-dl/.build_complete
endif

youtube-dl-package: youtube-dl-stage
	# youtube-dl.mk Package Structure
	rm -rf $(BUILD_DIST)/youtube-dl
	mkdir -p $(BUILD_DIST)/youtube-dl

	# youtube-dl.mk Prep youtube-dl
	cp -a $(BUILD_STAGE)/youtube-dl $(BUILD_DIST)

	# youtube-dl.mk Make .debs
	$(call PACK,youtube-dl,DEB_YOUTUBE-DL_V)

	# youtube-dl.mk Build cleanup
	rm -rf $(BUILD_DIST)/youtube-dl

.PHONY: youtube-dl youtube-dl-package
