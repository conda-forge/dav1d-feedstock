@echo on

mkdir %SRC_DIR%\stage
if errorlevel 1 exit 1

meson setup builddir           ^
    %MESON_ARGS%               ^
    --prefix=%SRC_DIR%\stage   ^
    -Denable_tests=false
if errorlevel 1 exit 1

meson compile -C builddir
if errorlevel 1 exit 1

meson install -C builddir --no-rebuild
if errorlevel 1 exit 1

setlocal EnableExtensions ENABLEDELAYEDEXPANSION

for %%f in ( "%SRC_DIR%\stage\lib\pkgconfig\*.pc" ) do (
    sed -i.bak "s,prefix=.*,prefix=/opt/anaconda1anaconda2anaconda3/Library,g" %%f
    del %%f.bak
)

endlocal
