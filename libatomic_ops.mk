ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += libatomic_ops
LIBATOMIC_OPS_VERSION := 7.6.10
DEB_LIBATOMIC_OPS_V   ?= $(LIBATOMIC_OPS_VERSION)

libatomic_ops-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/ivmai/libatomic_ops/releases/download/v$(LIBATOMIC_OPS_VERSION)/libatomic_ops-$(LIBATOMIC_OPS_VERSION).tar.gz
	$(call EXTRACT_TAR,libatomic_ops-$(LIBATOMIC_OPS_VERSION).tar.gz,libatomic_ops-$(LIBATOMIC_OPS_VERSION),libatomic_ops)

ifneq ($(wildcard $(BUILD_WORK)/libatomic_ops/.build_complete),)
libatomic_ops:
	@echo "Using previously built libatomic_ops."
else
libatomic_ops: libatomic_ops-setup
	cd $(BUILD_WORK)/libatomic_ops && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-shared=yes \
		--enable-static=no
	+$(MAKE) -C $(BUILD_WORK)/libatomic_ops
	+$(MAKE) -C $(BUILD_WORK)/libatomic_ops install \
		DESTDIR=$(BUILD_STAGE)/libatomic_ops
	+$(MAKE) -C $(BUILD_WORK)/libatomic_ops install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libatomic_ops/.build_complete
endif

libatomic_ops-package: libatomic_ops-stage
	# libatomic_ops.mk Package Structure
	rm -rf $(BUILD_DIST)/libatomic-ops-dev
	mkdir -p $(BUILD_DIST)/libatomic-ops-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libatomic_ops.mk Prep libatomic_ops
	cp -a $(BUILD_STAGE)/libatomic_ops/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/libatomic-ops-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libatomic_ops.mk Make .debs
	$(call PACK,libatomic-ops-dev,DEB_LIBATOMIC_OPS_V)

	# libatomic_ops.mk Build cleanup
	rm -rf $(BUILD_DIST)/libatomic-ops-dev

.PHONY: libatomic_ops libatomic_ops-package
