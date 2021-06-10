ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libboost
LIBBOOST_VERSION  := 1.76.0
DEB_LIBBOOST_V    ?= $(LIBBOOST_VERSION)

ifneq (,$(findstring amd64,$(MEMO_TARGET)))
LIBBOOST_CONFIGURE_ARGS := abi=sysv
else
LIBBOOST_CONFIGURE_ARGS := abi=aapcs
endif

libboost-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://boostorg.jfrog.io/artifactory/main/release/$(LIBBOOST_VERSION)/source/boost_$(shell echo $(LIBBOOST_VERSION) | $(SED) 's/\./_/g').tar.bz2
	$(call EXTRACT_TAR,boost_$(shell echo $(LIBBOOST_VERSION) | $(SED) 's/\./_/g').tar.bz2,boost_$(shell echo $(LIBBOOST_VERSION) | $(SED) 's/\./_/g'),libboost)

ifneq ($(wildcard $(BUILD_WORK)/libboost/.build_complete),)
libboost:
	@echo "Using previously built libboost."
else
libboost: libboost-setup xz zstd icu4c
	rm -rf $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_*
	$(BUILD_WORK)/libboost/tools/build/src/engine/build.sh --cxx="$(CXX_FOR_BUILD)" --cxxflags="-std=c++11 $(BUILD_CXXFLAGS)"
ifneq (,$(findstring amd64,$(MEMO_TARGET)))
	echo "using clang-darwin : x86 : $(CXX) : <compileflags>\"$(CPPFLAGS) -I$(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/$$(ls $(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include)\" <cflags>\"$(CFLAGS) -I$(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/$$(ls $(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include)\" <cxxflags>\"$(CXXFLAGS) -I$(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/$$(ls $(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include)\" <linkflags>\"$(LDFLAGS)\" ;" > $(BUILD_WORK)/libboost/tools/build/src/user-config.jam
else
	echo "using clang-darwin : arm : $(CXX) : <compileflags>\"$(CPPFLAGS) -I$(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/$$(ls $(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include)\" <cflags>\"$(CFLAGS) -I$(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/$$(ls $(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include)\" <cxxflags>\"$(CXXFLAGS) -I$(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/$$(ls $(BUILD_STAGE)/python3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include)\" <linkflags>\"$(LDFLAGS)\" ;" > $(BUILD_WORK)/libboost/tools/build/src/user-config.jam
endif
	cd $(BUILD_WORK)/libboost && $(BUILD_WORK)/libboost/tools/build/src/engine/b2 \
		--prefix=$(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--without-mpi \
		--without-graph_parallel \
		threading=multi \
		variant=release \
		cxxstd="14" \
		$(LIBBOOST_CONFIGURE_ARGS) \
		install
	cd $(BUILD_WORK)/libboost && $(BUILD_WORK)/libboost/tools/build/src/engine/b2 \
		--prefix=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--without-mpi \
		--without-graph_parallel \
		threading=multi \
		variant=release \
		cxxstd="14" \
		$(LIBBOOST_CONFIGURE_ARGS) \
		install
	# F u boost!
	for lib in $(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_*.dylib $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_*.dylib; do \
		$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/$$(basename $$lib .dylib).$(LIBBOOST_VERSION).dylib $$lib; \
		for linked in $$(otool -L $$lib | grep @rpath | sed 's/\ .*$$//' | tr -d '\011\013\014\015\040'); do \
			$(I_N_T) -change $$linked $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/$$(basename $$linked .dylib).$(LIBBOOST_VERSION).dylib $$lib; \
		done; \
		mv $$lib $$(dirname $$lib)/$$(basename $$lib .dylib).$(LIBBOOST_VERSION).dylib; \
		ln -s $$(basename $$lib .dylib).$(LIBBOOST_VERSION).dylib $$lib; \
	done
	touch $(BUILD_WORK)/libboost/.build_complete
endif

libboost-package: libboost-stage
	# libboost.mk Package Structure
	rm -rf $(BUILD_DIST)/libboost*/
	mkdir -p $(BUILD_DIST)/libboost-all-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libboost-{atomic,chrono,container,context,contract,coroutine,date-time,fiber,filesystem,graph,iostreams,json,locale,log,math,nowide,program-options,python,random,regex,serialization,stacktrace,system,test,thread,timer,type-erasure,wave}$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libboost$(LIBBOOST_VERSION)-all

	# libboost.mk Prep libboost-all-dev
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libboost-all-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(*$(LIBBOOST_VERSION)*) $(BUILD_DIST)/libboost-all-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libboost.mk Prep libboost-*$(LIBBOOST_VERSION)
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_atomic.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-atomic$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_chrono.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-chrono$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_container.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-container$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_context.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-context$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_contract.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-contract$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_coroutine.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-coroutine$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_date_time.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-date-time$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_fiber.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-fiber$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_filesystem.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-filesystem$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_graph.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-graph$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_iostreams.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-iostreams$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_json.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-json$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_locale.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-locale$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_log{,_setup}.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-log$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_math_*.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-math$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_nowide.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-nowide$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_program_options.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-program-options$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_python*.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-python$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_random.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-random$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_regex.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-regex$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_{,w}serialization.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-serialization$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_stacktrace*.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-stacktrace$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_system.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-system$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_{prg_exec_monitor,unit_test_framework}.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-test$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_thread.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-thread$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_timer.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-timer$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_type_erasure.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-type-erasure$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libboost/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libboost_wave.$(LIBBOOST_VERSION).dylib $(BUILD_DIST)/libboost-wave$(LIBBOOST_VERSION)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libboost.mk Sign
	$(call SIGN,libboost-atomic$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-chrono$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-container$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-context$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-contract$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-coroutine$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-date-time$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-fiber$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-filesystem$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-graph$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-iostreams$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-json$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-locale$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-log$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-math$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-nowide$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-program-options$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-python$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-random$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-regex$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-serialization$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-stacktrace$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-system$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-test$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-thread$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-timer$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-type-erasure$(LIBBOOST_VERSION),general.xml)
	$(call SIGN,libboost-wave$(LIBBOOST_VERSION),general.xml)

	# libboost.mk Make .debs
	$(call PACK,libboost-all-dev,DEB_LIBBOOST_V)
	$(call PACK,libboost$(LIBBOOST_VERSION)-all,DEB_LIBBOOST_V)
	$(call PACK,libboost-atomic$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-chrono$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-container$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-context$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-contract$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-coroutine$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-date-time$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-fiber$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-filesystem$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-graph$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-iostreams$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-json$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-locale$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-log$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-math$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-nowide$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-program-options$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-python$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-random$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-regex$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-serialization$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-stacktrace$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-system$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-test$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-thread$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-timer$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-type-erasure$(LIBBOOST_VERSION),DEB_LIBBOOST_V)
	$(call PACK,libboost-wave$(LIBBOOST_VERSION),DEB_LIBBOOST_V)

	# libboost.mk Build cleanup
	rm -rf $(BUILD_DIST)/libboost*/

.PHONY: libboost libboost-package
