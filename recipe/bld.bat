@echo on

meson setup builddir           ^
    %MESON_ARGS%               ^
    -Denable_tests=false
if errorlevel 1 exit 1

meson compile -C builddir
if errorlevel 1 exit 1

meson install -C builddir --no-rebuild --strip
if errorlevel 1 exit 1
