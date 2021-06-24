ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS   += libedit
LIBEDIT_VERSION := 3.1
LIBEDIT_DATE    := 20210522
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
		$(DEFAULT_CONFIGURE_FLAGS) \
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
	mkdir -p $(BUILD_DIST)/libedit{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,share/man}

	# libedit.mk Prep libedit0
	cp -a $(BUILD_STAGE)/libedit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libedit.0.dylib $(BUILD_DIST)/libedit0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libedit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/!(man3) $(BUILD_DIST)/libedit0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# libedit.mk Prep libedit-dev
	cp -a $(BUILD_STAGE)/libedit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libedit.0.dylib) $(BUILD_DIST)/libedit-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libedit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 $(BUILD_DIST)/libedit-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
	cp -a $(BUILD_STAGE)/libedit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libedit-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libedit.mk Sign
	$(call SIGN,libedit0,general.xml)

	# libedit.mk Make .debs
	$(call PACK,libedit0,DEB_LIBEDIT_V)
	$(call PACK,libedit-dev,DEB_LIBEDIT_V)

	# libedit.mk Build cleanup
	rm -rf $(BUILD_DIST)/libedit{0,-dev}

.PHONY: libedit libedit-package
