ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += sshpass
SSHPASS_VERSION := 1.09
DEB_SSHPASS_V   ?= $(SSHPASS_VERSION)

sshpass-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://deb.debian.org/debian/pool/main/s/sshpass/sshpass_$(SSHPASS_VERSION).orig.tar.gz
	$(call EXTRACT_TAR,sshpass_$(SSHPASS_VERSION).orig.tar.gz,sshpass-$(SSHPASS_VERSION),sshpass)

ifneq ($(wildcard $(BUILD_WORK)/sshpass/.build_complete),)
sshpass:
	@echo "Using previously built sshpass."
else
sshpass: sshpass-setup
	cd $(BUILD_WORK)/sshpass && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		ac_cv_func_malloc_0_nonnull=yes
	+$(MAKE) -C $(BUILD_WORK)/sshpass
	+$(MAKE) -C $(BUILD_WORK)/sshpass install \
		DESTDIR=$(BUILD_STAGE)/sshpass
	touch $(BUILD_WORK)/sshpass/.build_complete
endif

sshpass-package: sshpass-stage
	# sshpass.mk Package Structure
	rm -rf $(BUILD_DIST)/sshpass

	# sshpass.mk Prep sshpass
	cp -a $(BUILD_STAGE)/sshpass $(BUILD_DIST)

	# sshpass.mk Sign
	$(call SIGN,sshpass,general.xml)

	# sshpass.mk Make .debs
	$(call PACK,sshpass,DEB_SSHPASS_V)

	# sshpass.mk Build cleanup
	rm -rf $(BUILD_DIST)/sshpass

.PHONY: sshpass sshpass-package
