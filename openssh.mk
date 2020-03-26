ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

OPENSSH_VERSION := 8.2
DEB_OPENSSH_V   ?= $(OPENSSH_VERSION)

ifeq ($(UNAME),Linux)
EXTRA := INSTALL="/usr/bin/install -c --strip-program=$(STRIP)"
else
EXTRA :=
endif

ifneq ($(wildcard openssh/.build_complete),)
openssh:
	@echo "Using previously built openssh."
else
openssh: setup libressl
	if ! [ -f openssh/configure ]; then \
		cd openssh && autoreconf; \
	fi
	cd openssh && $(EXTRA) \
		./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--sysconfdir=/etc/ssh
	$(MAKE) -C openssh
	$(MAKE) -C openssh install \
		DESTDIR="$(BUILD_STAGE)/openssh"
	mkdir -p $(BUILD_STAGE)/openssh/Library/LaunchDaemons
	cp $(BUILD_INFO)/com.openssh.sshd.plist $(BUILD_STAGE)/openssh/Library/LaunchDaemons
	touch openssh/.build_complete
endif

openssh-package: openssh-stage
	# openssh.mk Package Structure
	rm -rf $(BUILD_DIST)/openssh
	mkdir -p $(BUILD_DIST)/openssh
	
	# openssh.mk Prep openssh
	$(FAKEROOT) cp -a $(BUILD_STAGE)/openssh/{usr,etc,var,Library} $(BUILD_DIST)/openssh
	
	# openssh.mk Sign
	$(call SIGN,openssh,general.xml)
	
	# openssh.mk Make .debs
	$(call PACK,openssh,DEB_OPENSSH_V)
	
	# openssh.mk Build cleanup
	rm -rf $(BUILD_DIST)/openssh

.PHONY: openssh openssh-package
