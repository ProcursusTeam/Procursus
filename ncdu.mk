ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += ncdu
NCDU_VERSION := 1.15.1
DEB_NCDU_V   ?= $(NCDU_VERSION)

ncdu-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://dev.yorhel.nl/download/ncdu-$(NCDU_VERSION).tar.gz
	$(call EXTRACT_TAR,ncdu-$(NCDU_VERSION).tar.gz,ncdu-$(NCDU_VERSION),ncdu)

ifneq ($(wildcard $(BUILD_WORK)/ncdu/.build_complete),)
ncdu:
	@echo "Using previously built ncdu."
else
ncdu: ncdu-setup ncurses
	cd $(BUILD_WORK)/ncdu && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/ncdu
	+$(MAKE) -C $(BUILD_WORK)/ncdu install \
		DESTDIR=$(BUILD_STAGE)/ncdu
	touch $(BUILD_WORK)/ncdu/.build_complete
endif

ncdu-package: ncdu-stage
	# ncdu.mk Package Structure
	rm -rf $(BUILD_DIST)/ncdu

	# ncdu.mk Prep ncdu
	cp -a $(BUILD_STAGE)/ncdu $(BUILD_DIST)

	# ncdu.mk Sign
	$(call SIGN,ncdu,general.xml)

	# ncdu.mk Make .debs
	$(call PACK,ncdu,DEB_NCDU_V)

	# ncdu.mk Build cleanup
	rm -rf $(BUILD_DIST)/ncdu

.PHONY: ncdu ncdu-package
