## ImageMagick

IMAGE_MAGICK_VERSION = 7.1.1-29
DAV1D_VERSION        = 1.4.0
KVAZAAR_VERSION      = 2.3.0
LITTLE_CMS2_VERSION  = 2.16
LIBDE265_VERSION     = 1.0.15
LIBHEIF_VERSION      = 1.17.6
LIBPNG_VERSION       = 1.6.43
LIBWEBP_VERSION      = 1.3.2
LIBXML2_VERSION      = 2.12.5
MOZJPEG_VERSION      = 4.1.5

OS := $(shell uname -s)

all: bin/magick

clean:
	$(RM) -r include lib libdata tmp
	$(RM) -r share/WebP share/aclocal share/doc share/man/man3 share/man/man5
	cd bin            && $(RM) MagickCore-config   MagickWand-config
	cd share/man/man1 && $(RM) MagickCore-config.1 MagickWand-config.1
	cd bin            && $(RM) kvazaar
	cd share/man/man1 && $(RM) kvazaar.1
	cd bin            && $(RM) cjpeg   djpeg   jpegtran   rdjpgcom   wrjpgcom
	cd share/man/man1 && $(RM) cjpeg.1 djpeg.1 jpegtran.1 rdjpgcom.1 wrjpgcom.1
	cd bin            && $(RM) libpng-config libpng16-config
	cd bin            && $(RM) xml2-config
	cd share/man/man1 && $(RM) xml2-config.1 xmlcatalog.1 xmllint.1

bin/magick: lib/liblcms2.a \
            lib/libheif.a \
            lib/libjpeg.a \
            lib/libpng.a \
            lib/libwebp.a \
            lib/libxml2.a
	cd src/ImageMagick-$(IMAGE_MAGICK_VERSION) && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	./configure --prefix=$(PWD) --disable-dependency-tracking \
		--disable-shared --enable-static \
		--disable-osx-universal-binary \
		--disable-openmp \
		--disable-opencl \
		--disable-deprecated \
		--disable-installed \
		--disable-cipher \
		--enable-zero-configuration \
		--disable-assert \
		--without-modules \
		--without-magick-plus-plus \
		--without-bzlib \
		--without-x \
		--without-zip \
		--without-zstd \
		--without-dps \
		--without-fftw \
		--without-flif \
		--without-fpx \
		--without-djvu \
		--without-fontconfig \
		--without-freetype \
		--without-raqm \
		--without-gslib \
		--without-gvc \
		--with-heic \
		--without-jbig \
		--with-jpeg \
		--without-jxl \
		--without-lcms \
		--without-openjp2 \
		--without-lqr \
		--without-lzma \
		--without-openexr \
		--without-pango \
		--with-png \
		--without-raw \
		--without-rsvg \
		--without-tiff \
		--with-webp \
		--without-wmf \
		--with-xml \
		LDFLAGS='-lz' && \
	$(MAKE) install

lib/libdav1d.a:
	cd src/dav1d-$(DAV1D_VERSION) && \
	meson setup --prefix=$(PWD) --libdir=$(PWD)/lib \
		--buildtype release --default-library static \
		-Denable_tools=false -Denable_examples=false -Denable_tests=false \
		-Denable_docs=false -Dxxhash_muxer=disabled \
		build && \
	ninja install -C build
ifeq ($(OS),FreeBSD)
	mkdir -p lib/pkgconfig
	cat libdata/pkgconfig/dav1d.pc | sed -e 's@^\(Libs:.*\)$$@\1 -lpthread@' \
	  > lib/pkgconfig/dav1d.pc
endif

lib/libde265.a:
	cd src/libde265-$(LIBDE265_VERSION) && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DBUILD_SHARED_LIBS=OFF \
		-DENABLE_DECODER=OFF -DENABLE_ENCODER=OFF \
		-DENABLE_SDL=OFF \
		. && \
	$(MAKE) install

lib/libkvazaar.a:
	mkdir -p include lib/pkgconfig
	cd src/kvazaar-$(KVAZAAR_VERSION) && \
	curl https://github.com/ultravideo/kvazaar/commit/d8c9688.patch \
	   | patch -p1 && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DBUILD_SHARED_LIBS=OFF -DBUILD_TESTS=OFF \
		. && \
	$(MAKE) $(MAKE_ARGS) && \
	install -m 644 src/kvazaar.h $(PWD)/include/kvazaar.h && \
	install -m 644 src/kvazaar.pc $(PWD)/lib/pkgconfig/kvazaar.pc && \
	install -m 644 libkvazaar.a $(PWD)/lib/libkvazaar.a
ifeq ($(OS),FreeBSD)
	sed -e 's@^\(Libs:.*\)$$@\1 -lpthread@' \
	    -i'.bak' lib/pkgconfig/kvazaar.pc
endif

lib/liblcms2.a:
	cd src/lcms2-$(LITTLE_CMS2_VERSION) && \
	meson setup --prefix=$(PWD) --libdir=$(PWD)/lib \
		--buildtype release --default-library static \
		-Djpeg=disabled -Dtiff=disabled -Dutils=false -Dsamples=false \
		build && \
	ninja install -C build
ifeq ($(OS),FreeBSD)
	mkdir -p lib/pkgconfig
	cat libdata/pkgconfig/lcms2.pc > lib/pkgconfig/lcms2.pc
