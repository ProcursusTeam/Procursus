ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += neofetch
NEOFETCH_VERSION := 7.3.11
DEB_NEOFETCH_V   ?= $(NEOFETCH_VERSION)

neofetch-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_WORK)/neofetch,https://github.com/hykilpikonna/hyfetch/raw/neofetch-$(NEOFETCH_VERSION)/neofetch{$(comma).1})
	mkdir -p $(BUILD_STAGE)/neofetch/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}
	sed -e '31s|=.*|="$(DEB_NEOFETCH_V)"|' -i $(BUILD_WORK)/neofetch/neofetch

ifneq ($(wildcard $(BUILD_WORK)/neofetch/.build_complete),)
neofetch:
	@echo "Using previously built neofetch."
else
neofetch: neofetch-setup
	$(INSTALL) -Dm755 $(BUILD_WORK)/neofetch/neofetch $(BUILD_STAGE)/neofetch/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(INSTALL) -Dm644 $(BUILD_WORK)/neofetch/neofetch.1 $(BUILD_STAGE)/neofetch/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	$(call AFTER_BUILD)
endif

neofetch-package: neofetch-stage
	# neofetch.mk Package Structure
	rm -rf $(BUILD_DIST)/neofetch

	# neofetch.mk Prep neofetch
	cp -a $(BUILD_STAGE)/neofetch $(BUILD_DIST)

	# neofetch.mk Make .debs
	$(call PACK,neofetch,DEB_NEOFETCH_V)

	# neofetch.mk Build cleanup
	rm -rf $(BUILD_DIST)/neofetch

.PHONY: neofetch neofetch-package
