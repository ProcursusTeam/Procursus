ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += epoll-shim
EPOLL_SHIM_VERSION := 0.0.20220607
DEB_EPOLL_SHIM_V   ?= $(EPOLL_SHIM_VERSION)

epoll-shim-setup: setup
	$(call GITHUB_ARCHIVE,jiixyj,epoll-shim,$(EPOLL_SHIM_VERSION),$(EPOLL_SHIM_VERSION))
	$(call EXTRACT_TAR,epoll-shim-$(EPOLL_SHIM_VERSION).tar.gz,epoll-shim-$(EPOLL_SHIM_VERSION),epoll-shim)
	$(call DO_PATCH,epoll-shim,epoll-shim,-p1)
	mkdir -p $(BUILD_WORK)/epoll-shim/build

ifneq ($(wildcard $(BUILD_WORK)/epoll-shim/.build_complete),)
epoll-shim:
	@echo "Using previously built epoll-shim."
else
epoll-shim: epoll-shim-setup
	cd $(BUILD_WORK)/epoll-shim/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DCMAKE_INSTALL_PKGCONFIGDIR=lib/pkgconfig \
		-DBUILD_TESTING=OFF \
		..
	+$(MAKE) -C $(BUILD_WORK)/epoll-shim/build
	+$(MAKE) -C $(BUILD_WORK)/epoll-shim/build install \
		DESTDIR="$(BUILD_STAGE)/epoll-shim"
	$(call AFTER_BUILD)
endif

epoll-shim-package: epoll-shim-stage
	# epoll-shim.mk Package Structure
	rm -rf $(BUILD_DIST)/libepoll-shim{,-dev}

	# epoll-shim.mk Prep libepoll-shim
	cp -a $(BUILD_STAGE)/epoll-shim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libepoll-shim{,-interpose}.0.dylib $(BUILD_DIST)/libepoll-shim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# epoll-shim.mk Prep libepoll-shim-dev
	cp -a $(BUILD_STAGE)/epoll-shim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libepoll-shim-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/epoll-shim/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libepoll-shim{,-interpose}.dylib,pkgconfig} $(BUILD_DIST)/libepoll-shim-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# epoll-shim.mk Sign
	$(call SIGN,libepoll-shim,general.xml)

	# epoll-shim.mk Make .debs
	$(call PACK,libepoll-shim,DEB_EPOLL_SHIM_V)
	$(call PACK,libepoll-shim-dev,DEB_EPOLL_SHIM_V)

	# epoll-shim.mk Build cleanup
	rm -rf $(BUILD_DIST)/libepoll-shim{,-dev}

.PHONY: epoll-shim epoll-shim-package
