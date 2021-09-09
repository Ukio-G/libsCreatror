#!/usr/bin/bash

CMAKE_MIN_VERSION="3.9"
CXX_STANDART=14

if [[ $# -lt 1 ]]; then
	echo "Illegal number of parameters"
	exit 1
fi

LIBNAME=$1

function createMakefile() {
cat > Makefile <<EOF
CXXFLAGS = -fPIC -std=c++$CXX_STANDART
NAME=lib$LIBNAME.so
OBJDIR=objs
DESTDIR :=
PREFIX := /usr
HEADERS=$LIBNAME.h
INCLUDE_DIR=include

OBJS=\$(patsubst %.cpp,%.o,\$(addprefix \$(OBJDIR)/,\$(wildcard *.cpp)))

\$(NAME): \$(OBJS)
	gcc $^ -shared -o \$@

\$(addprefix \$(OBJDIR)/, %o): %cpp
	@mkdir -p \$(OBJDIR)
	\$(CXX) \$(CXXFLAGS) -Iinclude -c $< -o \$@

all: $LIBNAME

install:
	install -D -m755 \$(NAME) \$(DESTDIR)\$(PREFIX)/lib/\$(NAME)
	for file in \$(HEADERS); do \\
		install -D -m644 \$(INCLUDE_DIR)/\$\$file \$(DESTDIR)\$(PREFIX)/\$(INCLUDE_DIR)/\$\$file ; \\
	done

uninstall:
	rm -f \$(DESTDIR)\$(PREFIX)/lib/\$(NAME)
	for file in \$(HEADERS); do \\
		rm -f \$(DESTDIR)\$(PREFIX)/\$(INCLUDE_DIR)/\$\$file ; \\
	done

clean:
	rm -rf objs \$(NAME)

.PHONY: install uninstall clean all

EOF
}

function createCMake() {
cat > CMakeLists.txt <<EOF
cmake_minimum_required(VERSION $CMAKE_MIN_VERSION)
project(lib$LIBNAME)

set(CMAKE_CXX_STANDARD $CXX_STANDART)

file(GLOB SRCS *.cpp)
add_library($LIBNAME SHARED \${SRCS})
target_include_directories($LIBNAME include)
EOF
}

function determinateBuildSystem() {
	if [ ! -z $1 ]; then
		if [ "$1" = "Makefile" ]; then
			echo "Selected Makefile project"
			BUILD_SYSTEM=Makefile
		elif [ "$1" = "CMake" ]; then
			echo "Selected CMake project"
			BUILD_SYSTEM=CMake
		else
			echo "Undefined build system. Possible values: Makefile|CMake. Passed $1"
			exit 1
		fi
	else
		echo "Project type not selected. Use default value (Makefile)"
		BUILD_SYSTEM=Makefile
	fi
}

function createBuildSystemFile() {
	echo "Create $BUILD_SYSTEM project"
	if [ "$BUILD_SYSTEM" = "Makefile" ]; then
		createMakefile
	elif [ "$BUILD_SYSTEM" = "CMake" ]; then
		createCMake
	else
		echo "Canot create build system file. BUILD_SYSTEM variable has incorrect value (must be Makefile or CMake. Value in script: $BUILD_SYSTEM)"
		exit 1
	fi
}

function createBaseSources() {
cat > $LIBNAME.cpp <<EOF
#include "$LIBNAME.h"

$LIBNAME::$LIBNAME() {

}

$LIBNAME::$LIBNAME(const $LIBNAME& other) {

}

$LIBNAME& $LIBNAME::operator=(const $LIBNAME& other) {
	if (&other == this)
		return *this;

	return *this;
}

$LIBNAME::~$LIBNAME() {
	
}

std::ostream& operator<<(std::ostream &stream, const $LIBNAME& obj) {
	return stream;
}

EOF

mkdir include && cd include

cat > $LIBNAME.h <<EOF
#include <iostream>

class $LIBNAME
{
public:
	$LIBNAME();
	$LIBNAME(const $LIBNAME& other);
	~$LIBNAME();

	$LIBNAME& operator=(const $LIBNAME& other);
private:
};

std::ostream& operator<<(std::ostream &stream, const $LIBNAME& obj);
EOF
}


function createArchPackage()
{
	NAME=$(git config user.name)
	VER="0.1"
cat > PKGBUILD<<EOF

# This is an example PKGBUILD file. Use this as a start to creating your own,
# and remove these comments. For more information, see 'man PKGBUILD'.
# NOTE: Please fill out the license field for your package! If it is unknown,
# then please put 'unknown'.

# Maintainer: Your Name <youremail@domain.com>
pkgname=$SRC_DIR
pkgver=$VER
pkgrel=1
# pkgdir=/usr/lib
epoch=
pkgdesc="Libs provide print bytes"
arch=("x86_64")
url=""
license=('GPL')
groups=()
depends=()
makedepends=()
checkdepends=()
optdepends=()
provides=()
conflicts=()
replaces=()
backup=()
options=()
install=
changelog=
source=("\$pkgname-\$pkgver.tar.gz")
noextract=()
md5sums=()
validpgpkeys=()

prepare() {
	cd "\$pkgname-\$pkgver"
	# patch -p1 -i "\$srcdir/\$pkgname-\$pkgver.patch"
}

build() {
	cd "\$pkgname-\$pkgver"
	# ./configure --prefix=/usr
	make
}

check() {
	cd "\$pkgname-\$pkgver"
	# make -k check
}

package() {
	cd "\$pkgname-\$pkgver"
	make DESTDIR=\$pkgdir install
}
EOF

PKG_DIR=$SRC_DIR-$VER

mkdir $PKG_DIR
cp *.cpp Makefile $PKG_DIR 
cp -r include $PKG_DIR
tar -cvf $PKG_DIR.tar.gz $PKG_DIR
makepkg --nocheck --skipchecksums -f
}

SRC_DIR=lib$LIBNAME

if [ "$1" = "make_package" ]; then
	SRC_DIR=${PWD##*/}

	if [ "$2" = "pacman" ]; then
		createArchPackage
		exit 0
	else
		echo "Package manager not supported."
		exit 1
	fi
fi

mkdir $SRC_DIR
cd $SRC_DIR

determinateBuildSystem $2
createBuildSystemFile
createBaseSources
