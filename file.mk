ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += file
FILE_VERSION   := 5.38
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
	rm -rf $(BUILD_WORK)/../../native/file
	mkdir -p $(BUILD_WORK)/../../native/file
	cd $(BUILD_WORK)/../../native/file && env -i $(BUILD_WORK)/file/configure
	+env -i $(MAKE) -C $(BUILD_WORK)/../../native/file
	cd $(BUILD_WORK)/file && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/file \
		CFLAGS="$(CFLAGS)" \
		FILE_COMPILE="$(BUILD_WORK)/../../native/file/src/file" \
		LIBS="$(BUILD_BASE)/usr/local/lib/liblzma.a -lbz2 -lz"
	+$(MAKE) -C $(BUILD_WORK)/file install \
		DESTDIR=$(BUILD_STAGE)/file
	touch $(BUILD_WORK)/file/.build_complete
endif

file-package: file-stage
	# file.mk Package Structure
	rm -rf $(BUILD_DIST)/file
	mkdir -p $(BUILD_DIST)/file
	
	# file.mk Prep file
	cp -a $(BUILD_STAGE)/file/usr $(BUILD_DIST)/file
	
	# file.mk Sign
	$(call SIGN,file,general.xml)
	
	# file.mk Make .debs
	$(call PACK,file,DEB_FILE_V)
	
	# file.mk Build cleanup
	rm -rf $(BUILD_DIST)/file

.PHONY: file file-package
