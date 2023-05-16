ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif


STRAPPROJECTS += dash
DASH_VERSION  := 0.5.12
DEB_DASH_V    ?= $(DASH_VERSION)

dash-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://git.kernel.org/pub/scm/utils/dash/dash.git/snapshot/dash-$(DASH_VERSION).tar.gz)
	$(call EXTRACT_TAR,dash-$(DASH_VERSION).tar.gz,dash-$(DASH_VERSION),dash)
	mkdir -p $(BUILD_STAGE)/dash/$(MEMO_PREFIX)/bin
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	sed -i 's|"/etc/profile|"$(MEMO_PREFIX)/etc/profile|' $(BUILD_WORK)/dash/src/main.c
	sed -i 's|PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin|PATH=$(shell printf "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\n" | tr ':' '\n' | sed "p; s|^|$(MEMO_PREFIX)|" | tr '\n' ':' | sed 's|:$$|\n|')|' $(BUILD_WORK)/dash/src/var.c
endif

ifneq ($(wildcard $(BUILD_WORK)/dash/.build_complete),)
dash:
	@echo "Using previously built dash."
else
dash: dash-setup libedit
	find $(BUILD_WORK)/dash -name '*.c' -exec sed -i 's/stat64/stat/g' "{}" \;
	cd $(BUILD_WORK)/dash && autoreconf -fi && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--exec-prefix="" \
		--with-libedit \
		--disable-static
	+$(MAKE) -C $(BUILD_WORK)/dash
	+$(MAKE) -C $(BUILD_WORK)/dash install \
		DESTDIR=$(BUILD_STAGE)/dash
	$(LN_S) $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/dash $(BUILD_STAGE)/dash/$(MEMO_PREFIX)/bin/sh
	$(LN_S) $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/dash $(BUILD_STAGE)/dash/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/sh
	$(call AFTER_BUILD)
endif

dash-package: dash-stage
	# dash.mk Package Structure
	rm -rf $(BUILD_DIST)/dash

	# dash.mk Prep dash
	cp -a $(BUILD_STAGE)/dash $(BUILD_DIST)

	# dash.mk Sign
	$(call SIGN,dash,general.xml)

	# dash.mk Make .debs
	$(call PACK,dash,DEB_DASH_V)

	# dash.mk Build cleanup
	rm -rf $(BUILD_DIST)/dash

.PHONY: dash dash-package
