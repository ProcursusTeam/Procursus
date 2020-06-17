ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

DOWNLOAD        += https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-$(OPENSSH_VERSION).tar.gz{,.asc}
ifeq ($(SSH_STRAP),1)
STRAPPROJECTS   += openssh
else
SUBPROJECTS     += openssh
endif
OPENSSH_VERSION := 8.3p1
DEB_OPENSSH_V   ?= $(OPENSSH_VERSION)

openssh-setup: setup
	$(call PGP_VERIFY,openssh-$(OPENSSH_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,openssh-$(OPENSSH_VERSION).tar.gz,openssh-$(OPENSSH_VERSION),openssh)
	$(call DO_PATCH,openssh,openssh,-p1)

ifneq ($(wildcard $(BUILD_WORK)/openssh/.build_complete),)
openssh:
	@echo "Using previously built openssh."
else
openssh: openssh-setup openssl
	if ! [ -f $(BUILD_WORK)/openssh/configure ]; then \
		cd $(BUILD_WORK)/openssh && autoreconf; \
	fi
	$(SED) -i '/HAVE_ENDIAN_H/d' $(BUILD_WORK)/openssh/config.h.in
	cd $(BUILD_WORK)/openssh && $(EXTRA) ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--sysconfdir=/etc/ssh
	+$(MAKE) -C $(BUILD_WORK)/openssh
	+$(MAKE) -C $(BUILD_WORK)/openssh install \
		DESTDIR="$(BUILD_STAGE)/openssh"
	mkdir -p $(BUILD_STAGE)/openssh/Library/LaunchDaemons
	cp $(BUILD_INFO)/com.openssh.sshd.plist $(BUILD_STAGE)/openssh/Library/LaunchDaemons
	cp $(BUILD_INFO)/sshd-keygen-wrapper $(BUILD_STAGE)/openssh/usr/libexec
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
