ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += apr
APR_VERSION := 1.7.0
DEB_APR_V   ?= $(APR_VERSION)
apr-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://downloads.apache.org//apr/apr-$(APR_VERSION).tar.gz
	$(call EXTRACT_TAR,apr-$(APR_VERSION).tar.gz,apr-$(APR_VERSION),apr)
	$(call DO_PATCH,apr,apr,-p1)
ifneq ($(wildcard $(BUILD_WORK)/apr/.build_complete),)
apr:
	@echo "Using previously built apr."
else
apr: apr-setup uuid
	cd $(BUILD_WORK)/apr && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		ac_cv_file__dev_zero=yes \
			ac_cv_func_setpgrp_void=yes \
				apr_cv_process_shared_works=yes \
					apr_cv_mutex_robust_shared=no \
					apr_cv_tcp_nodelay_with_cork=yes \
						ac_cv_sizeof_struct_iovec=8 \
							apr_cv_mutex_recursive=yes
	+$(MAKE) -C $(BUILD_WORK)/apr all \
CC_FOR_BUILD=/usr/bin/clang
	+$(MAKE) -C $(BUILD_WORK)/apr install \
		DESTDIR="$(BUILD_BASE)"
		+$(MAKE) -C $(BUILD_WORK)/apr install \
		DESTDIR="$(BUILD_STAGE)/apr"
		ln -sf $(BUILD_STAGE)/apr/usr/bin/apr-1-config $(BUILD_STAGE)/apr/usr/bin/apr-config
	touch $(BUILD_WORK)/apr/.build_complete
endif

apr-package: apr-stage
	# apr.mk Package Structure
	rm -rf $(BUILD_DIST)/libapr1{,-dev}
	mkdir -p $(BUILD_DIST)/libapr1{,-dev}
	
	# apr.mk Prep libapr1
	cp -a $(BUILD_STAGE)/apr/usr/lib/*.dylib $(BUILD_DIST)/libapr1
	
	# apr.mk Prep libapr1-dev
	cp -a $(BUILD_STAGE)/apr/usr/{bin,include,lib/libapr-1.a,lib/apr.exp,lib/pkgconfig,lib/libapr-1.la} $(BUILD_DIST)/libapr1-dev
	# apr.mk Sign
	$(call SIGN,libapr1,general.xml)
	$(call SIGN,libapr1-dev,general.xml)
	
	# apr.mk Make .debs
	$(call PACK,libapr1,DEB_APR_V)
	$(call PACK,libapr1-dev,DEB_APR_V)
	
	# apr.mk Build cleanup
	rm -rf $(BUILD_DIST)/libapr1{,-dev}

	.PHONY: apr apr-package
