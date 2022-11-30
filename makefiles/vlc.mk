ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += vlc
VLC_VERSION := 3.0.18
DEB_VLC_V   ?= $(VLC_VERSION)

vlc-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://download.videolan.org/vlc/$(VLC_VERSION)/vlc-$(VLC_VERSION).tar.xz{$(comma).asc})
	$(call PGP_VERIFY,vlc-$(VLC_VERSION).tar.xz,asc)
	$(call EXTRACT_TAR,vlc-$(VLC_VERSION).tar.xz,vlc-$(VLC_VERSION),vlc)
	$(call DO_PATCH,vlc,vlc,-p1)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(call DO_PATCH,vlc-ios,vlc,-p1)
	sed -i 's/-framework,ApplicationServices//g' $(BUILD_WORK)/vlc/modules/access/Makefile.am
	sed -i 's/libaudiounit_ios_plugin_la_LDFLAGS = /libaudiounit_ios_plugin_la_LDFLAGS = -framework Foundation -lobjc /g' $(BUILD_WORK)/vlc/modules/audio_output/Makefile.am
	sed -i 's|-Wl,-framework,VideoToolbox|-Wl,-framework,VideoToolbox -Wl,-framework,UIKit|g' $(BUILD_WORK)/vlc/modules/{video_chroma,codec}/Makefile.am
	sed -i 's/-framework,Cocoa/-framework,Foundation/g' $(BUILD_WORK)/vlc/modules/video_output/Makefile.am
	sed -i 's|libvout_ios_plugin_la_LDFLAGS = |libvout_ios_plugin_la_LDFLAGS = -lGLESv2 -framework Foundation -lobjc |g' $(BUILD_WORK)/vlc/modules/video_output/Makefile.am
	sed -i 's|include <OpenGL/|include <GL/|g' $(BUILD_WORK)/vlc/modules/visualization/glspectrum.c
	sed -i 's/,-framework,OpenGL/,-lGL/g' $(BUILD_WORK)/vlc/modules/{video_output,access}/Makefile.am
	sed -i 's/-Wl,-lGLES,/-Wl,-framework,OpenGLES,/g' $(BUILD_WORK)/vlc/modules/video_output/Makefile.am
	sed -i 's|libglconv_cvpx_plugin_la_LDFLAGS = \$$|libglconv_cvpx_plugin_la_LDFLAGS = -Wl,$(BUILD_WORK)/vlc/modules/codec/.libs/vt_utils.o,-framework,CoreFoundation,-framework,CoreVideo $$|g' $(BUILD_WORK)/vlc/modules/video_output/Makefile.am
endif
	sed -i 's|libaudiotoolboxmidi_plugin_la_LDFLAGS += -Wl,-framework,CoreFoundation,-framework,AudioUnit,-framework,AudioToolbox|libaudiotoolboxmidi_plugin_la_LDFLAGS += -Wl,-framework,CoreFoundation,-framework,AudioToolbox,-framework,CoreAudio|g' $(BUILD_WORK)/vlc/modules/codec/Makefile.am
	sed -i 's|-framework,AudioUnit,|-framework,CoreAudio,|g' $(BUILD_WORK)/vlc/modules/audio_output/Makefile.am
	sed -i 's|libgl_plugin_la_LIBADD = |libgl_plugin_la_LIBADD = -lGLESv2 |g' $(BUILD_WORK)/vlc/modules/video_output/Makefile.am

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
VLC_EXTRA_DEPS := libaacs libbluray
VLC_OPTS := --enable-bluray \
	--enable-osx-notifications \
	--enable-macosx
else
VLC_EXTRA_DEPS :=
VLC_OPTS := --disable-osx-notifications \
	--disable-macosx \
	--disable-bluray \
	--disable-minimal-macosx
endif

ifeq (,$(findstring arm,$(MEMO_TARGET)))
VLC_OPTS += --enable-mmx \
	--enable-sse \
	--disable-neon \
	--disable-arm64
