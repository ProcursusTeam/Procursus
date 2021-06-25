ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += txt2man
TXT2MAN_VERSION := 1.7.1
DEB_TXT2MAN_V   ?= $(TXT2MAN_VERSION)

txt2man-setup: setup
	$(call GITHUB_ARCHIVE,mvertes,txt2man,$(TXT2MAN_VERSION),master)
	$(call EXTRACT_TAR,txt2man-$(TXT2MAN_VERSION).tar.gz,txt2man-master,txt2man)

ifneq ($(wildcard $(BUILD_WORK)/txt2man/.build_complete),)
txt2man:
	@echo "Using previously built txt2man."
else
txt2man: txt2man-setup gawk
	+$(MAKE) -C $(BUILD_WORK)/txt2man
	+$(MAKE) -C $(BUILD_WORK)/txt2man install \
		prefix=$(BUILD_STAGE)/txt2man/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	touch $(BUILD_WORK)/txt2man/.build_complete
endif

txt2man-package: txt2man-stage
	# txt2man.mk Package structure
	mkdir -p $(BUILD_DIST)/txt2man
	cp -a $(BUILD_STAGE)/txt2man $(BUILD_DIST)

	# txt2man.mk Sign
	$(call SIGN,txt2man,general.xml)

	# txt2man.mk Make .debs
	$(call PACK,txt2man,DEB_TXT2MAN_V)

	# txt2man.mk Build cleanup
	rm -rf $(BUILD_DIST)/txt2man

.PHONY: txt2man txt2man-package
