:: dont print script content to the screen when running
@echo off

:: show bare files when running dir command
doskey ls=dir /w $*
doskey ll=dir /b $*
