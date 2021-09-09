#!/usr/bin/bash

if [[ $# -lt 1 ]]; then
	echo "Illegal number of parameters"
	exit 1
fi

LIBNAME=$1

function createMakefile() {
cat > Makefile <<EOF

CXXFLAGS = -fPIC
NAME=libA.so
OBJDIR=objs

OBJS=\$(patsubst %.cpp,%.o,\$(addprefix \$(OBJDIR)/,\$(wildcard *.cpp)))

\$(NAME): \$(OBJS)
	gcc $^ -shared -o \$@

\$(addprefix \$(OBJDIR)/, %o): %cpp
	@mkdir -p \$(OBJDIR)
	\$(CXX) \$(CXXFLAGS) -c $< -o \$@
EOF
}

function createCMake() {

}

function createBaseSources() {
cat > lib$LIBNAME.cpp <<EOF
$LIBNAME::$LIBNAME() {

}

$LIBNAME::$LIBNAME(const $LIBNAME& other) {

}

$LIBNAME& $LIBNAME::operator=(const $LIBNAME& other) {

}

$LIBNAME::~$LIBNAME() {
	
}

std::ostream& operator<<(std::ostream &stream, const $LIBNAME& obj) {
	return stream;
}

EOF

cat > lib$LIBNAME.h <<EOF
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



