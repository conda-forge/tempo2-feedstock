#! /bin/bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* ./tests/gtest-1.7.0/build-aux

#./bootstrap
#export CXXFLAGS=$(echo "$CXXFLAGS" | sed 's/-O2//' | perl -pe 's/-std=.+ /-std=c++98 /')
#echo "CXXFLAGS $CXXFLAGS"

export TEMPO2=$PREFIX/share/tempo2

if [[ "$CONDA_BUILD_CROSS_COMPILATION" == 1 ]]; then
  (
    # Make native build of tempo2
    mkdir -p native-build
    pushd native-build
    
    unset MACOSX_DEPLOYMENT_TARGET
    
    export CC=$CC_FOR_BUILD
    export host_alias=$build_alias
    
    cp -r ../bootstrap ../configure.ac ../*.c ../*.C ../*.h ../*.sh ../*.txt ../T2runtime .
    
    ./bootstrap
    ./configure --prefix=$BUILD_PREFIX --disable-local --disable-psrhome PGPLOT_DIR=$PREFIX/include/pgplot
    make -j${CPU_COUNT}

    popd
  )
  export PATH=`pwd`/native-build:$PATH
fi

./bootstrap
./configure --prefix=$PREFIX --disable-local --disable-psrhome PGPLOT_DIR=$PREFIX/include/pgplot
make -j${CPU_COUNT}

make install
make -j${CPU_COUNT} plugins
make plugins-install

# Copy runtime stuff
for dir in atmosphere ephemeris example_data observatory plugin_data solarWindModel clock earth
do
    cp -a T2runtime/$dir $TEMPO2/
done

# This foo will make conda automatically define a TEMPO2 env variable
# when the environment is activated.

ACTIVATE_DIR=${PREFIX}/etc/conda/activate.d
DEACTIVATE_DIR=${PREFIX}/etc/conda/deactivate.d
mkdir -p ${ACTIVATE_DIR}
mkdir -p ${DEACTIVATE_DIR}

cp ${RECIPE_DIR}/scripts/activate.sh ${ACTIVATE_DIR}/tempo2-activate.sh
cp ${RECIPE_DIR}/scripts/deactivate.sh ${DEACTIVATE_DIR}/tempo2-deactivate.sh
cp ${RECIPE_DIR}/scripts/activate.csh ${ACTIVATE_DIR}/tempo2-activate.csh
cp ${RECIPE_DIR}/scripts/deactivate.csh ${DEACTIVATE_DIR}/tempo2-deactivate.csh
cp ${RECIPE_DIR}/scripts/activate.fish ${ACTIVATE_DIR}/tempo2-activate.fish
cp ${RECIPE_DIR}/scripts/deactivate.fish ${DEACTIVATE_DIR}/tempo2-deactivate.fish
