ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += joe
JOE_VERSION := 4.6
DEB_JOE_V   ?= $(JOE_VERSION)

joe-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://sourceforge.net/projects/joe-editor/files/JOE%20sources/joe-$(JOE_VERSION)/joe-$(JOE_VERSION).tar.gz
	$(call EXTRACT_TAR,joe-$(JOE_VERSION).tar.gz,joe-$(JOE_VERSION),joe)

ifneq ($(wildcard $(BUILD_WORK)/joe/.build_complete),)
joe:
	@echo "Using previously built joe."
else
joe: joe-setup ncurses
	cd $(BUILD_WORK)/joe && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/joe
	+$(MAKE) -C $(BUILD_WORK)/joe install \
		DESTDIR=$(BUILD_STAGE)/joe
	touch $(BUILD_WORK)/joe/.build_complete
endif

joe-package: joe-stage
	# joe.mk Package Structure
	mkdir -p $(BUILD_DIST)/joe

	# joe.mk Prep joe
	cp -a $(BUILD_STAGE)/joe $(BUILD_DIST)

	# joe.mk Sign and Make .debs
	$(call SIGN,joe,general.xml)
	$(call PACK,joe,DEB_JOE_V)

	# joe.mk Build cleanup
	rm -rf $(BUILD_DIST)/joe

.PHONY: joe joe-package
