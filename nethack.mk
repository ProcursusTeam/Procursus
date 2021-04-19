ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += nethack
NETHACK_VERSION := 3.7
DEB_NETHACK_V   ?= $(NETHACK_VERSION)

nethack-setup: setup
	rm -Rf $(BUILD_WORK)/nethack
	git clone --depth 1 --single-branch --branch NetHack-$(NETHACK_VERSION) https://github.com/nethack/nethack $(BUILD_WORK)/nethack
	mkdir -p $(BUILD_STAGE)/nethack/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/nethack/.build_complete),)
nethack:
	@echo "Using previously built nethack."
else
nethack: nethack-setup
	cd $(BUILD_WORK)/nethack && sys/unix/setup.sh sys/unix/hints/unix
	cd $(BUILD_WORK)/nethack && \
		touch include/nhlua.h && \
		make fetch-lua && \
		CFLAGS="$(CFLAGS)" \
		CXXFLAGS="$(CXXFLAGS)" \
		CPPFLAGS="$(CPPFLAGS)" \
		LDFLAGS="$(LDFLAGS)" \
		$(MAKE)
	cp -a $(BUILD_WORK)/nethack/src/nethack $(BUILD_STAGE)/nethack/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	touch $(BUILD_WORK)/nethack/.build_complete
endif

nethack-package: nethack-stage
	# nethack.mk Package Structure
	rm -rf $(BUILD_DIST)/nethack

	# nethack.mk Prep nethack
	cp -a $(BUILD_STAGE)/nethack $(BUILD_DIST)/

	# nethack.mk Sign
	$(call SIGN,nethack,general.xml)

	# nethack.mk Make .debs
	$(call PACK,nethack,DEB_NETHACK_V)

	# nethack.mk Build cleanup
	rm -rf $(BUILD_DIST)/nethack

.PHONY: nethack nethack-package
