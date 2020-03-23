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
	$(MAKE) -C $(BUILD_WORK)/gettext \
		LIBTERMINFO=-lncursesw \
		LTLIBTERMINFO=-lncursesw
	$(MAKE) -C $(BUILD_WORK)/gettext install \
		DESTDIR=$(BUILD_STAGE)/gettext
	$(MAKE) -C $(BUILD_WORK)/gettext install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/gettext/.build_complete
endif

.PHONY: gettext
