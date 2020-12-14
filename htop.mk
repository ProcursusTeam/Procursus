ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += htop
HTOP_VERSION := 3.0.0
DEB_HTOP_V   ?= $(HTOP_VERSION)

htop-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/htop-$(HTOP_VERSION).tar.gz" ] && wget -q -nc -O$(BUILD_SOURCE)/htop-$(HTOP_VERSION).tar.gz https://github.com/htop-dev/htop/archive/$(HTOP_VERSION).tar.gz
	$(call EXTRACT_TAR,htop-$(HTOP_VERSION).tar.gz,htop-$(HTOP_VERSION),htop)

ifneq ($(wildcard $(BUILD_WORK)/htop/.build_complete),)
htop:
	@echo "Using previously built htop."
else
htop: htop-setup ncurses
	cd $(BUILD_WORK)/htop && ./autogen.sh
	cd $(BUILD_WORK)/htop && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-linux-affinity \
		ac_cv_lib_ncursesw_addnwstr=yes
	+$(MAKE) -C $(BUILD_WORK)/htop install \
		CFLAGS="$(CFLAGS) -U_XOPEN_SOURCE" \
		DESTDIR=$(BUILD_STAGE)/htop
	rm -rf $(BUILD_STAGE)/htop/usr/share/{applications,pixmaps}
	touch $(BUILD_WORK)/htop/.build_complete
endif

htop-package: htop-stage
	# htop.mk Package Structure
	rm -rf $(BUILD_DIST)/htop
	
	# htop.mk Prep htop
	cp -a $(BUILD_STAGE)/htop $(BUILD_DIST)

	# htop.mk Sign
	$(call SIGN,htop,general.xml)
	
	# htop.mk Make .debs
	$(call PACK,htop,DEB_HTOP_V)
	
	# htop.mk Build cleanup
	rm -rf $(BUILD_DIST)/htop

.PHONY: htop htop-package
