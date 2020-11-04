ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libedit
LIBEDIT_VERSION := 3.1
LIBEDIT_DATE    := 20191231
DEB_LIBEDIT_V   ?= $(LIBEDIT_VERSION)-$(LIBEDIT_DATE)

libedit-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://thrysoee.dk/editline/libedit-$(LIBEDIT_DATE)-$(LIBEDIT_VERSION).tar.gz
	$(call EXTRACT_TAR,libedit-$(LIBEDIT_DATE)-$(LIBEDIT_VERSION).tar.gz,libedit-$(LIBEDIT_DATE)-$(LIBEDIT_VERSION),libedit)

ifneq ($(wildcard $(BUILD_WORK)/libedit/.build_complete),)
libedit:
	@echo "Using previously built libedit."
else
libedit: libedit-setup ncurses
	cd $(BUILD_WORK)/libedit && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--with-examples=no
	+$(MAKE) -C $(BUILD_WORK)/libedit \
		LIBS=-lncursesw
	+$(MAKE) -C $(BUILD_WORK)/libedit install \
		DESTDIR="$(BUILD_STAGE)/libedit"
	+$(MAKE) -C $(BUILD_WORK)/libedit install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libedit/.build_complete
endif

libedit-package: libedit-stage
	# libedit.mk Package Structure
	rm -rf $(BUILD_DIST)/libedit{0,-dev}
	mkdir -p $(BUILD_DIST)/libedit{0,-dev}/usr/{lib,share/man}
	
	# libedit.mk Prep libedit0
	cp -a $(BUILD_STAGE)/libedit/usr/lib/libedit.0.dylib $(BUILD_DIST)/libedit0/usr/lib
	cp -a $(BUILD_STAGE)/libedit/usr/share/man/!(man3) $(BUILD_DIST)/libedit0/usr/share/man

	# libedit.mk Prep libedit-dev
	cp -a $(BUILD_STAGE)/libedit/usr/lib/!(libedit.0.dylib) $(BUILD_DIST)/libedit-dev/usr/lib
	cp -a $(BUILD_STAGE)/libedit/usr/share/man/man3 $(BUILD_DIST)/libedit-dev/usr/share/man
	cp -a $(BUILD_STAGE)/libedit/usr/include $(BUILD_DIST)/libedit-dev/usr
	
	# libedit.mk Sign
	$(call SIGN,libedit0,general.xml)
	
	# libedit.mk Make .debs
	$(call PACK,libedit0,DEB_LIBEDIT_V)
	$(call PACK,libedit-dev,DEB_LIBEDIT_V)
	
	# libedit.mk Build cleanup
	rm -rf $(BUILD_DIST)/libedit{0,-dev}

.PHONY: libedit libedit-package
