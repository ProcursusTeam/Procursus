ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

GREP_VERSION := 3.3
DEB_GREP_V   ?= $(GREP_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/grep/.build_complete),)
grep:
	@echo "Using previously built grep."
else
grep: setup pcre
	cd $(BUILD_WORK)/grep && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking \
		--with-packager="$(DEB_MAINTAINER)"
	$(MAKE) -C $(BUILD_WORK)/grep
	$(MAKE) -C $(BUILD_WORK)/grep install \
		DESTDIR=$(BUILD_STAGE)/grep
	touch $(BUILD_WORK)/grep/.build_complete
endif

.PHONY: grep
