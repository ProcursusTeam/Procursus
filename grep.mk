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
		--disable-nls \
		--with-packager="$(DEB_MAINTAINER)"
	+$(MAKE) -C $(BUILD_WORK)/grep
	+$(MAKE) -C $(BUILD_WORK)/grep install \
		DESTDIR=$(BUILD_STAGE)/grep
	touch $(BUILD_WORK)/grep/.build_complete
endif

grep-package: grep-stage
	# grep.mk Package Structure
	rm -rf $(BUILD_DIST)/grep
	mkdir -p $(BUILD_DIST)/grep
	
	# grep.mk Prep grep
	$(FAKEROOT) cp -a $(BUILD_STAGE)/grep/usr $(BUILD_DIST)/grep
	
	# grep.mk Sign
	$(call SIGN,grep,general.xml)
	
	# grep.mk Make .debs
	$(call PACK,grep,DEB_GREP_V)
	
	# grep.mk Build cleanup
	rm -rf $(BUILD_DIST)/grep

.PHONY: grep grep-package
