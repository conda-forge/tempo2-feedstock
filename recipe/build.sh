#! /bin/bash

set -exo pipefail

export TEMPO2=$PREFIX/share/tempo2

# GCC 15 and later default to C23, but Tempo2 still defines `bool`
# itself in jpleph.c. Build the C sources as GNU C17 for compatibility.
export CFLAGS="${CFLAGS} -std=gnu17"

configure_args=()

if [[ "${target_platform:-}" == "osx-arm64" ]]; then
    # Apple Clang does not provide the __float128 arithmetic required by
    # Tempo2 on arm64, so this target is built with GCC and libquadmath.
    configure_args+=(--enable-float128)

    # conda-forge's GCC for macOS uses libc++ but its bundled omp.h refers to libstdc++-specific headers.
    # Put llvm-openmp's compatible header in a separate include directory so that it is found before GCC's omp.h.
    mkdir -p "${SRC_DIR}/llvm-openmp-include"
    cp "${PREFIX}/include/omp.h" "${SRC_DIR}/llvm-openmp-include/omp.h"
    export CPPFLAGS="-I${SRC_DIR}/llvm-openmp-include ${CPPFLAGS:-}"
fi

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* ./tests/gtest-1.7.0/build-aux

./bootstrap
./configure --prefix=${PREFIX} --disable-local --disable-psrhome PGPLOT_DIR=$PREFIX/include/pgplot "${configure_args[@]}"
make -j${CPU_COUNT}
make install
make -j${CPU_COUNT} plugins
make plugins-install

# Copy runtime stuff
for dir in atmosphere ephemeris example_data observatory plugin_data solarWindModel clock earth
do
    cp -a T2runtime/${dir} $TEMPO2/
done

# Make conda automatically define a TEMPO2 env variable
# when the environment is activated.
mkdir -p "${PREFIX}/etc/conda/env_vars.d"
cat > "${PREFIX}/etc/conda/env_vars.d/${PKG_NAME}.json" << EOF
{
  "TEMPO2": "${PREFIX}/share/tempo2"
}
EOF