else
VLC_OPTS += --disable-mmx \
        --disable-sse \
	--disable-neon \
	--enable-arm64
endif
ifneq ($(wildcard $(BUILD_WORK)/vlc/.build_complete),)
vlc:
	@echo "Using previously built vlc."
else ifneq ($(call HAS_COMMAND,luac5.1),1)
vlc:
	@echo "Install lua5.1 before building"
else
vlc: vlc-setup aom dav1d ffmpeg fontconfig freetype frei0r gnutls lame libarchive libass libdvdcss libdvdnav libdvdread libpng16 libsoxr libssh2 libvidstab libvorbis libvpx libopencore-amr openjpeg libopus libx11 libxft libxcb luajit rav1e rtmpdump rubberband sdl2 libsnappy libspeex libsrt libtheora libwebp mesa x264 x265 libxvidcore xz libdca libtasn1 flac zstd p11-kit brotli libtiff glib2.0 libmpeg2 mpg123 libcaca libprotobuf libnfs libsmb2 libsamplerate $(VLC_EXTRA_DEPS)
	# VLC does not like it when static libraries are enabled!
	cd $(BUILD_WORK)/vlc && ./bootstrap && ./configure -C \
		$(shell echo '$(DEFAULT_CONFIGURE_FLAGS)' | sed 's/--enable-static//g' ) \
		--disable-static \
		--disable-debug \
		--with-macosx-sdk=$(TARGET_SYSROOT) \
		--enable-nfs \
		--enable-smb2 \
		--enable-macosx-avfoundation \
		--disable-qt \
		--disable-sparkle \
		--disable-update-check \
		--disable-vcd \
		--disable-dbus \
		--enable-archive \
		--enable-png \
		--enable-dvdnav \
		--enable-samplerate \
		--enable-dvdread \
		--enable-sftp \
		--enable-run-as-root \
		--enable-x264 \
		--enable-x265 \
		--with-x \
		--with-libintl-prefix=$(BUILD_BASE) \
		--disable-altivec \
		--disable-live555 \
		--disable-dc1394 \
		--disable-dv1394 \
		--disable-linsys \
		--enable-lua \
		--disable-opencv \
		--enable-libcddb \
		--disable-vnc \
		--disable-tiger \
		--enable-css \
		--enable-xcb \
		--enable-xvideo \
		--enable-freetype \
		--enable-fontconfig \
		--disable-svg \
		--disable-alsa \
		--disable-sndio \
		--disable-a52 \
		--disable-kate \
		--enable-gles2 \
		--enable-libmpeg2 \
		--enable-mpg123 \
		--enable-caca \
		$(VLC_OPTS) \
		LUA_CFLAGS="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/luajit-2.1" \
		LUA_LIBS="-lluajit-5.1" \
		LUAC="$(shell command -v luac5.1)" \
		CFLAGS="$(CFLAGS) -std=gnu17 -fcommon" \
		CXXFLAGS="$(CXXFLAGS) -std=gnu++17 -fcommon" \
		OBJCFLAGS="$(CFLAGS) -fcommon" \
		LIBS="-framework CFNetwork"
	+sed -i \
		-e 's/vlc_osx_LINK = \$$(LIBTOOL) \$$/vlc_osx_LINK = $$(LIBTOOL) --tag=CC $$/g' \
		-e 's/vlc_osx_static_LINK = \$$(LIBTOOL) \$$/vlc_osx_static_LINK = $$(LIBTOOL) --tag=CC $$/g' \
		-e 's|cd \$$(bindir); mv vlc-osx vlc|cd $(BUILD_STAGE)/vlc/$$(bindir); mv vlc-osx vlc|' \
		$(BUILD_WORK)/vlc/bin/Makefile # We sed in two stages as seding the prefix before compile with break some paths
	+$(MAKE) -C $(BUILD_WORK)/vlc
	+sed -i \
		-e 's| \$$(prefix)| $(BUILD_STAGE)/vlc/$$(prefix)|g' \
		-e 's| "\$$(prefix)| "$(BUILD_STAGE)/vlc/$$(prefix)|g' \
		$(BUILD_WORK)/vlc/Makefile
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	+$(MAKE) -C $(BUILD_WORK)/vlc -j1 --output-sync=target VLC.app \
		DESTDIR=$(BUILD_STAGE)/vlc \
		CONTRIB_DIR=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
