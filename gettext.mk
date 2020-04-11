ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

GETTEXT_VERSION := 0.20.1
DEB_GETTEXT_V   ?= $(GETTEXT_VERSION)

ifneq ($(wildcard $(BUILD_WORK)/gettext/.build_complete),)
gettext:
	@echo "Using previously built gettext."
else
gettext: setup ncurses
	cd $(BUILD_WORK)/gettext && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-java \
		--disable-csharp \
		--without-libintl-prefix
	+$(MAKE) -C $(BUILD_WORK)/gettext \
		LIBTERMINFO=-lncursesw \
		LTLIBTERMINFO=-lncursesw
	+$(MAKE) -C $(BUILD_WORK)/gettext install \
		DESTDIR=$(BUILD_STAGE)/gettext
	+$(MAKE) -C $(BUILD_WORK)/gettext install \
		DESTDIR=$(BUILD_BASE)
	rm -rf $(BUILD_STAGE)/gettext/usr/share
	touch $(BUILD_WORK)/gettext/.build_complete
endif

gettext-package: gettext-stage
	# gettext.mk Package Structure
	rm -rf $(BUILD_DIST)/gettext
	mkdir -p $(BUILD_DIST)/gettext
	
	# gettext.mk Prep gettext
	$(FAKEROOT) cp -a $(BUILD_STAGE)/gettext/usr $(BUILD_DIST)/gettext
	
	# gettext.mk Sign
	$(call SIGN,gettext,general.xml)
	
	# gettext.mk Make .debs
	$(call PACK,gettext,DEB_GETTEXT_V)
	
	# gettext.mk Build cleanup
	rm -rf $(BUILD_DIST)/gettext

.PHONY: gettext gettext-package

