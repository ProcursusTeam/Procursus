ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += progress
PROGRESS_VERSION := 0.16
DEB_PROGRESS_V   ?= $(PROGRESS_VERSION)

progress-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/progress-$(PROGRESS_VERSION).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/progress-$(PROGRESS_VERSION).tar.gz \
			https://github.com/Xfennec/progress/archive/v$(PROGRESS_VERSION).tar.gz
	$(call EXTRACT_TAR,progress-$(PROGRESS_VERSION).tar.gz,progress-$(PROGRESS_VERSION),progress)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	wget -P $(BUILD_WORK)/progress https://raw.githubusercontent.com/NetBSD/src/trunk/{lib/libc/gen/wordexp.c,include/wordexp.h}
	$(call DO_PATCH,progress,progress,-p1)
endif

ifneq ($(wildcard $(BUILD_WORK)/progress/.build_complete),)
progress:
	@echo "Using previously built progress."
else
progress: progress-setup ncurses
	+$(MAKE) -C $(BUILD_WORK)/progress install \
		UNAME="Darwin" \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		DESTDIR="$(BUILD_STAGE)/progress"
	touch $(BUILD_WORK)/progress/.build_complete
endif

progress-package: progress-stage
	# progress.mk Package Structure
	rm -rf $(BUILD_DIST)/progress
	
	# progress.mk Prep progress
	cp -a $(BUILD_STAGE)/progress $(BUILD_DIST)
	
	# progress.mk Make .debs
	$(call PACK,progress,DEB_PROGRESS_V)
	
	# progress.mk Build cleanup
	rm -rf $(BUILD_DIST)/progress

.PHONY: progress progress-package
