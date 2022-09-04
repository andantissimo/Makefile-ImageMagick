## ImageMagick

IMAGE_MAGICK_VERSION  = 7.1.0-47
AOM_VERSION           = 3.4.0
LITTLE_CMS2_VERSION   = 2.13.1
LIBHEIF_VERSION       = 1.13.0
LIBJPEG_TURBO_VERSION = 2.1.4
LIBPNG_VERSION        = 1.6.37
LIBWEBP_VERSION       = 1.2.4

all: bin/magick

clean:
	cd bin && $(RM) MagickCore-config MagickWand-config
	cd bin && $(RM) jpgicc linkicc psicc transicc
	cd bin && $(RM) cjpeg djpeg jpegtran rdjpgcom wrjpgcom tjbench
	cd bin && $(RM) libpng-config libpng16-config png-fix-itxt pngfix
	cd bin && $(RM) cwebp dwebp img2webp webpinfo webpmux
	cd share && $(RM) -r doc man/man3 man/man5 mime thumbnailers
	cd share/man/man1 && $(RM) ImageMagick.1
	cd share/man/man1 && $(RM) MagickCore-config.1 MagickWand-config.1
	cd share/man/man1 && $(RM) jpgicc.1 linkicc.1 psicc.1 tificc.1 transicc.1
	cd share/man/man1 && $(RM) heif-convert.1 heif-enc.1 heif-info.1
	cd share/man/man1 && $(RM) heif-thumbnailer.1
	cd share/man/man1 && $(RM) cjpeg.1 djpeg.1 jpegtran.1 rdjpgcom.1 wrjpgcom.1
	cd share/man/man1 && $(RM) cwebp.1 dwebp.1 img2webp.1 webpinfo.1 webpmux.1
	$(RM) -r etc include lib tmp

bin/magick: lib/liblcms2.a \
            lib/libheif.a \
            lib/libjpeg.a \
            lib/libpng.a \
            lib/libwebp.a
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
		--without-xml \
		LDFLAGS='-lz' && \
	$(MAKE) install

lib/libaom.a:
	mkdir -p tmp/libaom
	cd tmp/libaom && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DENABLE_DOCS=OFF -DENABLE_EXAMPLES=OFF \
		-DENABLE_TESTDATA=OFF -DENABLE_TESTS=OFF -DENABLE_TOOLS=OFF \
		$(PWD)/src/aom-$(AOM_VERSION) && \
	$(MAKE) install

lib/liblcms2.a: lib/libjpeg.a
	cd src/lcms2-$(LITTLE_CMS2_VERSION) && \
	./configure --prefix=$(PWD) --disable-dependency-tracking \
		--disable-shared --enable-static \
		--with-jpeg \
		--without-tiff && \
	$(MAKE) install

lib/libheif.a: lib/libaom.a
	cd src/libheif-$(LIBHEIF_VERSION) && \
	./configure --prefix=$(PWD) --disable-dependency-tracking \
		--disable-shared --enable-static \
		--disable-go \
		--disable-examples \
		--enable-aom \
		--disable-libde265 \
		--disable-x265 \
		--disable-gdk-pixbuf \
		--disable-rav1e && \
	$(MAKE) install
ifeq ($(shell uname),Darwin)
	sed -e 's@^\(Libs:.*\)$$@\1 -lc++@' \
	    -i'.bak' lib/pkgconfig/libheif.pc
endif
ifeq ($(shell uname),FreeBSD)
	sed -e 's@^\(Libs:.*\)$$@\1 -lc++@' \
	    -i'.bak' lib/pkgconfig/libheif.pc
endif
ifeq ($(shell uname),Linux)
	sed -e 's@^\(Libs:.*\)$$@\1 -lstdc++@' \
	    -i'.bak' lib/pkgconfig/libheif.pc
endif

lib/libjpeg.a:
	cd src/libjpeg-turbo-$(LIBJPEG_TURBO_VERSION) && \
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(PWD) \
		-DCMAKE_INSTALL_LIBDIR=$(PWD)/lib \
		-DCMAKE_INSTALL_MANDIR=$(PWD)/share/man \
		-DENABLE_SHARED=OFF -DENABLE_STATIC=ON \
		-DWITH_JPEG8=ON \
		. && \
	$(MAKE) install

lib/libpng.a:
	cd src/libpng-$(LIBPNG_VERSION) && \
	./configure --prefix=$(PWD) --disable-dependency-tracking \
		--disable-shared --enable-static && \
	$(MAKE) install

lib/libwebp.a: lib/libjpeg.a \
               lib/libpng.a
	cd src/libwebp-$(LIBWEBP_VERSION) && \
	./configure --prefix=$(PWD) --disable-dependency-tracking \
		--disable-shared --enable-static \
		--enable-libwebpmux \
		--enable-libwebpdemux \
		--enable-libwebpdecoder \
		--disable-gl \
		--disable-sdl \
		--disable-tiff \
		--disable-gif && \
	$(MAKE) install
