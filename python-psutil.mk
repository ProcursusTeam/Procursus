ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += python-psutil
PYTHON-PSUTIL_VERSION := 5.8.0
DEB_PYTHON-PSUTIL_V   ?= $(PYTHON-PSUTIL_VERSION)

python-psutil-setup: setup
	wget -q -nc -P $(BUILD_SOURCE)  https://github.com/giampaolo/psutil/archive/refs/tags/release-$(PYTHON-PSUTIL_VERSION).tar.gz
	$(call EXTRACT_TAR,release-$(PYTHON-PSUTIL_VERSION).tar.gz,psutil-release-$(PYTHON-PSUTIL_VERSION),python-psutil)

ifneq ($(wildcard $(BUILD_WORK)/python-psutil/.build_complete),)
python-psutil:
	@echo "Using previously built python-psutil."
else
python-psutil: python-psutil-setup python3
	cd $(BUILD_WORK)/python-psutil && python3 ./setup.py install  --root $(BUILD_STAGE)/python-psutil

	touch $(BUILD_WORK)/psutil/.build_complete
endif

python-psutil-package: python-psutil-stage
    # python-psutil.mk Package Structure
	rm -rf $(BUILD_DIST)/python-psutil
	mkdir -p $(BUILD_DIST)/python-psutil

	# python-psutil.mk Prep python-psutil
	cp -a $(BUILD_STAGE)/python-psutil/usr $(BUILD_DIST)/python-psutil

	# python-psutil.mk Sign
	$(call SIGN,python-psutil,general.xml)

	# python-psutil.mk Make .debs
	call PACK,python-psutil,DEB_PYTHON-PSUTIL_V)

	# python-psutil.mk Build cleanup
	rm -rf $(BUILD_DIST)/psutil

.PHONY: python-psutil python-psutil-package
