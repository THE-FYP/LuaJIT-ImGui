# LuaJIT-ImGui

![sample](sample.png)

This is a LuaJIT binding for the excellent C++ intermediate gui [imgui](https://github.com/ocornut/imgui).
Uses cimgui to be the most "up to date" as possible.

Notes:
* currently this wrapper is based on version [1.73 of imgui]

# compiling

* run one of the scripts in the build directory from a sibling folder to the repo. If you want to install,
(recomended) add this <code>-DLUAJIT_BIN="folder where LuaJIT is"</code> to the cmake command. 
* make (or make install).
* If you didnt install in LuaJIT directory, set basedir variable in imgui.lua to the directory libimgui is found.

# trying

* Remember you also need GLFW https://github.com/sonoro1234/LuaJIT-GLFW or SDL2 https://github.com/sonoro1234/LuaJIT-SDL2 .
* You have some scripts on the examples folder.
* In case you are in a hurry, you can get all done in the releases (GLFW version only).

# binding generation

* if cimgui is updated the binding can be remade with ./lua/build.bat

# used in

* https://github.com/sonoro1234/anima