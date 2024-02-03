## ImageMagick

IMAGE_MAGICK_VERSION = 7.1.1-27
DAV1D_VERSION        = 1.3.0
KVAZAAR_VERSION      = 2.3.0
LITTLE_CMS2_VERSION  = 2.16
LIBDE265_VERSION     = 1.0.15
LIBHEIF_VERSION      = 1.17.6
LIBPNG_VERSION       = 1.6.41
LIBWEBP_VERSION      = 1.3.2
LIBXML2_VERSION      = 2.12.4
MOZJPEG_VERSION      = 4.1.5
RAV1E_VERSION        = 0.7.1

all: bin/magick

clean:
	cd bin && $(RM) MagickCore-config MagickWand-config
	cd bin && $(RM) kvazaar
	cd bin && $(RM) acceleration_speed bjoentegaard block-rate-estim
	cd bin && $(RM) gen-enc-table rd-curves tests yuv-distortion
	cd bin && $(RM) heif-convert heif-enc heif-info heif-thumbnailer
	cd bin && $(RM) jpgicc linkicc psicc transicc
	cd bin && $(RM) cjpeg djpeg jpegtran rdjpgcom wrjpgcom tjbench
	cd bin && $(RM) libpng-config libpng16-config png-fix-itxt pngfix
	cd bin && $(RM) cwebp dwebp img2webp webpinfo webpmux
	cd bin && $(RM) xml2-config xmlcatalog xmllint
	cd share && $(RM) -r aclocal doc gtk-doc man mime thumbnailers
	$(RM) -r include lib libdata tmp

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
		--disable-docs \
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
	meson --prefix=$(PWD) --libdir=$(PWD)/lib \
		--buildtype release --default-library static \
		-Denable_tools=false -Denable_examples=false -Denable_tests=false \
		build && \
	ninja install -C build
ifeq ($(shell uname),FreeBSD)
	cat libdata/pkgconfig/dav1d.pc | sed -e 's@^\(Libs:.*\)$$@\1 -lpthread@' \
	  > lib/pkgconfig/dav1d.pc
endif

lib/libde265.a:
	cd src/libde265-$(LIBDE265_VERSION) && \
	./configure --prefix=$(PWD) --disable-dependency-tracking \
		--disable-shared --enable-static \
		--disable-dec265 \
		--disable-sherlock265 && \
	$(MAKE) install

lib/libkvazaar.a:
	cd src/kvazaar-$(KVAZAAR_VERSION) && \
	./autogen.sh && \
	./configure --prefix=$(PWD) --disable-dependency-tracking \
		--disable-shared --enable-static && \
	$(MAKE) install

lib/liblcms2.a: lib/libjpeg.a
	cd src/lcms2-$(LITTLE_CMS2_VERSION) && \
	./configure --prefix=$(PWD) --disable-dependency-tracking \
		--disable-shared --enable-static \
		--with-jpeg \
		--without-tiff && \
	$(MAKE) install

LIBHEIF_PC_LIBS = -ldav1d -lde265 -lkvazaar -lrav1e
lib/libheif.a: lib/libdav1d.a lib/libde265.a lib/libkvazaar.a lib/librav1e.a
	cd src/libheif-$(LIBHEIF_VERSION) && \
	sed -e 's@ kvzChroma;@ kvzChroma{};@' \
	    -i'.bak' libheif/plugins/encoder_kvazaar.cc && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF -DWITH_EXAMPLES=OFF \
		-DENABLE_PLUGIN_LOADING=OFF \
		-DWITH_AOM_DECODER=OFF -DWITH_AOM_ENCODER=OFF \
		-DWITH_DAV1D=ON -DWITH_DAV1D_PLUGIN=OFF \
		-DWITH_GDK_PIXBUF=OFF \
		-DWITH_KVAZAAR=OF -DWITH_KVAZAAR_PLUGIN=OFF \
		-DWITH_RAV1E=ON -DWITH_RAV1E_PLUGIN=OFF \
		-DWITH_X265=OFF \
		. && \
	$(MAKE) install
ifeq ($(shell uname),Darwin)
	sed -e 's@^\(Libs:.*\)$$@\1 $(LIBHEIF_PC_LIBS) -lc++@' \
	    -i'.bak' lib/pkgconfig/libheif.pc
endif
ifeq ($(shell uname),FreeBSD)
	sed -e 's@^\(Libs:.*\)$$@\1 $(LIBHEIF_PC_LIBS) -lc++@' \
	    -i'.bak' lib/pkgconfig/libheif.pc
endif
ifeq ($(shell uname),Linux)
	sed -e 's@^\(Libs:.*\)$$@\1 $(LIBHEIF_PC_LIBS) -ldl -lstdc++@' \
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
	./configure --prefix=$(PWD) --disable-dependency-tracking \
		--disable-shared --enable-static && \
	$(MAKE) install

lib/librav1e.a:
	cd src/rav1e-$(RAV1E_VERSION) && \
	cargo cinstall --prefix $(PWD) --pkgconfigdir $(PWD)/lib/pkgconfig \
		--release
	$(RM) lib/librav1e.*dylib
	$(RM) lib/librav1e.so*

lib/libwebp.a: lib/libjpeg.a \
               lib/libpng.a
	cd src/libwebp-$(LIBWEBP_VERSION) && \
	./configure --prefix=$(PWD) --disable-dependency-tracking \
		--disable-shared --enable-static \
		--disable-libwebpmux \
		--disable-libwebpdemux \
		--disable-libwebpdecoder \
		--disable-gl \
		--disable-sdl \
		--disable-tiff \
		--disable-gif && \
	$(MAKE) install

lib/libxml2.a:
	cd src/libxml2-$(LIBXML2_VERSION) && \
	./configure --prefix=$(PWD) --disable-dependency-tracking \
		--enable-static --disable-shared \
		--without-c14n --without-catalog --without-debug \
		--without-fexceptions --without-ftp --without-history --without-html \
		--without-http --without-iconv --without-icu --without-iso8859x \
		--without-legacy --without-mem-debug --with-minimum --without-output \
		--without-pattern --with-push --without-python --without-reader \
		--without-readline --without-regexps --without-run-debug --with-sax1 \
		--without-schemas --without-schematron --without-threads --with-tree \
		--without-valid --without-writer --without-xinclude --without-xpath \
		--without-xptr --without-modules --without-zlib --without-lzma \
		--without-coverage && \
	$(MAKE) install
