ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += gnu-getopt
GNU-GETOPT_VERSION := 2.37
DEB_GNU-GETOPT_V   ?= $(GNU-GETOPT_VERSION)

gnu-getopt-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://www.kernel.org/pub/linux/utils/util-linux/v2.37/util-linux-2.37.tar.xz
	$(call EXTRACT_TAR,util-linux-2.37.tar.xz,util-linux-$(GNU-GETOPT_VERSION),gnu-getopt)

ifneq ($(wildcard $(BUILD_WORK)/gnu-getopt/.build_complete),)
gnu-getopt:
	@echo "Using previously built gnu-getopt."
else
gnu-getopt: gnu-getopt-setup
	cd $(BUILD_WORK)/gnu-getopt && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-silent-rules
	+$(MAKE) -C $(BUILD_WORK)/gnu-getopt getopt misc-utils/getopt.1
	mkdir -p $(BUILD_STAGE)/gnu-getopt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
	$(INSTALL) -Dm755 $(BUILD_WORK)/gnu-getopt/getopt $(BUILD_STAGE)/gnu-getopt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/gnubin/getopt
	$(LN_S) ../libexec/gnubin/getopt $(BUILD_STAGE)/gnu-getopt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ggetopt
	$(INSTALL) -Dm644 $(BUILD_WORK)/gnu-getopt/misc-utils/getopt.1 $(BUILD_STAGE)/gnu-getopt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man1/ggetopt.1
	$(INSTALL) -Dm644 $(BUILD_WORK)/gnu-getopt/bash-completion/getopt $(BUILD_STAGE)/gnu-getopt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/bash-completion/ggetopt
	$(call AFTER_BUILD)
endif

gnu-getopt-package: gnu-getopt-stage
	# gnu-getopt.mk Package Structure
	rm -rf $(BUILD_DIST)/gnu-getopt

	# gnu-getopt.mk Prep gnu-getopt
	cp -a $(BUILD_STAGE)/gnu-getopt $(BUILD_DIST)

	# gnu-getopt.mk Sign
	$(call SIGN,gnu-getopt,general.xml)

	# gnu-getopt.mk Make .debs
	$(call PACK,gnu-getopt,DEB_GNU-GETOPT_V)

	# gnu-getopt.mk Build cleanup
	rm -rf $(BUILD_DIST)/gnu-getopt

.PHONY: gnu-getopt gnu-getopt-package
