#! /bin/sh

# OpenPandora firmware uses :
# - libgpg-error 1.4
# - libgcrypt 1.4.1
# - GnuTLS 2.8.5
# stick with them

LIBGPG_ERROR_VERSION=1.4
LIBGPG_ERROR_SHA256=5f71a3f7da2d0b5ea241186848e33e36714952d40d75d98278c4f184b79915f4

LIBGCRYPT_VERSION=1.4.1
LIBGCRYPT_SHA256=fe3b32bdf0c92d6b3bb7b3e4b3c19a6a899a9deb65f1b36f0a5882d308c91fa3

GNUTLS_VERSION=2.8.5
GNUTLS_SHA256=9249c29df71551e302e0186f4e1876dd6cc4c6cf2974b432c22525dde815cae8

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPERS_DIR=$PACKAGE_DIR/../..
. $HELPERS_DIR/functions.sh

do_make_bdir

do_http_fetch libgpg-error "http://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-${LIBGPG_ERROR_VERSION}.tar.bz2" \
	'tar xjf' "sha256:${LIBGPG_ERROR_SHA256}"

# Fix GCC preprocessor without a patch to avoid hacks
sed -ie 's/_\$@ | grep GPG_ERR_ |/-P \0/' src/Makefile.in

# Enable shared objects to make binary lighter
do_configure_shared
do_make

do_make -C src install-libLTLIBRARIES \
	install-binSCRIPTS \
	install-includeHEADERS \
	install-m4dataDATA

cd ..

do_http_fetch libgcrypt "http://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-${LIBGCRYPT_VERSION}.tar.bz2" \
	'tar xjf' "sha256:${LIBGCRYPT_SHA256}"

# Fix inline with recent GCCs without a patch to avoid hacks (5abc06114e91beca0177331e1c79815f5fb6d7be)
sed -ie 's/^\(#define G10_MPI_INLINE_DECL.*\) __inline__/\1 inline __attribute__ ((__gnu_inline__))/' mpi/mpi-inline.h

# Disable tests, they don't even build...
sed -ie 's/^\(SUBDIRS.*\) doc tests/\1/' Makefile.in

# Enable shared objects to make binary lighter
do_configure_shared --without-pth --disable-asm
do_make

do_make -C src install-libLTLIBRARIES \
	install-binSCRIPTS \
	install-includeHEADERS \
	install-m4dataDATA

cd ..

do_http_fetch gnutls "http://ftp.gnu.org/gnu/gnutls/gnutls-${GNUTLS_VERSION}.tar.bz2" \
	'tar xjf' "sha256:${GNUTLS_SHA256}"
do_patch gnutls

# Disable programs, doc and tests they don't even build...
sed -ie 's/^\(SUBDIRS.*\) src doc tests/\1/' Makefile.in

# Disable po
sed -ie 's/^\(SUBDIRS.*\) po/\1/' lib/Makefile.in

# Enable shared objects to make binary lighter
do_configure_shared --with-included-opencdk --with-included-libtasn1
do_make

do_make install

do_clean_bdir
