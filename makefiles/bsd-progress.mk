ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS          += bsd-progress
BSD_PROGRESS_VERSION := 9.99.81
BSD_PROGRESS_COMMIT  := a9bda63998e2f358b07a50a8dd4ed48100f9a9ee
DEB_BSD_PROGRESS_V   ?= $(BSD_PROGRESS_VERSION)

bsd-progress-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) \
		https://git.cameronkatri.com/bsd-progress/snapshot/bsd-progress-$(BSD_PROGRESS_COMMIT).tar.zst
	$(call EXTRACT_TAR,bsd-progress-$(BSD_PROGRESS_COMMIT).tar.zst,bsd-progress-$(BSD_PROGRESS_COMMIT),bsd-progress)

ifneq ($(wildcard $(BUILD_WORK)/bsd-progress/.build_complete),)
bsd-progress:
	@echo "Using previously built bsd-progress."
else
bsd-progress: bsd-progress-setup ncurses
	+$(MAKE) -C $(BUILD_WORK)/bsd-progress install \
		UNAME="Darwin" \
		PROG_PREFIX="bsd-" \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		DESTDIR="$(BUILD_STAGE)/bsd-progress"
	touch $(BUILD_WORK)/bsd-progress/.build_complete
endif

bsd-progress-package: bsd-progress-stage
	# bsd-progress.mk Package Structure
	rm -rf $(BUILD_DIST)/bsd-progress

	# bsd-progress.mk Prep bsd-progress
	cp -a $(BUILD_STAGE)/bsd-progress $(BUILD_DIST)

	# bsd-progress.mk Sign
	$(call SIGN,bsd-progress,general.xml)

	# bsd-progress.mk Make .debs
	$(call PACK,bsd-progress,DEB_BSD_PROGRESS_V)

	# bsd-progress.mk Build cleanup
	rm -rf $(BUILD_DIST)/bsd-progress

.PHONY: bsd-progress bsd-progress-package
