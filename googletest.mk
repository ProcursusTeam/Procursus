ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += googletest
GOOGLETEST_VERSION := 1.10.0
DEB_GOOGLETEST_V   ?= $(GOOGLETEST_VERSION)

googletest-setup: setup
	$(call GITHUB_ARCHIVE,google,googletest,$(GOOGLETEST_VERSION),release-$(GOOGLETEST_VERSION))
	$(call EXTRACT_TAR,googletest-$(GOOGLETEST_VERSION).tar.gz,googletest-release-$(GOOGLETEST_VERSION),googletest)

ifneq ($(wildcard $(BUILD_WORK)/googletest/.build_complete),)
googletest:
	@echo "Using previously built googletest."
else
googletest: googletest-setup
	mkdir -p $(BUILD_WORK)/googletest/build
	cd $(BUILD_WORK)/googletest/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DBUILD_SHARED_LIBS=ON \
		-DCMAKE_INSTALL_LIBDIR=lib \
		-Dgtest_build_tests=OFF \
		..
	+$(MAKE) -C $(BUILD_WORK)/googletest/build
	+$(MAKE) -C $(BUILD_WORK)/googletest/build install \
		DESTDIR=$(BUILD_STAGE)/googletest
	+$(MAKE) -C $(BUILD_WORK)/googletest/build install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/googletest/.build_complete
endif

googletest-package: googletest-stage
	# googletest.mk Package Structure
	rm -rf $(BUILD_DIST)/{libg{test,mock}-dev,googletest{,-tools}}
	mkdir -p $(BUILD_DIST)/googletest/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/src/googletest \
		$(BUILD_DIST)/googletest-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/googletest-tools/generator} \
		$(BUILD_DIST)/libg{mock,test}-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib/pkgconfig}

	# googletest.mk Prep googletest
	cp -a $(BUILD_WORK)/googletest/googletest $(BUILD_DIST)/googletest/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/src/googletest
	cp -a $(BUILD_WORK)/googletest/googlemock $(BUILD_DIST)/googletest/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/src/googletest
	cp -a $(BUILD_WORK)/googletest/CMakeLists.txt $(BUILD_DIST)/googletest/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/src/googletest

	# googletest.mk Prep googletest-tools
	cp -a $(BUILD_WORK)/googletest/googlemock/scripts/generator/gmock_gen.py $(BUILD_DIST)/googletest-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gmock_gen
	cp -a $(BUILD_WORK)/googletest/googlemock/scripts/generator/cpp $(BUILD_DIST)/googletest-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/googletest-tools/generator

	# googletest.mk Prep libgmock-dev
	cp -a $(BUILD_STAGE)/googletest/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/gmock $(BUILD_DIST)/libgmock-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/googletest/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/gmock*.pc $(BUILD_DIST)/libgmock-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# googletest.mk Prep libgtest-dev
	cp -a $(BUILD_STAGE)/googletest/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/gtest $(BUILD_DIST)/libgtest-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/googletest/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/gtest*.pc $(BUILD_DIST)/libgtest-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig

	# googletest.mk Make .debs
	$(call PACK,googletest,DEB_GOOGLETEST_V)
	$(call PACK,googletest-tools,DEB_GOOGLETEST_V)
	$(call PACK,libgmock-dev,DEB_GOOGLETEST_V)
	$(call PACK,libgtest-dev,DEB_GOOGLETEST_V)

	# googletest.mk Build cleanup
	rm -rf $(BUILD_DIST)/{libg{test,mock}-dev,googletest{,-tools}}

.PHONY: googletest googletest-package
