ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

ifeq ($(SSH_STRAP),1)
STRAPPROJECTS   += openssh
else
SUBPROJECTS     += openssh
endif
OPENSSH_VERSION := 8.2
DEB_OPENSSH_V   ?= $(OPENSSH_VERSION)

openssh-setup: setup
	rm -rf $(BUILD_WORK)/openssh
	mkdir -p $(BUILD_WORK)/openssh

ifneq ($(wildcard $(BUILD_WORK)/openssh/.build_complete),)
openssh:
	@echo "Using previously built openssh."
else
openssh: openssh-setup openssl
	if ! [ -f $(BUILD_WORK)/openssh/configure ]; then \
		cd openssh && autoreconf; \
	fi
	$(SED) -i '/HAVE_ENDIAN_H/d' openssh/config.h.in
	cd $(BUILD_WORK)/openssh && $(EXTRA) \
		$(BUILD_ROOT)/openssh/configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--sysconfdir=/etc/ssh
	+$(MAKE) -C $(BUILD_WORK)/openssh
	+$(MAKE) -C $(BUILD_WORK)/openssh install \
		DESTDIR="$(BUILD_STAGE)/openssh"
	mkdir -p $(BUILD_STAGE)/openssh/Library/LaunchDaemons
	cp $(BUILD_INFO)/com.openssh.sshd.plist $(BUILD_STAGE)/openssh/Library/LaunchDaemons
	touch $(BUILD_WORK)/openssh/.build_complete
endif

openssh-package: openssh-stage
	# openssh.mk Package Structure
	rm -rf $(BUILD_DIST)/openssh
	mkdir -p $(BUILD_DIST)/openssh
	
	# openssh.mk Prep openssh
	cp -a $(BUILD_STAGE)/openssh/{usr,etc,var,Library} $(BUILD_DIST)/openssh
	
	# openssh.mk Sign
	$(call SIGN,openssh,general.xml)
	
	# openssh.mk Make .debs
	$(call PACK,openssh,DEB_OPENSSH_V)
	
	# openssh.mk Build cleanup
	rm -rf $(BUILD_DIST)/openssh

.PHONY: openssh openssh-package
