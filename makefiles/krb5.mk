ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += krb5
KRB5_VERSION := 1.19.2
DEB_KRB5_V   ?= $(KRB5_VERSION)

krb5-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://kerberos.org/dist/krb5/$(shell echo $(KRB5_VERSION) | cut -d. -f-2)/krb5-$(KRB5_VERSION).tar.gz
	$(call EXTRACT_TAR,krb5-$(KRB5_VERSION).tar.gz,krb5-$(KRB5_VERSION),krb5)
	$(call DO_PATCH,krb5,krb5,-p1)

ifneq ($(wildcard $(BUILD_WORK)/krb5/.build_complete),)
krb5:
	@echo "Using previously built krb5."
else
krb5: krb5-setup
	cd $(BUILD_WORK)/krb5/src && autoreconf -fi && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-static \
		--without-system-verto \
		--without-keyutils \
		krb5_cv_attr_constructor_destructor=yes,yes \
		ac_cv_func_regcomp=yes \
		ac_cv_printf_positional=yes
	+$(MAKE) -C $(BUILD_WORK)/krb5/src
	+$(MAKE) -C $(BUILD_WORK)/krb5/src install \
		DESTDIR=$(BUILD_STAGE)/krb5
	$(call AFTER_BUILD,copy)
endif

krb5-package: krb5-stage
	# krb5.mk Package Structure
	rm -rf $(BUILD_DIST)/{krb5-{user,kdc,admin-server,kpropd,multidev,pkinit,otp,k5tls,gss-samples,doc},libkrb5-dev,libkrb5,libgssapi-krb5,libgssrpc,libkadm5srv-mit,libkadm5clnt-mit,libk5crypto,libkdb,libkrb5support,libkrad,libkrad-dev}
	mkdir -p $(BUILD_DIST)/krb5-user/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1} \
		$(BUILD_DIST)/krb5-kdc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{sbin,lib/krb5/plugins/kdb/,share/man/{man5,man8}} \
		$(BUILD_DIST)/krb5-admin-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{sbin,share/man/{man5,man8}} \
		$(BUILD_DIST)/krb5-kpropd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{sbin,share/man/man8} \
		$(BUILD_DIST)/krb5-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5 \
		$(BUILD_DIST)/libkrb5-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,include,lib,share/man/man1} \
		$(BUILD_DIST)/krb5-pkinit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/krb5/plugins/preauth/ \
		$(BUILD_DIST)/krb5-otp/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/krb5/plugins/preauth/ \
		$(BUILD_DIST)/krb5-k5tls/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/krb5/plugins/tls/ \
		$(BUILD_DIST)/libkrb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/krb5/plugins/preauth/ \
		$(BUILD_DIST)/libgssapi-krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libgssrpc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libkadm5srv-mit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libkadm5clnt-mit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libk5crypto/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libkdb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libkrb5support/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libkrad/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/krb5-gss-samples/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
		$(BUILD_DIST)/libkrad-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,include} \
		$(BUILD_DIST)/libcom-err/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/comerr-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib,include,share/{et,man/man1}}

	# krb5.mk Prep krb5-doc
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5/{k5identity,k5login,krb5.conf}.5.zst $(BUILD_DIST)/krb5-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5/
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man7 $(BUILD_DIST)/krb5-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/

	# krb5.mk Prep krb5-user
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{k5srvutil,kadmin,kdestroy,kinit,klist,kpasswd,ksu,kswitch,ktutil,kvno} $(BUILD_DIST)/krb5-user/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{k5srvutil,kadmin,kdestroy,kinit,klist,kpasswd,ksu,kswitch,ktutil,kvno}.1.zst $(BUILD_DIST)/krb5-user/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# krb5.mk Prep krb5-kdc
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/{kdb5_util,kproplog,krb5kdc} $(BUILD_DIST)/krb5-kdc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/krb5/plugins/kdb/db2.so $(BUILD_DIST)/krb5-kdc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/krb5/plugins/kdb/
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5/kdc.conf.5.zst $(BUILD_DIST)/krb5-kdc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/{kdb5_util,kproplog,krb5kdc}.8.zst $(BUILD_DIST)/krb5-kdc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8

	# krb5.mk Prep krb5-admin-server
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/{kadmin.local,kadmind,kprop} $(BUILD_DIST)/krb5-admin-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5/kadm5.acl.5.zst $(BUILD_DIST)/krb5-admin-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man5
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/{kadmin.local,kadmind,kprop}.8.zst $(BUILD_DIST)/krb5-admin-server/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8

	# krb5.mk Prep krb5-kpropd
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin/kpropd $(BUILD_DIST)/krb5-kpropd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/sbin
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8/kpropd.8.zst $(BUILD_DIST)/krb5-kpropd/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man8

	# krb5.mk Prep libkrb5-dev
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/krb5-config $(BUILD_DIST)/libkrb5-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/{gssapi.h,kdb.h,krb5.h,profile.h,gssapi,gssrpc,kadm5,krb5} $(BUILD_DIST)/libkrb5-dev$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libgssapi_krb5.dylib,libgssrpc.dylib,libk5crypto.dylib,libkadm5clnt{,_mit}.dylib,libkadm5srv{,_mit}.dylib,libkdb5.dylib,libkrb5.dylib,libkrb5support.dylib,pkgconfig} $(BUILD_DIST)/libkrb5-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/krb5-config.1.zst $(BUILD_DIST)/libkrb5-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# krb5.mk Prep krb5-pkinit
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/krb5/plugins/preauth/pkinit.so $(BUILD_DIST)/krb5-pkinit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/krb5/plugins/preauth/

	# krb5.mk Prep krb5-otp
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/krb5/plugins/preauth/otp.so $(BUILD_DIST)/krb5-otp/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/krb5/plugins/preauth/

	# krb5.mk Prep krb5-k5tls
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/krb5/plugins/tls/k5tls.so $(BUILD_DIST)/krb5-k5tls/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/krb5/plugins/tls/

	# krb5.mk Prep libkrb5
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrb5.{3.dylib,3.3.dylib} $(BUILD_DIST)/libkrb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/krb5/plugins/preauth/spake.so $(BUILD_DIST)/libkrb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/krb5/plugins/preauth/

	# krb5.mk Prep libgssapi-krb5
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgssapi_krb5.{2.dylib,2.2.dylib} $(BUILD_DIST)/libgssapi-krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# krb5.mk Prep libgssrpc
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgssrpc.{4.dylib,4.2.dylib} $(BUILD_DIST)/libgssrpc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# krb5.mk Prep libkadm5srv-mit
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkadm5srv_mit.{12.dylib,12.0.dylib} $(BUILD_DIST)/libkadm5srv-mit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# krb5.mk Prep libkadm5clnt-mit
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkadm5clnt_mit.{12.dylib,12.0.dylib} $(BUILD_DIST)/libkadm5clnt-mit/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# krb5.mk Prep libk5crypto
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libk5crypto.{3.dylib,3.1.dylib} $(BUILD_DIST)/libk5crypto/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# krb5.mk Prep libkdb5
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkdb5.{10.dylib,10.0.dylib} $(BUILD_DIST)/libkdb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# krb5.mk Prep libkrb5support
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrb5support.{1.dylib,1.1.dylib} $(BUILD_DIST)/libkrb5support/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# krb5.mk Prep libkrad
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrad.{0.dylib,0.0.dylib} $(BUILD_DIST)/libkrad/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# krb5.mk Prep krb5-gss-samples
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gss-client $(BUILD_DIST)/krb5-gss-samples/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# krb5.mk Prep libkrad-dev
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libkrad.dylib $(BUILD_DIST)/libkrad-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/krad.h $(BUILD_DIST)/libkrad-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# krb5.mk Prep libcom-err
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcom_err.{3.dylib,3.0.dylib} $(BUILD_DIST)/libcom-err/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# krb5.mk Prep comerr-dev
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/compile_et $(BUILD_DIST)/comerr-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libcom_err.dylib $(BUILD_DIST)/comerr-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/com_err.h $(BUILD_DIST)/comerr-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/et/et_{c,h}.awk $(BUILD_DIST)/comerr-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/et
	cp -a $(BUILD_STAGE)/krb5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/compile_et.1.zst $(BUILD_DIST)/comerr-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# krb5.mk Sign
	$(call SIGN,krb5-user,general.xml)
	$(call SIGN,krb5-kdc,general.xml)
	$(call SIGN,krb5-admin-server,general.xml)
	$(call SIGN,krb5-kpropd,general.xml)
	$(call SIGN,libkrb5-dev,general.xml)
	$(call SIGN,krb5-pkinit,general.xml)
	$(call SIGN,krb5-otp,general.xml)
	$(call SIGN,krb5-k5tls,general.xml)
	$(call SIGN,libkrb5,general.xml)
	$(call SIGN,libgssapi-krb5,general.xml)
	$(call SIGN,libgssrpc,general.xml)
	$(call SIGN,libkadm5srv-mit,general.xml)
	$(call SIGN,libkadm5clnt-mit,general.xml)
	$(call SIGN,libk5crypto,general.xml)
	$(call SIGN,libkdb5,general.xml)
	$(call SIGN,libkrb5support,general.xml)
	$(call SIGN,libkrad,general.xml)
	$(call SIGN,krb5-gss-samples,general.xml)
	$(call SIGN,libkrad-dev,general.xml)
	$(call SIGN,libcom-err,general.xml)
	$(call SIGN,comerr-dev,general.xml)

	# krb5.mk Make .debs
	$(call PACK,krb5-user,DEB_KRB5_V)
	$(call PACK,krb5-kdc,DEB_KRB5_V)
	$(call PACK,krb5-admin-server,DEB_KRB5_V)
	$(call PACK,krb5-kpropd,DEB_KRB5_V)
	$(call PACK,krb5-doc,DEB_KRB5_V)
	$(call PACK,libkrb5-dev,DEB_KRB5_V)
	$(call PACK,krb5-pkinit,DEB_KRB5_V)
	$(call PACK,krb5-otp,DEB_KRB5_V)
	$(call PACK,krb5-k5tls,DEB_KRB5_V)
	$(call PACK,libkrb5,DEB_KRB5_V)
	$(call PACK,libgssapi-krb5,DEB_KRB5_V)
	$(call PACK,libgssrpc,DEB_KRB5_V)
	$(call PACK,libkadm5srv-mit,DEB_KRB5_V)
	$(call PACK,libkadm5clnt-mit,DEB_KRB5_V)
	$(call PACK,libk5crypto,DEB_KRB5_V)
	$(call PACK,libkdb5,DEB_KRB5_V)
	$(call PACK,libkrb5support,DEB_KRB5_V)
	$(call PACK,libkrad,DEB_KRB5_V)
	$(call PACK,krb5-gss-samples,DEB_KRB5_V)
	$(call PACK,libkrad-dev,DEB_KRB5_V)
	$(call PACK,libcom-err,DEB_KRB5_V)
	$(call PACK,comerr-dev,DEB_KRB5_V)

	# krb5.mk Build cleanup
	rm -rf $(BUILD_DIST)/{krb5-{user,kdc,admin-server,kpropd,pkinit,otp,k5tls,gss-samples,doc},libkrb5-dev,libkrb5,libgssapi-krb5,libgssrpc4,libkadm5srv-mit12,libkadm5clnt-mit12,libk5crypto3,libkdb5,libkrb5support1,libkrad0,libkrad-dev,libcom-err3,comerr-dev}

.PHONY: krb5 krb5-package
