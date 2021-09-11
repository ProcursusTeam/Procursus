ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += mosh
MOSH_COMMIT  := e023e81c08897c95271b4f4f0726ec165bb6e1bd
MOSH_VERSION := 1.3.2+git20210721.$(shell echo $(MOSH_COMMIT) | cut -c -7)
DEB_MOSH_V   ?= $(MOSH_VERSION)

mosh-setup: setup
	$(call GITHUB_ARCHIVE,mobile-shell,mosh,$(MOSH_COMMIT),$(MOSH_COMMIT))
	$(call EXTRACT_TAR,mosh-$(MOSH_COMMIT).tar.gz,mosh-$(MOSH_COMMIT),mosh)

ifneq ($(wildcard $(BUILD_WORK)/mosh/.build_complete),)
mosh:
	@echo "Using previously built mosh."
else
mosh: mosh-setup libprotobuf openssl ncurses
	cd $(BUILD_WORK)/mosh && autoreconf -fi
	cd $(BUILD_WORK)/mosh && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-ncursesw \
		--with-crypto-library=openssl \
		--disable-dependency-tracking \
		--enable-completion \
		TINFO_LIBS="-L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -lncursesw"
	+$(MAKE) -C $(BUILD_WORK)/mosh \
		CXX="$(CXX) -std=c++11"
	+$(MAKE) -C $(BUILD_WORK)/mosh install \
		DESTDIR=$(BUILD_STAGE)/mosh
	$(call AFTER_BUILD)
endif

mosh-package: mosh-stage
	# mosh.mk Package Structure
	rm -rf $(BUILD_DIST)/mosh
	
	# mosh.mk Prep mosh
	cp -a $(BUILD_STAGE)/mosh $(BUILD_DIST)
	
	# mosh.mk Sign
	$(call SIGN,mosh,general.xml)
	
	# mosh.mk Make .debs
	$(call PACK,mosh,DEB_MOSH_V)
	
	# mosh.mk Build cleanup
	rm -rf $(BUILD_DIST)/mosh

.PHONY: mosh mosh-package
