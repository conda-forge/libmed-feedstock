@ECHO ON

setlocal

mkdir build
cd build

:: Needed by IFX
set "LIB=%BUILD_PREFIX%\Library\lib;%LIB%"
set "INCLUDE=%BUILD_PREFIX%\opt\compiler\include\intel64;%INCLUDE%"

set FCFLAGS=/fpp /nologo %FCFLAGS%

:: Remove 'bidon' dummy parameters from PPRO_NT C wrappers.
:: With default ifx calling convention (string lengths at end of arg list),
:: these parameters shift all arguments by one and cause ACCESS_VIOLATION.
python %RECIPE_DIR%\fix_iface.py ..
if errorlevel 1 exit 1

cmake -G "Ninja" ^
  %CMAKE_ARGS% ^
  -D HDF5_BUILD_FORTRAN:BOOL=ON ^
  -D CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS:BOOL=ON ^
  -D Python_FIND_STRATEGY:STRING=LOCATION ^
  -D Python_FIND_REGISTRY:STRING=NEVER ^
  -D Python3_ROOT_DIR:FILEPATH="%PREFIX%" ^
  -D HDF5_ROOT_DIR:FILEPATH="%LIBRARY_PREFIX%" ^
  -D CMAKE_Fortran_FLAGS:STRING="%FCFLAGS%" ^
  -D MEDFILE_INSTALL_DOC=OFF ^
  -D MEDFILE_BUILD_PYTHON=ON ^
  -D MEDFILE_BUILD_TESTS=OFF ^
  -D MEDFILE_BUILD_SHARED_LIBS=ON ^
  -D MEDFILE_BUILD_STATIC_LIBS=OFF ^
  -D MEDFILE_USE_UNICODE=OFF ^
  -D MED_MEDINT_TYPE=int ^
  ..

if errorlevel 1 exit 1

:: First pass: build everything (Fortran symbols exported as UPPERCASE)
ninja
if errorlevel 1 exit 1

:: Add lowercase+underscore aliases (e.g. mfacre_ = MFACRE) to auto-generated .def files
:: so that code_aster compiled with /names:lowercase /assume:underscore can link against libmed
python %RECIPE_DIR%\fix_exports.py .
if errorlevel 1 exit 1

:: Force re-link by deleting DLLs (ninja won't detect .def changes)
del /Q src\medC.dll src\medfwrap.dll src\med.dll 2>NUL

:: Second pass: re-link DLLs so they export both MFACRE and mfacre_
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

endlocal
