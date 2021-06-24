ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += file
FILE_VERSION   := 5.40
DEB_FILE_V     ?= $(FILE_VERSION)

file-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) ftp://ftp.astron.com/pub/file/file-$(FILE_VERSION).tar.gz{,.asc}
	$(call PGP_VERIFY,file-$(FILE_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,file-$(FILE_VERSION).tar.gz,file-$(FILE_VERSION),file)

ifneq ($(wildcard $(BUILD_WORK)/file/.build_complete),)
file:
	@echo "Using previously built file."
else
file: file-setup xz
	rm -rf $(BUILD_WORK)/file/native
	mkdir -p $(BUILD_WORK)/file/native
	+unset CC CFLAGS CXXFLAGS CPPFLAGS LDFLAGS; \
		cd $(BUILD_WORK)/file/native && $(BUILD_WORK)/file/configure; \
		$(MAKE) -C $(BUILD_WORK)/file/native
	cd $(BUILD_WORK)/file && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-libseccomp \
		--enable-fsect-man5
	+$(MAKE) -C $(BUILD_WORK)/file \
		FILE_COMPILE="$(BUILD_WORK)/file/native/src/file"
	+$(MAKE) -C $(BUILD_WORK)/file install \
		DESTDIR="$(BUILD_STAGE)/file"
	+$(MAKE) -C $(BUILD_WORK)/file install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/file/.build_complete
endif

file-package: file-stage
	# file.mk Package Structure
	rm -rf $(BUILD_DIST)/file $(BUILD_DIST)/libmagic{1,-dev}
	mkdir -p $(BUILD_DIST)/file/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man \
		$(BUILD_DIST)/libmagic1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,share} \
		$(BUILD_DIST)/libmagic-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,share/man}

	# file.mk Prep file
	cp -a $(BUILD_STAGE)/file/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/file/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/file/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 $(BUILD_DIST)/file/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# file.mk Prep libmagic1
	cp -a $(BUILD_STAGE)/file/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmagic.1.dylib $(BUILD_DIST)/libmagic1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/file/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5 $(BUILD_DIST)/libmagic1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
	cp -a $(BUILD_STAGE)/file/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/misc $(BUILD_DIST)/libmagic1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# file.mk Prep libmagic-dev
	cp -a $(BUILD_STAGE)/file/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libmagic.1.dylib) $(BUILD_DIST)/libmagic-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/file/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 $(BUILD_DIST)/libmagic-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# file.mk Sign
	$(call SIGN,file,general.xml)
	$(call SIGN,libmagic1,general.xml)

	# file.mk Make .debs
	$(call PACK,file,DEB_FILE_V)
	$(call PACK,libmagic1,DEB_FILE_V)
	$(call PACK,libmagic-dev,DEB_FILE_V)

	# file.mk Build cleanup
	rm -rf $(BUILD_DIST)/file $(BUILD_DIST)/libmagic{1,-dev}

.PHONY: file file-package
