ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += screen
SCREEN_VERSION := 4.8.0
DEB_SCREEN_V   ?= $(SCREEN_VERSION)-1

screen-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftp.gnu.org/gnu/screen/screen-$(SCREEN_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,screen-$(SCREEN_VERSION).tar.gz)
	$(call EXTRACT_TAR,screen-$(SCREEN_VERSION).tar.gz,screen-$(SCREEN_VERSION),screen)
	$(call DO_PATCH,screen,screen,-p1)

ifneq ($(wildcard $(BUILD_WORK)/screen/.build_complete),)
screen:
	@echo "Using previously built screen."
else
screen: screen-setup ncurses libxcrypt
	cd $(BUILD_WORK)/screen && ./autogen.sh
	cd $(BUILD_WORK)/screen && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--mandir=/usr/share/man \
		--enable-colors256 \
		--disable-pam \
		--with-sys-screenrc=/etc/screenrc
	+$(MAKE) -C $(BUILD_WORK)/screen install \
		DESTDIR="$(BUILD_STAGE)/screen"
	rm -f $(BUILD_STAGE)/screen/usr/bin/screen && mv $(BUILD_STAGE)/screen/usr/bin/screen{-$(SCREEN_VERSION),}
	mkdir -p $(BUILD_STAGE)/screen/etc
	cp -a $(BUILD_WORK)/screen/etc/etcscreenrc $(BUILD_STAGE)/screen/etc/screenrc
	touch $(BUILD_WORK)/screen/.build_complete
endif

screen-package: screen-stage
	# screen.mk Package Structure
	rm -rf $(BUILD_DIST)/screen
	
	# screen.mk Prep screen
	cp -a $(BUILD_STAGE)/screen $(BUILD_DIST)
	
	# screen.mk Sign
	$(call SIGN,screen,general.xml)
	
	# screen.mk Make .debs
	$(call PACK,screen,DEB_SCREEN_V)
	
	# screen.mk Build cleanup
	rm -rf $(BUILD_DIST)/screen

.PHONY: screen screen-package
