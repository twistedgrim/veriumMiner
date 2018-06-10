#!/bin/bash

if [ "$OS" = "Windows_NT" ]; then
    ./mingw64.sh
    exit 0
fi

# Linux build

make clean || echo clean

rm -f config.status
./autogen.sh || echo done

# Debian 7.7 / Ubuntu 14.04 (gcc 4.7+)
extracflags="$extracflags -Ofast -flto -fuse-linker-plugin -ftree-loop-if-convert-stores"

# Crude Arm detection/optimization
processor=$(uname -p)
: ${CC:="gcc"}

# Old / Badly configured gcc don't have march=native and usually ALSO don't have mfpu=neon available in this case, we filter them out
LANG=C
if ${CC} -march=native -Q --help=target 2>&1 |grep -q "unknown architecture"; then
	echo "${CC} does not support -march=native - you should manually optimize your build"
else

	case "${processor}" in

		"aarch64" )
		echo "AArch64 CPU detected"
		extracflags="$extracflags -march=native"
		;;

		"armv7l" )
		echo "Armv7 CPU detected"
		extracflags="$extracflags -march=armv7-a -mfpu=neon"
		;;

		* )
		;;
	esac

	if [ ! "0" = `cat /proc/cpuinfo | grep -c avx` ]; then
	    extracflags="$extracflags -march=native"
	fi
fi

./configure --with-crypto --with-curl CFLAGS="-O2 $extracflags -DUSE_ASM -pg"

make -j 4

strip -s cpuminer
