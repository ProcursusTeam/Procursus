ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS      += crontabs
CRONTABS_VERSION := 54
DEB_CRONTABS_V   ?= $(CRONTABS_VERSION)

crontabs-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://opensource.apple.com/tarballs/crontabs/crontabs-$(CRONTABS_VERSION).tar.gz
	$(call EXTRACT_TAR,crontabs-$(CRONTABS_VERSION).tar.gz,crontabs-$(CRONTABS_VERSION),crontabs)
	$(call DO_PATCH,crontabs,crontabs,-p1)
	mkdir -p $(BUILD_STAGE)/crontabs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin \
		$(BUILD_STAGE)/crontabs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/ \
		$(BUILD_STAGE)/crontabs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man{5,8} \
		$(BUILD_STAGE)/crontabs/$(MEMO_PREFIX)/Library/LaunchDaemons/ \
		$(BUILD_STAGE)/crontabs/$(MEMO_PREFIX)/etc/{newsyslog.d,defaults,periodic/{daily,weekly,monthly}}

ifneq ($(wildcard $(BUILD_WORK)/crontabs/.build_complete),)
crontabs:
	@echo "Using previously built crontabs."
else
crontabs: crontabs-setup
	$(SED) -i -e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' \
		-e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' \
		-e 's|@MEMO_ALT_PREFIX@|$(MEMO_ALT_PREFIX)|g' \
		$(BUILD_WORK)/crontabs/files/periodic.conf \
		$(BUILD_WORK)/crontabs/newsyslog/newsyslog.c \
		$(BUILD_WORK)/crontabs/newsyslog/pathnames.h \
		$(BUILD_WORK)/crontabs/periodic/periodic-wrapper.c \
		$(BUILD_WORK)/crontabs/periodic/periodic.sh
	+$(BMAKE) -C $(BUILD_WORK)/crontabs \
		$(DEFAULT_BMAKE_FLAGS)
	+$(BMAKE) -C $(BUILD_WORK)/crontabs install \
		$(DEFAULT_BMAKE_FLAGS) \
		DESTDIR=$(BUILD_STAGE)/crontabs
	gzip -d $(BUILD_STAGE)/crontabs/usr/share/man/man*/*.gz
	mv $(BUILD_STAGE)/crontabs/$(MEMO_PREFIX)/etc/periodic.conf $(BUILD_STAGE)/crontabs/$(MEMO_PREFIX)/etc/defaults/periodic.conf
	$(call AFTER_BUILD)
endif

crontabs-package: crontabs-stage
	# crontabs.mk Package Structure
	rm -rf $(BUILD_DIST)/crontabs
	
	# crontabs.mk Prep crontabs
	cp -a $(BUILD_STAGE)/crontabs $(BUILD_DIST)
	
	# crontabs.mk Sign
	$(call SIGN,crontabs,general.xml)
	
	# crontabs.mk Make .debs
	$(call PACK,crontabs,DEB_CRONTABS_V)
	
	# crontabs.mk Build cleanup
	rm -rf $(BUILD_DIST)/crontabs

.PHONY: crontabs crontabs-package

endif # ($(MEMO_TARGET),darwin-\*)
