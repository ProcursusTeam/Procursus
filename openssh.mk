ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

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
	$(FAKEROOT) $(MAKE) -C openssh install \
		DESTDIR="$(BUILD_STAGE)/openssh"
	touch openssh/.build_complete
endif

.PHONY: openssh
