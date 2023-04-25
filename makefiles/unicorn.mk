ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += unicorn
UNICORN_VERSION := 2.0.1.post1
DEB_UNICORN_V   ?= $(UNICORN_VERSION)

unicorn-setup: setup
	$(call GITHUB_ARCHIVE,unicorn-engine,unicorn,$(UNICORN_VERSION),$(UNICORN_VERSION))
	$(call EXTRACT_TAR,unicorn-$(UNICORN_VERSION).tar.gz,unicorn-$(UNICORN_VERSION),unicorn)
	$(call DO_PATCH,unicorn,unicorn,-p1)
	rm $(BUILD_WORK)/unicorn/qemu/include/tcg/tcg-apple-jit.h
	$(call DOWNLOAD_FILES,$(BUILD_WORK)/unicorn/qemu/include/tcg/,https://raw.githubusercontent.com/utmapp/qemu/80c0e30/include/tcg/tcg-apple-jit.h)
	mkdir -p $(BUILD_WORK)/unicorn/build

ifneq ($(wildcard $(BUILD_WORK)/unicorn/.build_complete),)
unicorn:
	@echo "Using previously built unicorn."
else
unicorn: unicorn-setup
	cd $(BUILD_WORK)/unicorn/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		..
	+$(MAKE) -C $(BUILD_WORK)/unicorn/build
	+$(MAKE) -C $(BUILD_WORK)/unicorn/build install \
		DESTDIR="$(BUILD_STAGE)/unicorn"
	cd $(BUILD_WORK)/unicorn/bindings/python && $(DEFAULT_SETUP_PY_ENV) python3 ./setup.py \
		build \
		--executable="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3" \
		install \
		--install-layout=deb \
		--root="$(BUILD_STAGE)/unicorn" \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"
	find $(BUILD_STAGE)/unicorn -name __pycache__ -prune -exec rm -rf {} \;
	$(call AFTER_BUILD,copy)
endif

unicorn-package: unicorn-stage
	# unicorn.mk Package Structure
	rm -rf $(BUILD_DIST)/{libunicorn{2,-dev},python3-unicorn}
	mkdir -p $(BUILD_DIST)/{libunicorn{2,-dev},python3-unicorn}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# unicorn.mk Prep libunicorn2
	cp -a $(BUILD_STAGE)/unicorn/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libunicorn.2.dylib $(BUILD_DIST)/libunicorn2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/

	# unicorn.mk Prep libunicorn-dev
	cp -a $(BUILD_STAGE)/unicorn/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libunicorn.{dylib,a}} $(BUILD_DIST)/libunicorn-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/
	cp -a $(BUILD_STAGE)/unicorn/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libunicorn-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/

	# unicorn.mk Prep python3-unicorn
	cp -a $(BUILD_STAGE)/unicorn/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python3 $(BUILD_DIST)/python3-unicorn/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/

	# unicorn.mk Sign
	$(call SIGN,libunicorn2,general.xml)

	# unicorn.mk Make .debs
	$(call PACK,libunicorn2,DEB_UNICORN_V)
	$(call PACK,libunicorn-dev,DEB_UNICORN_V)
	$(call PACK,python3-unicorn,DEB_UNICORN_V)

	# unicorn.mk Build cleanup
	rm -rf $(BUILD_DIST)/{libunicorn{2,-dev},python3-unicorn}

.PHONY: unicorn unicorn-package
