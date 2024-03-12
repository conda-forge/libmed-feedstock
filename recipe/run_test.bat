@ECHO ON

cd tests
rem Print files in the current directory
dir

cl.exe /I %CONDA_PREFIX%\include test_med_int_size.c /link /LIBPATH:%CONDA_PREFIX%\Library\lib medC.lib /out:test_med_int_size.exe

test_med_int_size.exe
