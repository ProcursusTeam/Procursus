ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += ruby
RUBY_VERSION     := 3.0
RUBY_API_VERSION := $(RUBY_VERSION).0
DEB_RUBY_V       ?= $(RUBY_API_VERSION)

ruby-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://cache.ruby-lang.org/pub/ruby/$(RUBY_VERSION)/ruby-$(RUBY_API_VERSION).tar.gz
	$(call EXTRACT_TAR,ruby-$(RUBY_API_VERSION).tar.gz,ruby-$(RUBY_API_VERSION),ruby)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(call DO_PATCH,ruby-ios,ruby,-p1)
endif

ifneq ($(wildcard $(BUILD_WORK)/ruby/.build_complete),)
ruby:
	@echo "Using previously built ruby."
else
ruby: ruby-setup libxcrypt libgmp10 libjemalloc ncurses readline openssl libyaml libffi libgdbm libucontext
	mkdir -p $(BUILD_WORK)/ruby/nativebuild
	cd $(BUILD_WORK)/ruby/nativebuild && env -i ../configure --prefix=$(BUILD_WORK)/ruby/nativebuild/install --disable-install-rdoc --disable-install-doc
	+unset CC CXX CFLAGS CPPFLAGS LDFLAGS && $(MAKE) -C $(BUILD_WORK)/ruby/nativebuild install

	$(SED) -i -e 's/\bcurses\b/ncursesw/' \
		-e 's/\bncurses\b/ncursesw/' $(BUILD_WORK)/ruby/ext/readline/extconf.rb

	# Future reference: coroutine should be "arm64" on M1 macs
	cd $(BUILD_WORK)/ruby && LIBS="-lcrypt -lucontext" PKG_CONFIG="pkg-config --define-prefix" \
		 ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--target=$(GNU_HOST_TRIPLE) \
		--with-arch=$(MEMO_ARCH) \
		--with-coroutine=ucontext \
		--with-jemalloc \
		--prefix=/usr \
		--enable-shared \
		--program-suffix=$(RUBY_VERSION) \
		--with-soname=ruby-$(RUBY_VERSION) \
		--with-sitedir=/usr/local/lib/ruby/site_ruby \
    	--with-vendordir=/usr/lib/ruby/vendor_ruby \
		--runstatedir=/var/run \
		--localstatedir=/var \
		--sysconfdir=/etc \
		--disable-dtrace \
		--enable-ipv6 \
		--with-baseruby="$(BUILD_WORK)/ruby/nativebuild/install/bin/ruby" \
		CFLAGS="$(CFLAGS) -I$(BUILD_STAGE)/libucontext/usr/include -D_STRUCT_UCONTEXT" \
		LDFLAGS="$(LDFLAGS) -L$(BUILD_STAGE)/libucontext/usr/lib"
	+$(MAKE) -C $(BUILD_WORK)/ruby
	+$(MAKE) -C $(BUILD_WORK)/ruby install \
		DESTDIR="$(BUILD_STAGE)/ruby"
	$(SED) -i 's/.*DLDFLAGS=.*/DLDFLAGS=/' $(BUILD_STAGE)/ruby/usr/lib/pkgconfig/ruby-$(RUBY_VERSION).pc
	touch $(BUILD_WORK)/ruby/.build_complete
endif

ruby-package: ruby-stage
	# ruby.mk Package Structure
	rm -rf $(BUILD_DIST)/ruby$(RUBY_VERSION){,-dev,-doc} $(BUILD_DIST)/libruby$(RUBY_VERSION) $(BUILD_DIST)/ruby
	mkdir -p $(BUILD_DIST)/ruby$(RUBY_VERSION){,-doc}/usr/share \
		$(BUILD_DIST)/ruby$(RUBY_VERSION)-dev/usr/lib \
		$(BUILD_DIST)/libruby$(RUBY_VERSION)/usr/lib \
		$(BUILD_DIST)/ruby/usr/{bin,share/man/man1}
	
	# ruby.mk Prep ruby$(RUBY_VERSION)
	cp -a $(BUILD_STAGE)/ruby/usr/bin $(BUILD_DIST)/ruby$(RUBY_VERSION)/usr
	cp -a $(BUILD_STAGE)/ruby/usr/share/man $(BUILD_DIST)/ruby$(RUBY_VERSION)/usr/share

	# ruby.mk Prep ruby$(RUBY_VERSION)-dev
	cp -a $(BUILD_STAGE)/ruby/usr/include $(BUILD_DIST)/ruby$(RUBY_VERSION)-dev/usr
	cp -a $(BUILD_STAGE)/ruby/usr/lib/pkgconfig $(BUILD_DIST)/ruby$(RUBY_VERSION)-dev/usr/lib

	# ruby.mk Prep ruby$(RUBY_VERSION)-doc
	cp -a $(BUILD_STAGE)/ruby/usr/share/ri $(BUILD_DIST)/ruby$(RUBY_VERSION)-doc/usr/share

	# ruby.mk Prep libruby$(RUBY_VERSION)
	cp -a $(BUILD_STAGE)/ruby/usr/lib/{libruby-$(RUBY_VERSION).dylib,ruby} $(BUILD_DIST)/libruby$(RUBY_VERSION)/usr/lib

	# ruby.mk Prep ruby
	for bin in erb irb rdoc ri ruby; do \
		ln -s $${bin}$(RUBY_VERSION) $(BUILD_DIST)/ruby/usr/bin/$${bin}; \
		ln -s $${bin}$(RUBY_VERSION).1.zst $(BUILD_DIST)/ruby/usr/share/man/man1/$${bin}.1; \
	done

	# ruby.mk Sign
	$(call SIGN,ruby$(RUBY_VERSION),general.xml)
	$(call SIGN,libruby$(RUBY_VERSION),general.xml)
	
	# ruby.mk Make .debs
	$(call PACK,ruby,DEB_RUBY_V)
	$(call PACK,ruby$(RUBY_VERSION),DEB_RUBY_V)
	$(call PACK,ruby$(RUBY_VERSION)-dev,DEB_RUBY_V)
	$(call PACK,ruby$(RUBY_VERSION)-doc,DEB_RUBY_V)
	$(call PACK,libruby$(RUBY_VERSION),DEB_RUBY_V)
	
	# ruby.mk Build cleanup
	rm -rf $(BUILD_DIST)/ruby$(RUBY_VERSION){,-dev,-doc} $(BUILD_DIST)/libruby$(RUBY_VERSION) $(BUILD_DIST)/ruby

.PHONY: ruby ruby-package
