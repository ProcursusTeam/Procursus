ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += jlutil
JLUTIL_VERSION    := 1.0
DEB_JLUTIL_V      ?= $(JLUTIL_VERSION)

jlutil-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/jlutil-$(JLUTIL_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/jlutil-$(JLUTIL_VERSION).tar.gz \
			http://newosxbook.com/tools/jlutil.tgz
	mkdir -p $(BUILD_WORK)/jlutil
	tar xf $(BUILD_SOURCE)/jlutil-$(JLUTIL_VERSION).tar.gz -C $(BUILD_WORK)/jlutil

ifneq ($(wildcard $(BUILD_WORK)/jlutil/.build_complete),)
jlutil:
	@echo "Using previously built jlutil."
else
jlutil: jlutil-setup
	$(CC) $(CFLAGS) $(LDFLAGS) -DWANT_MAIN $(BUILD_WORK)/jlutil/*.c \
		-o $(BUILD_WORK)/jlutil/jlutil
	$(STRIP) $(BUILD_WORK)/jlutil/jlutil
	$(GINSTALL) -Dm755 $(BUILD_WORK)/jlutil/jlutil $(BUILD_STAGE)/jlutil/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/jlutil
	touch $(BUILD_WORK)/jlutil/.build_complete
endif

jlutil-package: jlutil-stage
	# jlutil.mk Package Structure
	rm -rf $(BUILD_DIST)/jlutil

	# jlutil.mk Prep jlutil
	cp -a $(BUILD_STAGE)/jlutil $(BUILD_DIST)/jlutil

	# jlutil.mk Sign
	$(call SIGN,jlutil,general.xml)

	# jlutil.mk Make .debs
	$(call PACK,jlutil,DEB_JLUTIL_V)

	# jlutil.mk Build cleanup
	rm -rf $(BUILD_DIST)/jlutil

.PHONY: jlutil jlutil-package
