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
	rm -rf $(BUILD_DIST)/libboost*/
	mkdir -p $(BUILD_DIST)/libboost1.73-all-dev/usr/lib \
		$(BUILD_DIST)/libboost-{atomic,chrono,container,context,contract,coroutine,date-time,filesystem,graph,iostreams,locale,log,math,numpy,program-options,python,random,regex,serialization,stacktrace,system,test,thread,timer,type-erasure,wave}1.73.0/usr/lib \
		$(BUILD_DIST)/libboost1.73.0-all
	
	# libboost.mk Prep libboost1.73-all-dev
	cp -a $(BUILD_STAGE)/libboost/include $(BUILD_DIST)/libboost1.73-all-dev/usr/
	cp -a $(BUILD_STAGE)/libboost/lib/cmake $(BUILD_DIST)/libboost1.73-all-dev/usr/lib
	
	# libboost.mk Prep libboost-*1.73.0
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_atomic.dylib $(BUILD_DIST)/libboost-atomic1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_chrono.dylib $(BUILD_DIST)/libboost-chrono1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_container.dylib $(BUILD_DIST)/libboost-container1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_context.dylib $(BUILD_DIST)/libboost-context1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_contract.dylib $(BUILD_DIST)/libboost-contract1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_coroutine.dylib $(BUILD_DIST)/libboost-coroutine1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_date_time.dylib $(BUILD_DIST)/libboost-date-time1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_filesystem.dylib $(BUILD_DIST)/libboost-filesystem1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_graph.dylib $(BUILD_DIST)/libboost-graph1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_iostreams.dylib $(BUILD_DIST)/libboost-iostreams1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_locale.dylib $(BUILD_DIST)/libboost-locale1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_log{,_setup}.dylib $(BUILD_DIST)/libboost-log1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_math_*.dylib $(BUILD_DIST)/libboost-math1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_numpy*.dylib $(BUILD_DIST)/libboost-numpy1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_program_options.dylib $(BUILD_DIST)/libboost-program-options1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_python*.dylib $(BUILD_DIST)/libboost-python1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_random.dylib $(BUILD_DIST)/libboost-random1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_regex.dylib $(BUILD_DIST)/libboost-regex1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_{serialization,wserialization}.dylib $(BUILD_DIST)/libboost-serialization1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_stacktrace*.dylib $(BUILD_DIST)/libboost-stacktrace1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_system.dylib $(BUILD_DIST)/libboost-system1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_{prg_exec_monitor,unit_test_framework}.dylib $(BUILD_DIST)/libboost-test1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_thread.dylib $(BUILD_DIST)/libboost-thread1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_timer.dylib $(BUILD_DIST)/libboost-timer1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_type_erasure.dylib $(BUILD_DIST)/libboost-type-erasure1.73.0/usr/lib
	cp -a $(BUILD_STAGE)/libboost/lib/libboost_wave.dylib $(BUILD_DIST)/libboost-wave1.73.0/usr/lib
	
	# libboost.mk Sign
	$(call SIGN,libboost-atomic1.73.0,general.xml)
	$(call SIGN,libboost-chrono1.73.0,general.xml)
	$(call SIGN,libboost-container1.73.0,general.xml)
	$(call SIGN,libboost-context1.73.0,general.xml)
	$(call SIGN,libboost-contract1.73.0,general.xml)
	$(call SIGN,libboost-coroutine1.73.0,general.xml)
	$(call SIGN,libboost-date-time1.73.0,general.xml)
	$(call SIGN,libboost-filesystem1.73.0,general.xml)
	$(call SIGN,libboost-graph1.73.0,general.xml)
	$(call SIGN,libboost-iostreams1.73.0,general.xml)
	$(call SIGN,libboost-locale1.73.0,general.xml)
	$(call SIGN,libboost-log1.73.0,general.xml)
	$(call SIGN,libboost-math1.73.0,general.xml)
	$(call SIGN,libboost-numpy1.73.0,general.xml)
	$(call SIGN,libboost-program-options1.73.0,general.xml)
	$(call SIGN,libboost-python1.73.0,general.xml)
	$(call SIGN,libboost-random1.73.0,general.xml)
	$(call SIGN,libboost-regex1.73.0,general.xml)
	$(call SIGN,libboost-serialization1.73.0,general.xml)
	$(call SIGN,libboost-stacktrace1.73.0,general.xml)
	$(call SIGN,libboost-system1.73.0,general.xml)
	$(call SIGN,libboost-test1.73.0,general.xml)
	$(call SIGN,libboost-thread1.73.0,general.xml)
	$(call SIGN,libboost-timer1.73.0,general.xml)
	$(call SIGN,libboost-type-erasure1.73.0,general.xml)
	$(call SIGN,libboost-wave1.73.0,general.xml)
	
	# libboost.mk Make .debs
	$(call PACK,libboost1.73-all-dev,DEB_LIBBOOST_V)
	$(call PACK,libboost1.73.0-all,DEB_LIBBOOST_V)
	$(call PACK,libboost-atomic1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-chrono1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-container1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-context1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-contract1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-coroutine1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-date-time1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-filesystem1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-graph1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-iostreams1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-locale1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-log1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-math1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-numpy1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-program-options1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-python1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-random1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-regex1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-serialization1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-stacktrace1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-system1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-test1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-thread1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-timer1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-type-erasure1.73.0,DEB_LIBBOOST_V)
	$(call PACK,libboost-wave1.73.0,DEB_LIBBOOST_V)
	
	# libboost.mk Build cleanup
	rm -rf $(BUILD_DIST)/libboost*/

.PHONY: libboost libboost-package
