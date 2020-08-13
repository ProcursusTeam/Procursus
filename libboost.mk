ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libboost
LIBBOOST_FORMAT_V := 1_73_0
LIBBOOST_VERSION  := 1.73.0
DEB_LIBBOOST_V    ?= $(LIBBOOST_VERSION)

libboost-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://dl.bintray.com/boostorg/release/$(LIBBOOST_VERSION)/source/boost_$(LIBBOOST_FORMAT_V).tar.bz2
	$(call EXTRACT_TAR,boost_$(LIBBOOST_FORMAT_V).tar.bz2,boost_$(LIBBOOST_FORMAT_V),libboost)

ifneq ($(wildcard $(BUILD_WORK)/libboost/.build_complete),)
libboost:
	@echo "Using previously built libboost."
else
libboost: libboost-setup python3 bzip2 xz zstd
	cd $(BUILD_WORK)/libboost && unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS SYSROOT && ./bootstrap.sh \
		--prefix=/usr \
		--without-icu
	echo 'using clang : arm : $(CXX) : <compileflags>"$(CPPFLAGS)" <cflags>"$(CFLAGS)" <cxxflags>"$(CXXFLAGS)" <linkflags>"$(LDFLAGS)" ;' >> $(BUILD_WORK)/libboost/tools/build/src/user-config.jam
	cd $(BUILD_WORK)/libboost && ./b2 \
		--prefix=$(BUILD_STAGE)/libboost \
		threading=multi \
		abi=aapcs \
		toolset=clang-arm \
		link=shared \
		install
	cd $(BUILD_WORK)/libboost && ./b2 \
		--prefix=$(BUILD_BASE)/usr \
		threading=multi \
		abi=aapcs \
		toolset=clang-arm \
		link=shared \
		install
	touch $(BUILD_WORK)/libboost/.build_complete
endif

libboost-package: libboost-stage
	# libboost.mk Package Structure
	rm -rf $(BUILD_DIST)/libboost
	mkdir -p $(BUILD_DIST)/libboost
	
	# libboost.mk Prep libboost
	cp -a $(BUILD_STAGE)/libboost/usr $(BUILD_DIST)/libboost
	
	# libboost.mk Sign
	$(call SIGN,libboost,general.xml)
	
	# libboost.mk Make .debs
	$(call PACK,libboost,DEB_LIBBOOST_V)
	
	# libboost.mk Build cleanup
	rm -rf $(BUILD_DIST)/libboost

.PHONY: libboost libboost-package
