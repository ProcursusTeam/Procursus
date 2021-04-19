ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += nethack
NETHACK_COMMIT  := 2d2c584c961d4328044f587b1135eef216146d45
NETHACK_VERSION := 3.7+git20210419.$(shell echo $(NETHACK_COMMIT) | cut -c -7)
DEB_NETHACK_V   ?= $(NETHACK_VERSION)

nethack-setup: setup
	rm -Rf $(BUILD_WORK)/nethack
	$(call GITHUB_ARCHIVE,NetHack,NetHack,$(NETHACK_COMMIT),$(NETHACK_COMMIT))
	$(call EXTRACT_TAR,NetHack-$(NETHACK_COMMIT).tar.gz,NetHack-$(NETHACK_COMMIT),nethack)
	mkdir -p $(BUILD_STAGE)/nethack/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	sed -i 's/WINTTYLIB=-lncurses -ltinfo/WINTTYLIB=-lncurses/' $(BUILD_WORK)/nethack/sys/unix/hints/linux
	sed -i 's,PREFIX=.*/nh/install,'"PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"',' $(BUILD_WORK)/nethack/sys/unix/hints/linux
	sed -i 's,INSTDIR=.*,'"INSTDIR=$(BUILD_WORK)/nethack/BUILD"',' $(BUILD_WORK)/nethack/sys/unix/hints/linux

ifneq ($(wildcard $(BUILD_WORK)/nethack/.build_complete),)
nethack:
	@echo "Using previously built nethack."
else
nethack: nethack-setup ncurses
	cd $(BUILD_WORK)/nethack && sys/unix/setup.sh sys/unix/hints/linux
	cd $(BUILD_WORK)/nethack && \
		touch include/nhlua.h && \
		make fetch-lua && \
		CFLAGS="$(CFLAGS)" \
		CXXFLAGS="$(CXXFLAGS)" \
		CPPFLAGS="$(CPPFLAGS)" \
		LDFLAGS="$(LDFLAGS)" \
		$(MAKE)
	cd $(BUILD_WORK)/nethack && \
		$(MAKE) install
	cp -a $(BUILD_WORK)/nethack/BUILD/* $(BUILD_STAGE)/nethack/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	touch $(BUILD_WORK)/nethack/.build_complete
endif

nethack-package: nethack-stage
	# nethack.mk Package Structure
	rm -rf $(BUILD_DIST)/nethack
	mkdir -p $(BUILD_DIST)/nethack/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/games/lib/nethackdir
	touch $(BUILD_DIST)/nethack/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/games/lib/nethackdir/sysconf
	touch $(BUILD_DIST)/nethack/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/games/lib/nethackdir/perm

	# nethack.mk Prep nethack
	cp -a $(BUILD_STAGE)/nethack $(BUILD_DIST)/

	# nethack.mk Sign
	$(call SIGN,nethack,general.xml)

	# nethack.mk Make .debs
	$(call PACK,nethack,DEB_NETHACK_V)

	# nethack.mk Build cleanup
	rm -rf $(BUILD_DIST)/nethack

.PHONY: nethack nethack-package
