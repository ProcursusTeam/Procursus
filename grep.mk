ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

grep: setup
	cd grep && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking \
		--with-packager="$(DEB_MAINTAINER)"
	$(MAKE) -C grep
	$(FAKEROOT) $(MAKE) -C grep install

.PHONY: grep
