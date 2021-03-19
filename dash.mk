ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif


SUBPROJECTS   += dash
DASH_VERSION  := 0.5.11.3
DEB_DASH_V    ?= $(DASH_VERSION)

dash-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://git.kernel.org/pub/scm/utils/dash/dash.git/snapshot/dash-$(DASH_VERSION).tar.gz
	$(call EXTRACT_TAR,dash-$(DASH_VERSION).tar.gz,dash-$(DASH_VERSION),dash)

ifneq ($(wildcard $(BUILD_WORK)/dash/.build_complete),)
dash:
	@echo "Using previously built dash."
else
dash: dash-setup libedit
	$(FIND) $(BUILD_WORK)/dash -name '*.c' -exec $(SED) -i 's/stat64/stat/g' "{}" \;

	cd $(BUILD_WORK)/dash && ./autogen.sh && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX) \
		--bindir=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin \
		--mandir=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share/man \
		--exec-prefix="" \
		--with-libedit
		
	+$(MAKE) -C $(BUILD_WORK)/dash
	+$(MAKE) -C $(BUILD_WORK)/dash install \
		DESTDIR=$(BUILD_STAGE)/dash
	touch $(BUILD_WORK)/dash/.build_complete
endif

dash-package: dash-stage
	# dash.mk Package Structure
	rm -rf $(BUILD_DIST)/dash
	mkdir -p $(BUILD_DIST)/dash
	
	# dash.mk Prep dash
	cp -a $(BUILD_STAGE)/dash $(BUILD_DIST)
	
	# dash.mk Sign
	$(call SIGN,dash,general.xml)
	
	# dash.mk Make .debs
	$(call PACK,dash,DEB_DASH_V)
	
	# dash.mk Build cleanup
	rm -rf $(BUILD_DIST)/dash

.PHONY: dash dash-package
