@ECHO ON

mkdir build
cd build

cmake -G "Ninja" ^
  %CMAKE_ARGS% ^
  -D Python_FIND_STRATEGY:STRING=LOCATION ^
  -D Python_FIND_REGISTRY:STRING=NEVER ^
  -D Python3_ROOT_DIR:FILEPATH="%PREFIX%" ^
  -D HDF5_ROOT_DIR:FILEPATH="%LIBRARY_PREFIX%" ^
  -D MEDFILE_INSTALL_DOC=OFF ^
  -D MEDFILE_BUILD_PYTHON=ON ^
  -D MEDFILE_BUILD_TESTS=OFF ^
  -D MEDFILE_BUILD_SHARED_LIBS=ON ^
  -D MEDFILE_BUILD_STATIC_LIBS=OFF ^
  -D MEDFILE_USE_UNICODE=OFF ^
  ..

if errorlevel 1 exit 1
ninja
if errorlevel 1 exit 1
mkdir %SP_DIR%\med
if errorlevel 1 exit 1
ninja install
if errorlevel 1 exit 1

copy %LIBRARY_BIN%\mdump4.exe %LIBRARY_BIN%\mdump.exe
if errorlevel 1 exit 1
copy %LIBRARY_BIN%\xmdump4 %LIBRARY_BIN%\xmdump
if errorlevel 1 exit 1
