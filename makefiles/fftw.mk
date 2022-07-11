ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += fftw
FFTW_VERSION := 3.3.10
DEB_FFTW_V   ?= $(FFTW_VERSION)

fftw-setup: setup
	curl --silent -L -Z --create-dirs -C - --remote-name-all --output-dir$(BUILD_SOURCE) https://fftw.org/fftw-$(FFTW_VERSION).tar.gz
	$(call EXTRACT_TAR,fftw-$(FFTW_VERSION).tar.gz,fftw-$(FFTW_VERSION),fftw)

ifneq ($(wildcard $(BUILD_WORK)/fftw/.build_complete),)
fftw:
	@echo "Using previously built fftw."
else
fftw: fftw-setup openmp
	cd $(BUILD_WORK)/fftw && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-openmp \
		--enable-threads \
		--enable-single \
		OPENMP_CFLAGS="-Xpreprocessor -fopenmp -lomp"
	sed -i 's/|-fopenmp//' $(BUILD_WORK)/fftw/libtool
	+$(MAKE) -C $(BUILD_WORK)/fftw \
		OPENMP_CFLAGS="-Xpreprocessor -fopenmp -lomp"
	+$(MAKE) -C $(BUILD_WORK)/fftw install \
		DESTDIR=$(BUILD_STAGE)/fftw
	+$(MAKE) -C $(BUILD_WORK)/fftw clean
	cd $(BUILD_WORK)/fftw && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-openmp \
		--enable-threads \
		--enable-double \
		OPENMP_CFLAGS="-Xpreprocessor -fopenmp -lomp"
	sed -i 's/|-fopenmp//' $(BUILD_WORK)/fftw/libtool
	+$(MAKE) -C $(BUILD_WORK)/fftw \
		OPENMP_CFLAGS="-Xpreprocessor -fopenmp -lomp"
	+$(MAKE) -C $(BUILD_WORK)/fftw install \
		DESTDIR=$(BUILD_STAGE)/fftw
	+$(MAKE) -C $(BUILD_WORK)/fftw clean
	cd $(BUILD_WORK)/fftw && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-openmp \
		--enable-threads \
		--enable-long-double \
		OPENMP_CFLAGS="-Xpreprocessor -fopenmp -lomp"
	sed -i 's/|-fopenmp//' $(BUILD_WORK)/fftw/libtool
	+$(MAKE) -C $(BUILD_WORK)/fftw \
		OPENMP_CFLAGS="-Xpreprocessor -fopenmp -lomp"
	+$(MAKE) -C $(BUILD_WORK)/fftw install \
		DESTDIR=$(BUILD_STAGE)/fftw
	+$(MAKE) -C $(BUILD_WORK)/fftw clean
	$(call AFTER_BUILD,copy)
endif

fftw-package: fftw-stage
	# fftw.mk Package Structure
	rm -rf $(BUILD_DIST)/libfftw3-{bin,dev,double3,long3,single3,3}
	mkdir -p $(BUILD_DIST)/libfftw3-3 \
		$(BUILD_DIST)/libfftw3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libfftw3-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} \
		$(BUILD_DIST)/libfftw3-{double,long,single}3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# fftw.mk Prep libfftw3-dev
	cp -a $(BUILD_STAGE)/fftw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libfftw3{,f,l}{,_threads,_omp}.a \
		$(BUILD_DIST)/libfftw3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/
	cp -a $(BUILD_STAGE)/fftw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libfftw3{,f,l}{,_threads,_omp}.dylib \
		$(BUILD_DIST)/libfftw3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/
	cp -a $(BUILD_STAGE)/fftw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{cmake,pkgconfig} \
		$(BUILD_DIST)/libfftw3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/
	cp -a $(BUILD_STAGE)/fftw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		$(BUILD_DIST)/libfftw3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/
	
	# fftw.mk Prep libfftw3-bin
	cp -a $(BUILD_STAGE)/fftw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
		$(BUILD_DIST)/libfftw3-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/
	cp -a $(BUILD_STAGE)/fftw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man \
		$(BUILD_DIST)/libfftw3-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/
	
	# fftw.mk Prep libfftw3-double3
	cp -a $(BUILD_STAGE)/fftw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libfftw3{,_threads,_omp}.3.dylib \
		$(BUILD_DIST)/libfftw3-double3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/
	
	# fftw.mk Prep libfftw3-long3
	cp -a $(BUILD_STAGE)/fftw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libfftw3l{,_threads,_omp}.3.dylib \
		$(BUILD_DIST)/libfftw3-long3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/
	
	# fftw.mk Prep libfftw3-single3
	cp -a $(BUILD_STAGE)/fftw/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libfftw3f{,_threads,_omp}.3.dylib \
		$(BUILD_DIST)/libfftw3-single3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/
	
	# fftw.mk Sign
	$(call SIGN,libfftw3-bin,general.xml)
	$(call SIGN,libfftw3-double3,general.xml)
	$(call SIGN,libfftw3-long3,general.xml)
	$(call SIGN,libfftw3-single3,general.xml)
	
	# fftw.mk Make .debs
	$(call PACK,libfftw3-bin,DEB_FFTW_V)
	$(call PACK,libfftw3-dev,DEB_FFTW_V)
	$(call PACK,libfftw3-3,DEB_FFTW_V)
	$(call PACK,libfftw3-double3,DEB_FFTW_V)
	$(call PACK,libfftw3-long3,DEB_FFTW_V)
	$(call PACK,libfftw3-single3,DEB_FFTW_V)
	
	# fftw.mk Build cleanup
	rm -rf $(BUILD_DIST)/libfftw3-{bin,dev,double3,long3,single3,3}

.PHONY: fftw fftw-package
