ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS          += apt-rdepends
APT-RDEPENDS_VERSION := 1.3.0
DEB_APT-RDEPENDS_V   ?= $(APT-RDEPENDS_VERSION)

apt-rdepends-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://deb.debian.org/debian/pool/main/a/apt-rdepends/apt-rdepends_$(APT-RDEPENDS_VERSION).orig.tar.gz
	$(call EXTRACT_TAR,apt-rdepends_$(APT-RDEPENDS_VERSION).orig.tar.gz,apt-rdepends-$(APT-RDEPENDS_VERSION),apt-rdepends)
	mkdir -p $(BUILD_STAGE)/apt-rdepends/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
ifeq (,$(shell which pod2man))
apt-rdepends:
	@echo "Please install pod2man to build apt-rdepends"
else ifneq ($(wildcard $(BUILD_WORK)/apt-rdepends/.build_complete),)
apt-rdepends:
	@echo "Using previously built apt-rdepends."
else
apt-rdepends: apt-rdepends-setup
	$(SED) -i '1s|.*|#!$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/perl|g' $(BUILD_WORK)/apt-rdepends/apt-rdepends
	$(MAKE) -C $(BUILD_WORK)/apt-rdepends install install-man prefix=$(BUILD_STAGE)/apt-rdepends/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	touch $(BUILD_WORK)/apt-rdepends/.build_complete
endif

apt-rdepends-package: apt-rdepends-stage
	# apt-rdepends.mk Package Structure
	rm -rf $(BUILD_DIST)/apt-rdepends

	# apt-rdepends.mk Prep apt-rdepends
	cp -a $(BUILD_STAGE)/apt-rdepends $(BUILD_DIST)/

	# apt-rdepends.mk Make .debs
	$(call PACK,apt-rdepends,DEB_APT-RDEPENDS_V)

	# apt-rdepends.mk Build cleanup
	rm -rf $(BUILD_DIST)/apt-rdepends

.PHONY: apt-rdepends apt-rdepends-package
