ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += fail2ban
FAIL2BAN_VERSION := 0.11.2
DEB_FAIL2BAN_V   ?= $(FAIL2BAN_VERSION)

fail2ban-setup: setup
	$(call GITHUB_ARCHIVE,fail2ban,fail2ban,$(FAIL2BAN_VERSION),$(FAIL2BAN_VERSION))
	$(call EXTRACT_TAR,fail2ban-$(FAIL2BAN_VERSION).tar.gz,fail2ban-$(FAIL2BAN_VERSION),fail2ban)

ifneq ($(wildcard $(BUILD_WORK)/fail2ban/.build_complete),)
fail2ban:
	@echo "Using previously built fail2ban."
else
fail2ban: fail2ban-setup
	cd $(BUILD_WORK)/fail2ban && unset MACOSX_DEPLOYMENT_TARGET && python$(PYTHON3_MAJOR_V) ./setup.py \
		install \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		--root="$(BUILD_STAGE)/fail2ban" \
		--install-layout=deb
	touch $(BUILD_WORK)/fail2ban/.build_complete
endif
fail2ban-package: fail2ban-stage
	# fail2ban.mk Package Structure
	rm -rf $(BUILD_DIST)/fail2ban
	
	# fail2ban.mk Prep fail2ban
	cp -a $(BUILD_STAGE)/fail2ban $(BUILD_DIST)/
	
	#fail2ban.mk Make .debs
	$(call PACK,fail2ban,DEB_FAIL2BAN_V)
	
	# fail2ban.mk Build cleanup
	rm -rf $(BUILD_DIST)/fail2ban

.PHONY: fail2ban fail2ban-package
