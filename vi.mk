ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += vi
VI_VERSION    := 070224
DEB_VI_V      ?= $(VI_VERSION)

vi-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://sources.archlinux.org/other/vi/ex-$(VI_VERSION).tar.xz
	$(call EXTRACT_TAR,ex-$(VI_VERSION).tar.xz,ex-$(VI_VERSION),vi)

ifneq ($(wildcard $(BUILD_WORK)/vi/.build_complete),)
vi:
	@echo "Using previously built vi."
else
vi: vi-setup ncurses
	$(SED) -i '/#include "ex_tty.h"/a #include <sys/ioctl.h>' $(BUILD_WORK)/vi/ex_tty.c
	$(SED) -i '/#include "ex_tty.h"/a #include <sys/ioctl.h>' $(BUILD_WORK)/vi/ex_subr.c
	$(SED) -i '/size ex/d' $(BUILD_WORK)/vi/Makefile
	$(SED) -i 's/ar /$(AR) /g' $(BUILD_WORK)/vi/libuxre/Makefile
	+$(MAKE) -C $(BUILD_WORK)/vi install \
		$(EXTRA) \
		PREFIX="/usr" \
		TERMLIB=ncursesw \
		PRESERVEDIR="/var/lib/ex" \
		LIBEXECDIR=/usr/lib/ex \
		FEATURES="-DCHDIR -DFASTTAG -DUCVISUAL -DMB -DBIT8" \
		DESTDIR="$(BUILD_STAGE)/vi"
	touch $(BUILD_WORK)/vi/.build_complete
endif
vi-package: vi-stage
	# vi.mk Package Structure
	rm -rf $(BUILD_DIST)/vi
	mkdir -p $(BUILD_DIST)/vi/usr/{bin,share/man/man1}
	
	# vi.mk Prep vi
	cp -a $(BUILD_STAGE)/vi/usr/bin/ex $(BUILD_DIST)/vi/usr/bin/ex-vi
	cp -a $(BUILD_STAGE)/vi/usr/lib $(BUILD_DIST)/vi/usr
	cp -a $(BUILD_STAGE)/vi/usr/share/man/man1/ex.1 $(BUILD_DIST)/vi/usr/share/man/man1/exa.1
	cp -a $(BUILD_STAGE)/vi/usr/share/man/man1/vi.1 $(BUILD_DIST)/vi/usr/share/man/man1/via.1
	cp -a $(BUILD_STAGE)/vi/var $(BUILD_DIST)/vi

	# vi.mk Sign
	$(call SIGN,vi,general.xml)
	
	# vi.mk Make .debs
	$(call PACK,vi,DEB_VI_V)
	
	# vi.mk Build cleanup
	rm -rf $(BUILD_DIST)/vi

.PHONY: vi vi-package
