@echo off
rem Runs CMake to configure nanodbc (static) for Visual Studio 2015.
rem Runs MSBuild to build the generated solution.
setlocal

rem rem #######################################################
set NANODBC_STATIC=ON
set NANODBC_INSTALL=OFF
set BOOST_ROOT=C:/local/boost_1_59_0
rem #######################################################

if not defined VS140COMNTOOLS goto :NoVS
if [%1]==[] goto :Usage
if [%1]==[32] goto :32
if [%1]==[64] goto :64
goto :Usage

:32
set NANOP=32
set MSBUILDP=x86
set GENERATOR="Visual Studio 14 2015"
goto :Build

:64
set NANOP=64
set MSBUILDP=x64
set GENERATOR="Visual Studio 14 2015 Win64"
goto :Build

:Build
set BUILDDIR=build%NANOP%
mkdir %BUILDDIR%
pushd %BUILDDIR%
"C:\Program Files (x86)\CMake\bin\cmake.exe" ^
	-G %GENERATOR% ^
	-DNANODBC_STATIC=%NANODBC_STATIC% ^
	-DNANODBC_USE_UNICODE=ON ^
	-DNANODBC_TEST=ON ^
	-DNANODBC_INSTALL=%NANODBC_INSTALL% ^
	-DBOOST_ROOT:PATH=%BOOST_ROOT% ^
	-DBOOST_LIBRARYDIR:PATH=%BOOST_ROOT%/lib%NANOP%-msvc-14.0 ^
  	..
move nanodbc.sln nanodbc%NANOP%.sln
msbuild.exe nanodbc%NANOP%.sln /p:Configuration=Release /p:Platform=%MSBUILDP%
popd
goto :EOF

:NoVS
@echo build.bat
@echo  Visual Studio 2015 not found
@echo  "%%VS140COMNTOOLS%%" environment variable not defined
exit /B 1

:Usage
@echo build.bat
@echo Usage: build.bat [32 or 64]
exit /B 1