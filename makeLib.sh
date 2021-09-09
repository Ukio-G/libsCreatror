#!/usr/bin/bash

if [[ $# -lt 1 ]]; then
	echo "Illegal number of parameters"
	exit 1
fi

LIBNAME=$1

function createMakefile() {
cat > Makefile <<EOF
CXXFLAGS = -fPIC
NAME=lib$LIBNAME.so
OBJDIR=objs
SHARED_INSTALL_DIR=/usr/lib
HEADER_INSTALL_DIR=/usr/include
HEADERS=$LIBNAME.h

OBJS=\$(patsubst %.cpp,%.o,\$(addprefix \$(OBJDIR)/,\$(wildcard *.cpp)))

\$(NAME): \$(OBJS)
	gcc $^ -shared -o \$@

\$(addprefix \$(OBJDIR)/, %o): %cpp
	@mkdir -p \$(OBJDIR)
	\$(CXX) \$(CXXFLAGS) -c $< -o \$@

all: $LIBNAME

install:
	cp \$(NAME) \$(SHARED_INSTALL_DIR)
	cp \$(HEADERS) \$(HEADER_INSTALL_DIR)

delete:
	rm -f \$(SHARED_INSTALL_DIR)/\$(NAME)
	rm -f \$(HEADER_INSTALL_DIR)/\$(HEADERS)

clean:
	rm -rf objs \$(NAME)

.PHONY: install delete clean all

EOF
}

function createCMake() {
cat > CMakeLists.txt <<EOF
cmake_minimum_required(VERSION 3.9)
project(lib$LIBNAME)

set(CMAKE_CXX_STANDARD 14)

file(GLOB SRCS *.cpp)

add_library($LIBNAME SHARED \${SRCS})
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

SRC_DIR=lib$LIBNAME-src

mkdir $SRC_DIR
cd $SRC_DIR

determinateBuildSystem $2
createBuildSystemFile
createBaseSources

