ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += man-db
MAN-DB_VERSION := 2.9.4
DEB_MAN-DB_V   ?= $(MAN-DB_VERSION)-4

man-db-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://download.savannah.gnu.org/releases/man-db/man-db-$(MAN-DB_VERSION).tar.xz{$(comma).asc})
	$(call PGP_VERIFY,man-db-$(MAN-DB_VERSION).tar.xz,asc)
	$(call EXTRACT_TAR,man-db-$(MAN-DB_VERSION).tar.xz,man-db-$(MAN-DB_VERSION),man-db)
	$(call DO_PATCH,man-db,man-db,-p1)
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	sed -i 's|LIBMAN = |LIBMAN = -lxcselect |' $(BUILD_WORK)/man-db/src/Makefile.{am,in}
endif
	sed -i "s|@ON_DEVICE_SDK_PATH@|$(ON_DEVICE_SDK_PATH)|g" $(BUILD_WORK)/man-db/src/man_db.conf.in

ifneq ($(wildcard $(BUILD_WORK)/man-db/.build_complete),)
man-db:
	@echo "Using previously built man-db."
else
man-db: man-db-setup libpipeline libgdbm gettext zstd
	cd $(BUILD_WORK)/man-db && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-cache-owner \
		--enable-nls \
		--with-nroff=groff \
		man_cv_prog_gnu_nroff=yes
	+$(MAKE) -C $(BUILD_WORK)/man-db \
		LDFLAGS="$(LDFLAGS) -lintl -Wl,-framework -Wl,CoreFoundation"
	+$(MAKE) -C $(BUILD_WORK)/man-db install \
		DESTDIR=$(BUILD_STAGE)/man-db
	$(call AFTER_BUILD,,,$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/man-db)
endif

man-db-package: man-db-stage
	# man-db.mk Package Structure
	rm -rf $(BUILD_DIST)/man-db
	mkdir -p $(BUILD_DIST)/man-db

	# man-db.mk Prep man-db
	cp -a $(BUILD_STAGE)/man-db $(BUILD_DIST)

	# man-db.mk Sign
	$(call SIGN,man-db,general.xml)

	# man-db.mk Make .debs
	$(call PACK,man-db,DEB_MAN-DB_V)

	# man-db.mk Build cleanup
	rm -rf $(BUILD_DIST)/man-db

.PHONY: man-db man-db-package