else
	+$(MAKE) -C $(BUILD_WORK)/vlc -j1 --output-sync=target install \
		DESTDIR=$(BUILD_STAGE)/vlc
endif
	find $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins -name '*.la' -delete
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	rm -f $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/access/libshm_plugin.dylib
	for file in $$(find $(BUILD_STAGE)/vlc -type f -exec sh -c "file -ib '{}' | grep -q 'x-mach-binary; charset=binary'" \; -print); do \
		$(I_N_T) -change '@rpath/libvlc.dylib' '$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libvlc.5.dylib' -change '@rpath/libvlccore.dylib' '$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libvlccore.9.dylib' $${file};  \
	done
else
	mkdir -p $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)/Applications
	cp -a $(BUILD_WORK)/vlc/VLC.app $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)/Applications
	rm -rf $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/macosx
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)/Applications/VLC.app/Contents/MacOS/share/. $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	rm -rf $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)/Applications/VLC.app/Contents/MacOS/{share,plugins,VLC,lib/*}
	$(I_N_T) -change '@rpath/libexpat.1.dylib' '/usr/lib/libexpat.1.dylib' $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/codec/liblibass_plugin.dylib
	$(I_N_T) -change '@rpath/libexpat.1.dylib' '/usr/lib/libexpat.1.dylib' $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc//plugins/access/liblibbluray_plugin.dylib
endif
	$(I_N_T) -add_rpath $(MEMO_PREFIX)/lib/vlc $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/video_output/libxcb_xv_plugin.dylib
	$(I_N_T) -add_rpath $(MEMO_PREFIX)/lib/vlc $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/video_output/libxcb_x11_plugin.dylib
	$(call AFTER_BUILD,copy)
endif

vlc-package: vlc-stage
	# vlc.mk Package Structure
	rm -rf $(BUILD_DIST)/{vlc.app,vlc{,-bin,-data,-l10n,-plugin-{access-extra,base,video-output,video-splitter,visualization}},libvlc{-bin,-dev,5,core{9,-dev}}}
	mkdir -p $(BUILD_DIST)/{vlc{,-bin,-data,-l10n,-plugin-{access-extra,base,video-output,video-splitter,visualization}},libvlc{-bin,-dev,5,core{9,-dev}}}
	mkdir -p $(BUILD_DIST)/{vlc-{bin,data,l10n,plugin-{access-extra,base,video-output,video-splitter,visualization}},libvlc{-bin,-dev,5,core{9,-dev}}}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/vlc-{bin,data,l10n}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	mkdir -p $(BUILD_DIST)/vlc-plugin-{base,access-extra,video-output,video-splitter,visualization}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins
	mkdir -p $(BUILD_DIST)/vlc-plugin-base/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/{video_output,access_output,access}
	mkdir -p $(BUILD_DIST)/vlc-plugin-access-extra/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/{access,access_output,video_output}
	mkdir -p $(BUILD_DIST)/vlc-plugin-video-output/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/video_output
	mkdir -p $(BUILD_DIST)/libvlc{-bin,-dev,5,core{9,-dev}}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libvlc{core,}-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include/vlc}
	mkdir -p $(BUILD_DIST)/libvlc{-bin,core-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc
	mkdir -p $(BUILD_DIST)/vlc.app/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/vlc,share,bin}

	# vlc.mk Prep vlc
	# vlc.mk Prep vlc-bin
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/vlc-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man $(BUILD_DIST)/vlc-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	$(LN_SR) $(BUILD_DIST)/vlc-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{,c}vlc.1$(MEMO_MANPAGE_SUFFIX)
	$(LN_SR) $(BUILD_DIST)/vlc-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{,n}vlc.1$(MEMO_MANPAGE_SUFFIX)
	$(LN_SR) $(BUILD_DIST)/vlc-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{,r}vlc.1$(MEMO_MANPAGE_SUFFIX)

	# vlc.mk Prep vlc-data
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{vlc,icons} $(BUILD_DIST)/vlc-data/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{hrtfs,lua} $(BUILD_DIST)/vlc-data/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
endif

	# vlc.mk Prep vlc-plugin-base
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/lua $(BUILD_DIST)/vlc-plugin-base/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/{audio_mixer,meta_engine,audio_output,gui,audio_filter,codec,control,stream_extractor,demux,keystore,logger,misc,mux,packetizer,services_discovery,spu,stream_filter,stream_out,text_renderer,video_chroma,video_filter} $(BUILD_DIST)/vlc-plugin-base/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/access/!(libaccess_srt|libvnc|libxcb_screen|libaccess_output_srt)_plugin.dylib $(BUILD_DIST)/vlc-plugin-base/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/access
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/video_output/lib{yuv,vdummy}_plugin.dylib $(BUILD_DIST)/vlc-plugin-base/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/video_output
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/access_output/!(libaccess_output_srt_plugin.dylib) $(BUILD_DIST)/vlc-plugin-base/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/access_output

	# vlc.mk Prep vlc-plugin-access-extra
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/access/{libaccess_srt,libxcb_screen}_plugin.dylib $(BUILD_DIST)/vlc-plugin-access-extra/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/access
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/access_output/libaccess_output_srt_plugin.dylib $(BUILD_DIST)/vlc-plugin-access-extra/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/access_output

	# vlc.mk Prep vlc-plugin-video-output
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/video_output/!(libfb|libvdummy|libvmem|libyuv)_plugin.dylib $(BUILD_DIST)/vlc-plugin-video-output/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/video_output
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/libvlc_xcb_events.{,0.}dylib $(BUILD_DIST)/vlc-plugin-video-output/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc

	# vlc.mk Prep vlc-plugin-video-splitter
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/video_splitter $(BUILD_DIST)/vlc-plugin-video-splitter/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins

	# vlc.mk Prep vlc-plugin-visualization
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins/visualization $(BUILD_DIST)/vlc-plugin-visualization/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins

	# vlc.mk Prep vlc-l10n
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale $(BUILD_DIST)/vlc-l10n/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# vlc.mk Prep libvlc5
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libvlc.5.dylib $(BUILD_DIST)/libvlc5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# vlc.mk Prep libvlccore9
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libvlccore.9.dylib $(BUILD_DIST)/libvlc5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	# vlc.mk Prep vlc.app
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)/Applications $(BUILD_DIST)/vlc.app/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	$(LN_S) $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/libvlc_xcb_events.0.dylib $(BUILD_DIST)/vlc.app/$(MEMO_PREFIX)/Applications/VLC.app/Contents/MacOS/lib/libvlc_xcb_events.0.dylib
	$(LN_S) $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/libvlccore.dylib $(BUILD_DIST)/vlc.app/$(MEMO_PREFIX)/Applications/VLC.app/Contents/MacOS/lib/libvlccore.9.dylib
	$(LN_S) $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/libvlc.5.dylib $(BUILD_DIST)/vlc.app/$(MEMO_PREFIX)/Applications/VLC.app/Contents/MacOS/lib/libvlc.5.dylib
	$(LN_S) $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale $(BUILD_DIST)/vlc.app/$(MEMO_PREFIX)/Applications/VLC.app/Contents/MacOS/share
	# Please note that the directory structure is different, however symlink it anyways
	$(LN_S) $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/plugins $(BUILD_DIST)/vlc.app/$(MEMO_PREFIX)/Applications/VLC.app/Contents/MacOS/plugins
	$(LN_S) $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/vlc-cache-gen $(BUILD_DIST)/vlc.app/$(MEMO_PREFIX)/Applications/VLC.app/Contents/MacOS/vlc-cache-gen
	$(LN_S) $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/vlc $(BUILD_DIST)/vlc.app/$(MEMO_PREFIX)/Applications/VLC.app/Contents/MacOS/VLC
endif

	# vlc.mk Prep libvlc-dev
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libvlc.dylib $(BUILD_DIST)/libvlc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/libvlc.pc $(BUILD_DIST)/libvlc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/vlc/{deprecated,vlc,libvlc_}*.h $(BUILD_DIST)/libvlc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/vlc

	# vlc.mk Prep libvlc-bin
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/vlc-cache-gen $(BUILD_DIST)/libvlc-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc

	# vlc.mk Prep libvlccore-dev
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libvlccore.dylib $(BUILD_DIST)/libvlccore-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/vlc-plugin.pc $(BUILD_DIST)/libvlccore-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/vlc/plugins $(BUILD_DIST)/libvlccore-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/vlc
	cp -a $(BUILD_STAGE)/vlc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc/libcompat.a $(BUILD_DIST)/libvlccore-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/vlc

	# vlc.mk Sign
	$(call SIGN,vlc-bin,vlc.xml,vlc-macos.xml)
	$(call SIGN,vlc-plugin-base,vlc.xml,vlc-macos.xml)
	$(call SIGN,vlc-plugin-access-extra,vlc.xml,vlc-macos.xml)
	$(call SIGN,vlc-plugin-video-output,vlc.xml,vlc-macos.xml)
	$(call SIGN,vlc-plugin-video-splitter,vlc.xml,vlc-macos.xml)
	$(call SIGN,vlc-plugin-visualization,vlc.xml,vlc-macos.xml)
	$(call SIGN,libvlc5,vlc.xml,vlc-macos.xml)
	$(call SIGN,libvlccore9,vlc.xml,vlc-macos.xml)
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	# codesign VLC.app **correctly**
	codesign $(MEMO_CODESIGN_EXTRA_FLAGS) -fs - $(BUILD_DIST)/vlc.app/$(MEMO_PREFIX)/Applications/VLC.app || true # .jar files moment
endif
	$(call SIGN,libvlc-bin,vlc.xml,vlc-macos.xml)


	# vlc.mk Make .debs
	$(call PACK,vlc,DEB_VLC_V)
	$(call PACK,vlc-bin,DEB_VLC_V)
	$(call PACK,vlc-data,DEB_VLC_V)
	$(call PACK,vlc-l10n,DEB_VLC_V)
	$(call PACK,vlc-plugin-base,DEB_VLC_V)
	$(call PACK,vlc-plugin-access-extra,DEB_VLC_V)
	$(call PACK,vlc-plugin-video-output,DEB_VLC_V)
	$(call PACK,vlc-plugin-video-splitter,DEB_VLC_V)
	$(call PACK,vlc-plugin-visualization,DEB_VLC_V)
	$(call PACK,libvlc5,DEB_VLC_V)
	$(call PACK,libvlccore9,DEB_VLC_V)
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	$(call PACK,vlc.app,DEB_VLC_V)
endif
	$(call PACK,libvlc-dev,DEB_VLC_V)
	$(call PACK,libvlc-bin,DEB_VLC_V)
	$(call PACK,libvlccore-dev,DEB_VLC_V)

	# vlc.mk Build cleanup
	rm -rf $(BUILD_DIST)/{vlc.app,vlc{,-bin,-data,-l10n,-plugin-{access-extra,base,video-output,video-splitter,visualization}},libvlc{-bin,-dev,5,core{9,-dev}}}

.PHONY: vlc vlc-package
