@ECHO ON

mkdir build
cd build
rem fortran support is currently disabled on windows using 'disable-fortran.patch',
rem so the following 2 lines are commented out
rem set FCFLAGS=-fdefault-integer-8 %FCFLAGS%
rem set FFLAGS=-fdefault-integer-8 %FFLAGS%

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
  -D MED_MEDINT_TYPE=int ^
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
