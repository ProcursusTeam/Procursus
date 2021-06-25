ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += bastet
BASTET_VERSION := 0.43.2
DEB_BASTET_V   ?= $(BASTET_VERSION)

bastet-setup: setup
	$(call GITHUB_ARCHIVE,fph,bastet,$(BASTET_VERSION),$(BASTET_VERSION))
	$(call EXTRACT_TAR,bastet-$(BASTET_VERSION).tar.gz,bastet-$(BASTET_VERSION),bastet)
	$(call DO_PATCH,bastet,bastet,-p1)
	$(SED) -i 's/-lncurses/-lncursesw/' $(BUILD_WORK)/bastet/Makefile
	mkdir -p $(BUILD_STAGE)/bastet/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man6}

ifneq ($(wildcard $(BUILD_WORK)/bastet/.build_complete),)
bastet:
	@echo "Using previously built bastet."
else
bastet: bastet-setup ncurses libboost
	+$(MAKE) -C $(BUILD_WORK)/bastet all \
		CXX="$(CXX) $(CXXFLAGS)"
	cp -a $(BUILD_WORK)/bastet/bastet $(BUILD_STAGE)/bastet/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_WORK)/bastet/bastet.6 $(BUILD_STAGE)/bastet/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man6
	touch $(BUILD_WORK)/bastet/.build_complete
endif

bastet-package: bastet-stage
	# bastet.mk Package Structure
	rm -rf $(BUILD_DIST)/bastet

	# bastet.mk Prep bastet
	cp -a $(BUILD_STAGE)/bastet $(BUILD_DIST)

	# bastet.mk Sign
	$(call SIGN,bastet,general.xml)

	# bastet.mk Make .debs
	$(call PACK,bastet,DEB_BASTET_V)

	# bastet.mk Build cleanup
	rm -rf $(BUILD_DIST)/bastet

.PHONY: bastet bastet-package