endif

lib/libheif.a: lib/libdav1d.a lib/libde265.a lib/libkvazaar.a lib/libwebp.a
	cd src/libheif-$(LIBHEIF_VERSION) && \
	sed -e 's@ kvzChroma;@ kvzChroma{};@' \
	    -i'.bak' libheif/plugins/encoder_kvazaar.cc && \
	export PKG_CONFIG_PATH=$(PWD)/lib/pkgconfig && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF -DWITH_EXAMPLES=OFF \
		-DENABLE_PLUGIN_LOADING=OFF \
		-DWITH_AOM_DECODER=OFF -DWITH_AOM_ENCODER=OFF \
		-DWITH_DAV1D=ON -DWITH_DAV1D_PLUGIN=OFF \
		-DWITH_GDK_PIXBUF=OFF \
		-DWITH_KVAZAAR=ON -DWITH_KVAZAAR_PLUGIN=OFF \
		-DWITH_X265=OFF \
		. && \
	$(MAKE) install
ifeq ($(OS),Darwin)
	sed -e 's@^\(Libs:.*\)$$@\1 -ldav1d -lde265 -lkvazaar -lsharpyuv -lc++@' \
	    -i'.bak' lib/pkgconfig/libheif.pc
endif
ifeq ($(OS),FreeBSD)
	sed -e 's@^\(Libs:.*\)$$@\1 -ldav1d -lde265 -lkvazaar -lsharpyuv -lc++@' \
	    -i'.bak' lib/pkgconfig/libheif.pc
endif
ifeq ($(OS),Linux)
	sed -e 's@^\(Libs:.*\)$$@\1 -ldav1d -lde265 -lkvazaar -lsharpyuv -ldl -lstdc++@' \
	    -i'.bak' lib/pkgconfig/libheif.pc
endif

lib/libjpeg.a:
	cd src/mozjpeg-$(MOZJPEG_VERSION) && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DCMAKE_INSTALL_LIBDIR=$(PWD)/lib \
		-DCMAKE_INSTALL_MANDIR=$(PWD)/share/man \
		-DENABLE_SHARED=OFF -DENABLE_STATIC=ON \
		-DPNG_SUPPORTED=OFF \
		-DWITH_JPEG8=ON \
		-DWITH_TURBOJPEG=OFF \
		. && \
	$(MAKE) install

lib/libpng.a:
	cd src/libpng-$(LIBPNG_VERSION) && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DPNG_EXECUTABLES=OFF -DPNG_FRAMEWORK=OFF \
		-DPNG_SHARED=OFF -DPNG_STATIC=ON \
		-DPNG_TESTS=OFF -DPNG_TOOLS=OFF \
		. && \
	$(MAKE) install

lib/libwebp.a:
	cd src/libwebp-$(LIBWEBP_VERSION) && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DWEBP_BUILD_ANIM_UTILS=OFF \
		-DWEBP_BUILD_CWEBP=OFF -DWEBP_BUILD_DWEBP=OFF \
		-DWEBP_BUILD_EXTRAS=OFF \
		-DWEBP_BUILD_GIF2WEBP=OFF \
		-DWEBP_BUILD_IMG2WEBP=OFF \
		-DWEBP_BUILD_LIBWEBPMUX=OFF \
		-DWEBP_BUILD_VWEBP=OFF \
		-DWEBP_BUILD_WEBPINFO=OFF \
		-DWEBP_BUILD_WEBPMUX=OFF \
		. && \
	$(MAKE) install

lib/libxml2.a:
	cd src/libxml2-$(LIBXML2_VERSION) && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DBUILD_SHARED_LIBS=OFF \
		-DLIBXML2_WITH_C14N=OFF \
		-DLIBXML2_WITH_CATALOG=OFF \
		-DLIBXML2_WITH_DEBUG=OFF \
		-DLIBXML2_WITH_HTML=OFF \
		-DLIBXML2_WITH_HTTP=OFF \
		-DLIBXML2_WITH_ICONV=OFF \
		-DLIBXML2_WITH_ISO8859X=OFF \
		-DLIBXML2_WITH_LZMA=OFF \
		-DLIBXML2_WITH_MODULES=OFF \
		-DLIBXML2_WITH_OUTPUT=OFF \
		-DLIBXML2_WITH_PATTERN=OFF \
		-DLIBXML2_WITH_PROGRAMS=OFF \
		-DLIBXML2_WITH_PYTHON=OFF \
		-DLIBXML2_WITH_READER=OFF \
		-DLIBXML2_WITH_REGEXPS=OFF \
		-DLIBXML2_WITH_SCHEMAS=OFF \
		-DLIBXML2_WITH_SCHEMATRON=OFF \
		-DLIBXML2_WITH_TESTS=OFF \
		-DLIBXML2_WITH_THREADS=OFF \
		-DLIBXML2_WITH_VALID=OFF \
		-DLIBXML2_WITH_WRITER=OFF \
		-DLIBXML2_WITH_XINCLUDE=OFF \
		-DLIBXML2_WITH_XPATH=OFF \
		-DLIBXML2_WITH_XPTR=OFF \
		-DLIBXML2_WITH_ZLIB=OFF \
		. && \
	$(MAKE) install
