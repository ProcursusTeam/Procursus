ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += uutils
UUTILS_VERSION   := 0.0.4
DEB_UUTILS_V     ?= $(UUTILS_VERSION)

uutils-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/uutils-$(UUTILS_VERSION).tar.gz" ] && wget -q -nc -O$(BUILD_SOURCE)/uutils-$(UUTILS_VERSION).tar.gz https://github.com/uutils/coreutils/archive/$(UUTILS_VERSION).tar.gz
	$(call EXTRACT_TAR,uutils-$(UUTILS_VERSION).tar.gz,coreutils-$(UUTILS_VERSION),uutils)
	$(call DO_PATCH,uutils,uutils,-p1)

ifneq ($(wildcard $(BUILD_WORK)/uutils/.build_complete),)
uutils:
	@echo "Using previously built uutils."
else
uutils: uutils-setup
	SDKROOT="$(TARGET_SYSROOT)" $(MAKE) -C $(BUILD_WORK)/uutils TARGET=$(RUST_TARGET)
	$(MAKE) -C $(BUILD_WORK)/uutils install TARGET=$(RUST_TARGET) DESTDIR=$(BUILD_STAGE)/uutils PREFIX=/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	touch $(BUILD_WORK)/uutils/.build_complete
endif

uutils-package: uutils-stage
	# uutils.mk Package Structure
	rm -rf $(BUILD_DIST)/uutils
	mkdir -p $(BUILD_DIST)/uutils/$(MEMO_PREFIX)/{bin,$(MEMO_SUB_PREFIX)/sbin}
	
	# uutils.mk Prep uutils
	cp -a $(BUILD_STAGE)/uutils $(BUILD_DIST)
ifneq ($(MEMO_SUB_PREFIX),)
	ln -s /$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/chown $(BUILD_DIST)/uutils/$(MEMO_PREFIX)/bin
	ln -s /$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{cat,chgrp,cp,date,dd,dir,echo,false,kill,ln,ls,mkdir,mknod,mktemp,mv,pwd,readlink,rm,rmdir,sleep,stty,su,touch,true,uname,vdir} $(BUILD_DIST)/uutils/$(MEMO_PREFIX)/bin
	mkdir -p $(BUILD_DIST)/uutils/$(MEMO_PREFIX)/etc/profile.d
	cp $(BUILD_INFO)/coreutils.sh $(BUILD_DIST)/uutils/$(MEMO_PREFIX)/etc/profile.d
endif
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	mkdir -p $(BUILD_DIST)/uutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/gnubin
	for bin in $(BUILD_DIST)/uutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*; do \
		ln -s /$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$$(echo $$bin | rev | cut -d/ -f1 | rev) $(BUILD_DIST)/uutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/gnubin/$$(echo $$bin | rev | cut -d/ -f1 | rev | cut -c2-); \
	done
endif

	# uutils.mk Sign
	$(call SIGN,uutils,general.xml)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(LDID) -S$(BUILD_INFO)/dd.xml $(BUILD_DIST)/uutils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/cat
	find $(BUILD_DIST)/uutils -name '.ldid*' -type f -delete
endif
	
	# uutils.mk Make .debs
	$(call PACK,uutils,DEB_UUTILS_V)
	
	# uutils.mk Build cleanup
	rm -rf $(BUILD_DIST)/uutils

.PHONY: uutils uutils-package
