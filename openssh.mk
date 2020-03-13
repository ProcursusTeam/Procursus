ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

ifneq ($(wildcard openssh/.build_complete),)
openssh:
	@echo "Using previously built openssh."
else
openssh: setup libressl
	cd openssh && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		UsePrivilegeSeparation=no \
		PermitRootLogin=yes
	$(MAKE) -C openssh
	$(FAKEROOT) $(MAKE) -C openssh install \
		DESTDIR="$(BUILD_STAGE)/openssh"
	touch openssh/.build_complete
endif

.PHONY: openssh
