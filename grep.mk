ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += grep
GREP_VERSION  := 3.5
DEB_GREP_V    ?= $(GREP_VERSION)-1

grep-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/grep/grep-$(GREP_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,grep-$(GREP_VERSION).tar.xz)
	$(call EXTRACT_TAR,grep-$(GREP_VERSION).tar.xz,grep-$(GREP_VERSION),grep)

ifneq ($(wildcard $(BUILD_WORK)/grep/.build_complete),)
grep:
	@echo "Using previously built grep."
else
grep: grep-setup pcre
	cd $(BUILD_WORK)/grep && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--disable-dependency-tracking \
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
	cp -a $(BUILD_STAGE)/grep $(BUILD_DIST)
	
	# grep.mk Sign
	$(call SIGN,grep,general.xml)
	
	# grep.mk Make .debs
	$(call PACK,grep,DEB_GREP_V)
	
	# grep.mk Build cleanup
	rm -rf $(BUILD_DIST)/grep

.PHONY: grep grep-package
