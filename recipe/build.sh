set -ex

mkdir $SRC_DIR/stage

meson setup builddir          \
    ${MESON_ARGS}             \
    --prefix=$SRC_DIR/stage   \
    -Denable_tests=false

meson compile -C builddir

meson install -C builddir --no-rebuild

sed -i.bak "s,$SRC_DIR/stage,/opt/anaconda1anaconda2anaconda3,g" $SRC_DIR/stage/lib/pkgconfig/*.pc
rm $SRC_DIR/stage/lib/pkgconfig/*.bak
