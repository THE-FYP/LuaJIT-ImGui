local cimguimodule = 'cimgui_glfw' --set imgui directory location
local ffi = require"ffi"
local cdecl = require"imgui.cdefs"

local ffi_cdef = function(code)
    local ret,err = pcall(ffi.cdef,code)
    if not ret then
        local lineN = 1
        for line in code:gmatch("([^\n\r]*)\r?\n") do
            print(lineN, line)
            lineN = lineN + 1
        end
        print(err)
        error"bad cdef"
    end
end


assert(cdecl, "imgui.lua not properly build")
ffi.cdef(cdecl)


--load dll
local lib = ffi.load(cimguimodule)

-----------ImVec2 definition
local ImVec2 
ImVec2 = ffi.metatype("ImVec2",{
    __add = function(a,b) return ImVec2(a.x + b.x, a.y + b.y) end,
    __sub = function(a,b) return ImVec2(a.x - b.x, a.y - b.y) end,
    __unm = function(a) return ImVec2(-a.x,-a.y) end,
    __mul = function(a, b) --scalar mult
        if not ffi.istype(ImVec2, b) then
        return ImVec2(a.x * b, a.y * b) end
        return ImVec2(a * b.x, a * b.y)
    end,
    __tostring = function(v) return 'ImVec2<'..v.x..','..v.y..'>' end
})
local ImVec4= {}
ImVec4.__index = ImVec4
ImVec4 = ffi.metatype("ImVec4",ImVec4)
--the module
local M = {ImVec2 = ImVec2, ImVec4 = ImVec4 ,lib = lib}

if jit.os == "Windows" then
    function M.ToUTF(unc_str)
        local buf_len = lib.igImTextCountUtf8BytesFromStr(unc_str, nil) + 1;
        local buf_local = ffi.new("char[?]",buf_len)
        lib.igImTextStrToUtf8(buf_local, buf_len, unc_str, nil);
        return buf_local
    end
    
    function M.FromUTF(utf_str)
        local wbuf_length = lib.igImTextCountCharsFromUtf8(utf_str, nil) + 1;
        local buf_local = ffi.new("ImWchar[?]",wbuf_length)
        lib.igImTextStrFromUtf8(buf_local, wbuf_length, utf_str, nil,nil);
        return buf_local
    end
end

M.FLT_MAX = lib.igGET_FLT_MAX()

-----------ImGui_ImplGlfwGL3
local ImGui_ImplGlfwGL3 = {}
ImGui_ImplGlfwGL3.__index = ImGui_ImplGlfwGL3

local gl3w_inited = false
function ImGui_ImplGlfwGL3.__new()
    if gl3w_inited == false then
        lib.Do_gl3wInit()
        gl3w_inited = true
    end
    local ptr = lib.ImGui_ImplGlfwGL3_new()
    ffi.gc(ptr,lib.ImGui_ImplGlfwGL3_delete)
    return ptr
end

function ImGui_ImplGlfwGL3:destroy()
    ffi.gc(self,nil) --prevent gc twice
    lib.ImGui_ImplGlfwGL3_delete(self)
end

function ImGui_ImplGlfwGL3:NewFrame()
    return lib.ImGui_ImplGlfwGL3_NewFrame(self)
end

function ImGui_ImplGlfwGL3:Render()
    return lib.ImGui_ImplGlfwGL3_Render(self)
end

function ImGui_ImplGlfwGL3:Init(window, install_callbacks)
    return lib.ImGui_ImplGlfwGL3_Init(self, window,install_callbacks);
end

function ImGui_ImplGlfwGL3.KeyCallback(window, key,scancode, action, mods)
    return lib.ImGui_ImplGlfwGL3_KeyCallback(window, key,scancode, action, mods);
end

function ImGui_ImplGlfwGL3.MouseButtonCallback(win, button, action, mods)
    return lib.ImGui_ImplGlfwGL3_MouseButtonCallback(win, button, action, mods)
end

function ImGui_ImplGlfwGL3.ScrollCallback(window,xoffset,yoffset)
    return lib.ImGui_ImplGlfwGL3_MouseButtonCallback(window,xoffset,yoffset)
end

function ImGui_ImplGlfwGL3.CharCallback(window,c)
    return lib.ImGui_ImplGlfwGL3_CharCallback(window, c);
end

M.ImplGlfwGL3 = ffi.metatype("ImGui_ImplGlfwGL3",ImGui_ImplGlfwGL3)

-----------------------Imgui_Impl_SDL_opengl3
local Imgui_Impl_SDL_opengl3 = {}
Imgui_Impl_SDL_opengl3.__index = Imgui_Impl_SDL_opengl3

function Imgui_Impl_SDL_opengl3.__call()
    if gl3w_inited == false then
        lib.Do_gl3wInit()
        gl3w_inited = true
    end
    return setmetatable({ctx = lib.igCreateContext(nil)},Imgui_Impl_SDL_opengl3)
end

function Imgui_Impl_SDL_opengl3:Init(window, gl_context, glsl_version)
    self.window = window
	glsl_version = glsl_version or "#version 150"
    lib.ImGui_ImplSDL2_InitForOpenGL(window, gl_context);
    lib.ImGui_ImplOpenGL3_Init(glsl_version);
end

function Imgui_Impl_SDL_opengl3:destroy()
    lib.ImGui_ImplOpenGL3_Shutdown();
    lib.ImGui_ImplSDL2_Shutdown();
    lib.igDestroyContext(self.ctx);
end

function Imgui_Impl_SDL_opengl3:NewFrame()
    lib.ImGui_ImplOpenGL3_NewFrame();
    lib.ImGui_ImplSDL2_NewFrame(self.window);
    lib.igNewFrame();
end

function Imgui_Impl_SDL_opengl3:Render()
    lib.igRender()
    lib.ImGui_ImplOpenGL3_RenderDrawData(lib.igGetDrawData());
end
M.Imgui_Impl_SDL_opengl3 = setmetatable({},Imgui_Impl_SDL_opengl3)
-----------------------Imgui_Impl_SDL_opengl2
local Imgui_Impl_SDL_opengl2 = {}
Imgui_Impl_SDL_opengl2.__index = Imgui_Impl_SDL_opengl2

function Imgui_Impl_SDL_opengl2.__call()
    return setmetatable({ctx = lib.igCreateContext(nil)},Imgui_Impl_SDL_opengl2)
end

function Imgui_Impl_SDL_opengl2:Init(window, gl_context)
    self.window = window
    lib.ImGui_ImplSDL2_InitForOpenGL(window, gl_context);
    lib.ImGui_ImplOpenGL2_Init();
end

function Imgui_Impl_SDL_opengl2:destroy()
    lib.ImGui_ImplOpenGL2_Shutdown();
    lib.ImGui_ImplSDL2_Shutdown();
    lib.igDestroyContext(self.ctx);
end

function Imgui_Impl_SDL_opengl2:NewFrame()
    lib.ImGui_ImplOpenGL2_NewFrame();
    lib.ImGui_ImplSDL2_NewFrame(self.window);
    lib.igNewFrame();
end

function Imgui_Impl_SDL_opengl2:Render()
    lib.igRender()
    lib.ImGui_ImplOpenGL2_RenderDrawData(lib.igGetDrawData());
end
M.Imgui_Impl_SDL_opengl2 = setmetatable({},Imgui_Impl_SDL_opengl2)
-----------------------Imgui_Impl_glfw_opengl3
local Imgui_Impl_glfw_opengl3 = {}
Imgui_Impl_glfw_opengl3.__index = Imgui_Impl_glfw_opengl3

function Imgui_Impl_glfw_opengl3.__call()
    if gl3w_inited == false then
        lib.Do_gl3wInit()
        gl3w_inited = true
    end
    return setmetatable({ctx = lib.igCreateContext(nil)},Imgui_Impl_glfw_opengl3)
end

function Imgui_Impl_glfw_opengl3:Init(window, install_callbacks,glsl_version)
	glsl_version = glsl_version or "#version 150"
    lib.ImGui_ImplGlfw_InitForOpenGL(window, install_callbacks);
    lib.ImGui_ImplOpenGL3_Init(glsl_version);
end

function Imgui_Impl_glfw_opengl3:destroy()
    lib.ImGui_ImplOpenGL3_Shutdown();
    lib.ImGui_ImplGlfw_Shutdown();
    lib.igDestroyContext(self.ctx);
end

function Imgui_Impl_glfw_opengl3:NewFrame()
    lib.ImGui_ImplOpenGL3_NewFrame();
    lib.ImGui_ImplGlfw_NewFrame();
    lib.igNewFrame();
end

function Imgui_Impl_glfw_opengl3:Render()
    lib.igRender()
    lib.ImGui_ImplOpenGL3_RenderDrawData(lib.igGetDrawData());
end

function Imgui_Impl_glfw_opengl3.KeyCallback(window, key,scancode, action, mods)
    return lib.ImGui_ImplGlfw_KeyCallback(window, key,scancode, action, mods);
end

function Imgui_Impl_glfw_opengl3.MouseButtonCallback(win, button, action, mods)
    return lib.ImGui_ImplGlfw_MouseButtonCallback(win, button, action, mods)
end

function Imgui_Impl_glfw_opengl3.ScrollCallback(window,xoffset,yoffset)
    return lib.ImGui_ImplGlfw_ScrollCallback(window,xoffset,yoffset)
end

function Imgui_Impl_glfw_opengl3.CharCallback(window,c)
    return lib.ImGui_ImplGlfw_CharCallback(window, c);
end

M.Imgui_Impl_glfw_opengl3 = setmetatable({},Imgui_Impl_glfw_opengl3)

-----------------------Imgui_Impl_glfw_opengl2
local Imgui_Impl_glfw_opengl2 = {}
Imgui_Impl_glfw_opengl2.__index = Imgui_Impl_glfw_opengl2

function Imgui_Impl_glfw_opengl2.__call()
    return setmetatable({ctx = lib.igCreateContext(nil)},Imgui_Impl_glfw_opengl2)
end

function Imgui_Impl_glfw_opengl2:Init(window, install_callbacks)
    lib.ImGui_ImplGlfw_InitForOpenGL(window, install_callbacks);
    lib.ImGui_ImplOpenGL2_Init();
end

function Imgui_Impl_glfw_opengl2:destroy()
    lib.ImGui_ImplOpenGL2_Shutdown();
    lib.ImGui_ImplGlfw_Shutdown();
    lib.igDestroyContext(self.ctx);
end

function Imgui_Impl_glfw_opengl2:NewFrame()
    lib.ImGui_ImplOpenGL2_NewFrame();
    lib.ImGui_ImplGlfw_NewFrame();
    lib.igNewFrame();
end

function Imgui_Impl_glfw_opengl2:Render()
    lib.igRender()
    lib.ImGui_ImplOpenGL2_RenderDrawData(lib.igGetDrawData());
end

function Imgui_Impl_glfw_opengl2.KeyCallback(window, key,scancode, action, mods)
    return lib.ImGui_ImplGlfw_KeyCallback(window, key,scancode, action, mods);
end

function Imgui_Impl_glfw_opengl2.MouseButtonCallback(win, button, action, mods)
    return lib.ImGui_ImplGlfw_MouseButtonCallback(win, button, action, mods)
end

function Imgui_Impl_glfw_opengl2.ScrollCallback(window,xoffset,yoffset)
    return lib.ImGui_ImplGlfw_ScrollCallback(window,xoffset,yoffset)
end

function Imgui_Impl_glfw_opengl2.CharCallback(window,c)
    return lib.ImGui_ImplGlfw_CharCallback(window, c);
end

M.Imgui_Impl_glfw_opengl2 = setmetatable({},Imgui_Impl_glfw_opengl2)
-----------------------another Log
local Log = {}
Log.__index = Log
function Log.__new()
    local ptr = lib.Log_new()
    ffi.gc(ptr,lib.Log_delete)
    return ptr
end
function Log:Add(fmt,...)
    lib.Log_Add(self,fmt,...)
end
function Log:Draw(title)
    title = title or "Log"
    lib.Log_Draw(self,title)
end
M.Log = ffi.metatype("Log",Log)
------------convenience function
function M.U32(a,b,c,d) return lib.igGetColorU32Vec4(ImVec4(a,b,c,d or 1)) end

---------------for using nonUDT2 versions
function M.use_nonUDT2()
    for k,v in pairs(M) do
        if M[k.."_nonUDT2"] then
            M[k] = M[k.."_nonUDT2"]
        end
    end
end


----------BEGIN_AUTOGENERATED_LUA---------------------------
--------------------------ImFontConfig----------------------------
local ImFontConfig= {}
ImFontConfig.__index = ImFontConfig
function ImFontConfig.__new(ctype)
    local ptr = lib.ImFontConfig_ImFontConfig()
    return ffi.gc(ptr,lib.ImFontConfig_destroy)
end
M.ImFontConfig = ffi.metatype("ImFontConfig",ImFontConfig)
--------------------------ImDrawList----------------------------
local ImDrawList= {}
ImDrawList.__index = ImDrawList
function ImDrawList:AddBezierCurve(pos0,cp0,cp1,pos1,col,thickness,num_segments)
    num_segments = num_segments or 0
    return lib.ImDrawList_AddBezierCurve(self,pos0,cp0,cp1,pos1,col,thickness,num_segments)
end
ImDrawList.AddCallback = lib.ImDrawList_AddCallback
function ImDrawList:AddCircle(center,radius,col,num_segments,thickness)
    num_segments = num_segments or 12
    thickness = thickness or 1.0
    return lib.ImDrawList_AddCircle(self,center,radius,col,num_segments,thickness)
end
function ImDrawList:AddCircleFilled(center,radius,col,num_segments)
    num_segments = num_segments or 12
    return lib.ImDrawList_AddCircleFilled(self,center,radius,col,num_segments)
end
ImDrawList.AddConvexPolyFilled = lib.ImDrawList_AddConvexPolyFilled
ImDrawList.AddDrawCmd = lib.ImDrawList_AddDrawCmd
function ImDrawList:AddImage(user_texture_id,p_min,p_max,uv_min,uv_max,col)
    uv_max = uv_max or ImVec2(1,1)
    uv_min = uv_min or ImVec2(0,0)
    col = col or 4294967295
    return lib.ImDrawList_AddImage(self,user_texture_id,p_min,p_max,uv_min,uv_max,col)
end
function ImDrawList:AddImageQuad(user_texture_id,p1,p2,p3,p4,uv1,uv2,uv3,uv4,col)
    uv1 = uv1 or ImVec2(0,0)
    uv2 = uv2 or ImVec2(1,0)
    col = col or 4294967295
    uv3 = uv3 or ImVec2(1,1)
    uv4 = uv4 or ImVec2(0,1)
    return lib.ImDrawList_AddImageQuad(self,user_texture_id,p1,p2,p3,p4,uv1,uv2,uv3,uv4,col)
end
function ImDrawList:AddImageRounded(user_texture_id,p_min,p_max,uv_min,uv_max,col,rounding,rounding_corners)
    rounding_corners = rounding_corners or lib.ImDrawCornerFlags_All
    return lib.ImDrawList_AddImageRounded(self,user_texture_id,p_min,p_max,uv_min,uv_max,col,rounding,rounding_corners)
end
function ImDrawList:AddLine(p1,p2,col,thickness)
    thickness = thickness or 1.0
    return lib.ImDrawList_AddLine(self,p1,p2,col,thickness)
end
ImDrawList.AddPolyline = lib.ImDrawList_AddPolyline
function ImDrawList:AddQuad(p1,p2,p3,p4,col,thickness)
    thickness = thickness or 1.0
    return lib.ImDrawList_AddQuad(self,p1,p2,p3,p4,col,thickness)
end
ImDrawList.AddQuadFilled = lib.ImDrawList_AddQuadFilled
function ImDrawList:AddRect(p_min,p_max,col,rounding,rounding_corners,thickness)
    rounding = rounding or 0.0
    thickness = thickness or 1.0
    rounding_corners = rounding_corners or lib.ImDrawCornerFlags_All
    return lib.ImDrawList_AddRect(self,p_min,p_max,col,rounding,rounding_corners,thickness)
end
function ImDrawList:AddRectFilled(p_min,p_max,col,rounding,rounding_corners)
    rounding = rounding or 0.0
    rounding_corners = rounding_corners or lib.ImDrawCornerFlags_All
    return lib.ImDrawList_AddRectFilled(self,p_min,p_max,col,rounding,rounding_corners)
end
ImDrawList.AddRectFilledMultiColor = lib.ImDrawList_AddRectFilledMultiColor
function ImDrawList:AddText(pos,col,text_begin,text_end)
    text_end = text_end or nil
    return lib.ImDrawList_AddText(self,pos,col,text_begin,text_end)
end
function ImDrawList:AddTextFontPtr(font,font_size,pos,col,text_begin,text_end,wrap_width,cpu_fine_clip_rect)
    text_end = text_end or nil
    cpu_fine_clip_rect = cpu_fine_clip_rect or nil
    wrap_width = wrap_width or 0.0
    return lib.ImDrawList_AddTextFontPtr(self,font,font_size,pos,col,text_begin,text_end,wrap_width,cpu_fine_clip_rect)
end
function ImDrawList:AddTriangle(p1,p2,p3,col,thickness)
    thickness = thickness or 1.0
    return lib.ImDrawList_AddTriangle(self,p1,p2,p3,col,thickness)
end
ImDrawList.AddTriangleFilled = lib.ImDrawList_AddTriangleFilled
ImDrawList.ChannelsMerge = lib.ImDrawList_ChannelsMerge
ImDrawList.ChannelsSetCurrent = lib.ImDrawList_ChannelsSetCurrent
ImDrawList.ChannelsSplit = lib.ImDrawList_ChannelsSplit
ImDrawList.Clear = lib.ImDrawList_Clear
ImDrawList.ClearFreeMemory = lib.ImDrawList_ClearFreeMemory
ImDrawList.CloneOutput = lib.ImDrawList_CloneOutput
function ImDrawList:GetClipRectMax()
    local nonUDT_out = ffi.new("ImVec2")
    lib.ImDrawList_GetClipRectMax_nonUDT(nonUDT_out,self)
    return nonUDT_out
end
ImDrawList.GetClipRectMax_nonUDT2 = lib.ImDrawList_GetClipRectMax_nonUDT2
function ImDrawList:GetClipRectMin()
    local nonUDT_out = ffi.new("ImVec2")
    lib.ImDrawList_GetClipRectMin_nonUDT(nonUDT_out,self)
    return nonUDT_out
end
ImDrawList.GetClipRectMin_nonUDT2 = lib.ImDrawList_GetClipRectMin_nonUDT2
function ImDrawList.__new(ctype,shared_data)
    local ptr = lib.ImDrawList_ImDrawList(shared_data)
    return ffi.gc(ptr,lib.ImDrawList_destroy)
end
function ImDrawList:PathArcTo(center,radius,a_min,a_max,num_segments)
    num_segments = num_segments or 10
    return lib.ImDrawList_PathArcTo(self,center,radius,a_min,a_max,num_segments)
end
ImDrawList.PathArcToFast = lib.ImDrawList_PathArcToFast
function ImDrawList:PathBezierCurveTo(p1,p2,p3,num_segments)
    num_segments = num_segments or 0
    return lib.ImDrawList_PathBezierCurveTo(self,p1,p2,p3,num_segments)
end
ImDrawList.PathClear = lib.ImDrawList_PathClear
ImDrawList.PathFillConvex = lib.ImDrawList_PathFillConvex
ImDrawList.PathLineTo = lib.ImDrawList_PathLineTo
ImDrawList.PathLineToMergeDuplicate = lib.ImDrawList_PathLineToMergeDuplicate
function ImDrawList:PathRect(rect_min,rect_max,rounding,rounding_corners)
    rounding = rounding or 0.0
    rounding_corners = rounding_corners or lib.ImDrawCornerFlags_All
    return lib.ImDrawList_PathRect(self,rect_min,rect_max,rounding,rounding_corners)
end
function ImDrawList:PathStroke(col,closed,thickness)
    thickness = thickness or 1.0
    return lib.ImDrawList_PathStroke(self,col,closed,thickness)
end
ImDrawList.PopClipRect = lib.ImDrawList_PopClipRect
ImDrawList.PopTextureID = lib.ImDrawList_PopTextureID
ImDrawList.PrimQuadUV = lib.ImDrawList_PrimQuadUV
ImDrawList.PrimRect = lib.ImDrawList_PrimRect
ImDrawList.PrimRectUV = lib.ImDrawList_PrimRectUV
ImDrawList.PrimReserve = lib.ImDrawList_PrimReserve
ImDrawList.PrimVtx = lib.ImDrawList_PrimVtx
ImDrawList.PrimWriteIdx = lib.ImDrawList_PrimWriteIdx
ImDrawList.PrimWriteVtx = lib.ImDrawList_PrimWriteVtx
function ImDrawList:PushClipRect(clip_rect_min,clip_rect_max,intersect_with_current_clip_rect)
    intersect_with_current_clip_rect = intersect_with_current_clip_rect or false
    return lib.ImDrawList_PushClipRect(self,clip_rect_min,clip_rect_max,intersect_with_current_clip_rect)
end
ImDrawList.PushClipRectFullScreen = lib.ImDrawList_PushClipRectFullScreen
ImDrawList.PushTextureID = lib.ImDrawList_PushTextureID
ImDrawList.UpdateClipRect = lib.ImDrawList_UpdateClipRect
ImDrawList.UpdateTextureID = lib.ImDrawList_UpdateTextureID
M.ImDrawList = ffi.metatype("ImDrawList",ImDrawList)
--------------------------ImGuiTextRange----------------------------
local ImGuiTextRange= {}
ImGuiTextRange.__index = ImGuiTextRange
function ImGuiTextRange.__new(ctype)
    local ptr = lib.ImGuiTextRange_ImGuiTextRange()
    return ffi.gc(ptr,lib.ImGuiTextRange_destroy)
end
function ImGuiTextRange.ImGuiTextRangeStr(_b,_e)
    local ptr = lib.ImGuiTextRange_ImGuiTextRangeStr(_b,_e)
    return ffi.gc(ptr,lib.ImGuiTextRange_destroy)
end
ImGuiTextRange.empty = lib.ImGuiTextRange_empty
ImGuiTextRange.split = lib.ImGuiTextRange_split
M.ImGuiTextRange = ffi.metatype("ImGuiTextRange",ImGuiTextRange)
--------------------------ImFontGlyphRangesBuilder----------------------------
local ImFontGlyphRangesBuilder= {}
ImFontGlyphRangesBuilder.__index = ImFontGlyphRangesBuilder
ImFontGlyphRangesBuilder.AddChar = lib.ImFontGlyphRangesBuilder_AddChar
ImFontGlyphRangesBuilder.AddRanges = lib.ImFontGlyphRangesBuilder_AddRanges
function ImFontGlyphRangesBuilder:AddText(text,text_end)
    text_end = text_end or nil
    return lib.ImFontGlyphRangesBuilder_AddText(self,text,text_end)
end
ImFontGlyphRangesBuilder.BuildRanges = lib.ImFontGlyphRangesBuilder_BuildRanges
ImFontGlyphRangesBuilder.Clear = lib.ImFontGlyphRangesBuilder_Clear
ImFontGlyphRangesBuilder.GetBit = lib.ImFontGlyphRangesBuilder_GetBit
function ImFontGlyphRangesBuilder.__new(ctype)
    local ptr = lib.ImFontGlyphRangesBuilder_ImFontGlyphRangesBuilder()
    return ffi.gc(ptr,lib.ImFontGlyphRangesBuilder_destroy)
end
ImFontGlyphRangesBuilder.SetBit = lib.ImFontGlyphRangesBuilder_SetBit
M.ImFontGlyphRangesBuilder = ffi.metatype("ImFontGlyphRangesBuilder",ImFontGlyphRangesBuilder)
--------------------------ImGuiListClipper----------------------------
local ImGuiListClipper= {}
ImGuiListClipper.__index = ImGuiListClipper
function ImGuiListClipper:Begin(items_count,items_height)
    items_height = items_height or -1.0
    return lib.ImGuiListClipper_Begin(self,items_count,items_height)
end
ImGuiListClipper.End = lib.ImGuiListClipper_End
function ImGuiListClipper.__new(ctype,items_count,items_height)
    if items_height == nil then items_height = -1.0 end
    if items_count == nil then items_count = -1 end
    local ptr = lib.ImGuiListClipper_ImGuiListClipper(items_count,items_height)
    return ffi.gc(ptr,lib.ImGuiListClipper_destroy)
end
ImGuiListClipper.Step = lib.ImGuiListClipper_Step
M.ImGuiListClipper = ffi.metatype("ImGuiListClipper",ImGuiListClipper)
--------------------------ImFontAtlas----------------------------
local ImFontAtlas= {}
ImFontAtlas.__index = ImFontAtlas
function ImFontAtlas:AddCustomRectFontGlyph(font,id,width,height,advance_x,offset)
    offset = offset or ImVec2(0,0)
    return lib.ImFontAtlas_AddCustomRectFontGlyph(self,font,id,width,height,advance_x,offset)
end
ImFontAtlas.AddCustomRectRegular = lib.ImFontAtlas_AddCustomRectRegular
ImFontAtlas.AddFont = lib.ImFontAtlas_AddFont
function ImFontAtlas:AddFontDefault(font_cfg)
    font_cfg = font_cfg or nil
    return lib.ImFontAtlas_AddFontDefault(self,font_cfg)
end
function ImFontAtlas:AddFontFromFileTTF(filename,size_pixels,font_cfg,glyph_ranges)
    glyph_ranges = glyph_ranges or nil
    font_cfg = font_cfg or nil
    return lib.ImFontAtlas_AddFontFromFileTTF(self,filename,size_pixels,font_cfg,glyph_ranges)
end
function ImFontAtlas:AddFontFromMemoryCompressedBase85TTF(compressed_font_data_base85,size_pixels,font_cfg,glyph_ranges)
    glyph_ranges = glyph_ranges or nil
    font_cfg = font_cfg or nil
    return lib.ImFontAtlas_AddFontFromMemoryCompressedBase85TTF(self,compressed_font_data_base85,size_pixels,font_cfg,glyph_ranges)
end
function ImFontAtlas:AddFontFromMemoryCompressedTTF(compressed_font_data,compressed_font_size,size_pixels,font_cfg,glyph_ranges)
    glyph_ranges = glyph_ranges or nil
    font_cfg = font_cfg or nil
    return lib.ImFontAtlas_AddFontFromMemoryCompressedTTF(self,compressed_font_data,compressed_font_size,size_pixels,font_cfg,glyph_ranges)
end
function ImFontAtlas:AddFontFromMemoryTTF(font_data,font_size,size_pixels,font_cfg,glyph_ranges)
    glyph_ranges = glyph_ranges or nil
    font_cfg = font_cfg or nil
    return lib.ImFontAtlas_AddFontFromMemoryTTF(self,font_data,font_size,size_pixels,font_cfg,glyph_ranges)
end
ImFontAtlas.Build = lib.ImFontAtlas_Build
ImFontAtlas.CalcCustomRectUV = lib.ImFontAtlas_CalcCustomRectUV
ImFontAtlas.Clear = lib.ImFontAtlas_Clear
ImFontAtlas.ClearFonts = lib.ImFontAtlas_ClearFonts
ImFontAtlas.ClearInputData = lib.ImFontAtlas_ClearInputData
ImFontAtlas.ClearTexData = lib.ImFontAtlas_ClearTexData
ImFontAtlas.GetCustomRectByIndex = lib.ImFontAtlas_GetCustomRectByIndex
ImFontAtlas.GetGlyphRangesChineseFull = lib.ImFontAtlas_GetGlyphRangesChineseFull
ImFontAtlas.GetGlyphRangesChineseSimplifiedCommon = lib.ImFontAtlas_GetGlyphRangesChineseSimplifiedCommon
ImFontAtlas.GetGlyphRangesCyrillic = lib.ImFontAtlas_GetGlyphRangesCyrillic
ImFontAtlas.GetGlyphRangesDefault = lib.ImFontAtlas_GetGlyphRangesDefault
ImFontAtlas.GetGlyphRangesJapanese = lib.ImFontAtlas_GetGlyphRangesJapanese
ImFontAtlas.GetGlyphRangesKorean = lib.ImFontAtlas_GetGlyphRangesKorean
ImFontAtlas.GetGlyphRangesThai = lib.ImFontAtlas_GetGlyphRangesThai
ImFontAtlas.GetGlyphRangesVietnamese = lib.ImFontAtlas_GetGlyphRangesVietnamese
ImFontAtlas.GetMouseCursorTexData = lib.ImFontAtlas_GetMouseCursorTexData
function ImFontAtlas:GetTexDataAsAlpha8(out_pixels,out_width,out_height,out_bytes_per_pixel)
    out_bytes_per_pixel = out_bytes_per_pixel or nil
    return lib.ImFontAtlas_GetTexDataAsAlpha8(self,out_pixels,out_width,out_height,out_bytes_per_pixel)
end
function ImFontAtlas:GetTexDataAsRGBA32(out_pixels,out_width,out_height,out_bytes_per_pixel)
    out_bytes_per_pixel = out_bytes_per_pixel or nil
    return lib.ImFontAtlas_GetTexDataAsRGBA32(self,out_pixels,out_width,out_height,out_bytes_per_pixel)
end
function ImFontAtlas.__new(ctype)
    local ptr = lib.ImFontAtlas_ImFontAtlas()
    return ffi.gc(ptr,lib.ImFontAtlas_destroy)
end
ImFontAtlas.IsBuilt = lib.ImFontAtlas_IsBuilt
ImFontAtlas.SetTexID = lib.ImFontAtlas_SetTexID
M.ImFontAtlas = ffi.metatype("ImFontAtlas",ImFontAtlas)
--------------------------ImGuiStoragePair----------------------------
local ImGuiStoragePair= {}
ImGuiStoragePair.__index = ImGuiStoragePair
function ImGuiStoragePair.ImGuiStoragePairInt(_key,_val_i)
    local ptr = lib.ImGuiStoragePair_ImGuiStoragePairInt(_key,_val_i)
    return ffi.gc(ptr,lib.ImGuiStoragePair_destroy)
end
function ImGuiStoragePair.ImGuiStoragePairFloat(_key,_val_f)
    local ptr = lib.ImGuiStoragePair_ImGuiStoragePairFloat(_key,_val_f)
    return ffi.gc(ptr,lib.ImGuiStoragePair_destroy)
end
function ImGuiStoragePair.ImGuiStoragePairPtr(_key,_val_p)
    local ptr = lib.ImGuiStoragePair_ImGuiStoragePairPtr(_key,_val_p)
    return ffi.gc(ptr,lib.ImGuiStoragePair_destroy)
end
M.ImGuiStoragePair = ffi.metatype("ImGuiStoragePair",ImGuiStoragePair)
--------------------------ImDrawData----------------------------
local ImDrawData= {}
ImDrawData.__index = ImDrawData
ImDrawData.Clear = lib.ImDrawData_Clear
ImDrawData.DeIndexAllBuffers = lib.ImDrawData_DeIndexAllBuffers
function ImDrawData.__new(ctype)
    local ptr = lib.ImDrawData_ImDrawData()
    return ffi.gc(ptr,lib.ImDrawData_destroy)
end
ImDrawData.ScaleClipRects = lib.ImDrawData_ScaleClipRects
M.ImDrawData = ffi.metatype("ImDrawData",ImDrawData)
--------------------------ImColor----------------------------
local ImColor= {}
ImColor.__index = ImColor
function ImColor:HSV(h,s,v,a)
    a = a or 1.0
    local nonUDT_out = ffi.new("ImColor")
    lib.ImColor_HSV_nonUDT(nonUDT_out,self,h,s,v,a)
    return nonUDT_out
end
function ImColor:HSV_nonUDT2(h,s,v,a)
    a = a or 1.0
    return lib.ImColor_HSV_nonUDT2(self,h,s,v,a)
end
function ImColor.__new(ctype)
    local ptr = lib.ImColor_ImColor()
    return ffi.gc(ptr,lib.ImColor_destroy)
end
function ImColor.ImColorInt(r,g,b,a)
    if a == nil then a = 255 end
    local ptr = lib.ImColor_ImColorInt(r,g,b,a)
    return ffi.gc(ptr,lib.ImColor_destroy)
end
function ImColor.ImColorU32(rgba)
    local ptr = lib.ImColor_ImColorU32(rgba)
    return ffi.gc(ptr,lib.ImColor_destroy)
end
function ImColor.ImColorFloat(r,g,b,a)
    if a == nil then a = 1.0 end
    local ptr = lib.ImColor_ImColorFloat(r,g,b,a)
    return ffi.gc(ptr,lib.ImColor_destroy)
end
function ImColor.ImColorVec4(col)
    local ptr = lib.ImColor_ImColorVec4(col)
    return ffi.gc(ptr,lib.ImColor_destroy)
end
function ImColor:SetHSV(h,s,v,a)
    a = a or 1.0
    return lib.ImColor_SetHSV(self,h,s,v,a)
end
M.ImColor = ffi.metatype("ImColor",ImColor)
--------------------------ImFont----------------------------
local ImFont= {}
ImFont.__index = ImFont
ImFont.AddGlyph = lib.ImFont_AddGlyph
function ImFont:AddRemapChar(dst,src,overwrite_dst)
    if overwrite_dst == nil then overwrite_dst = true end
    return lib.ImFont_AddRemapChar(self,dst,src,overwrite_dst)
end
ImFont.BuildLookupTable = lib.ImFont_BuildLookupTable
function ImFont:CalcTextSizeA(size,max_width,wrap_width,text_begin,text_end,remaining)
    text_end = text_end or nil
    remaining = remaining or nil
    local nonUDT_out = ffi.new("ImVec2")
    lib.ImFont_CalcTextSizeA_nonUDT(nonUDT_out,self,size,max_width,wrap_width,text_begin,text_end,remaining)
    return nonUDT_out
end
function ImFont:CalcTextSizeA_nonUDT2(size,max_width,wrap_width,text_begin,text_end,remaining)
    text_end = text_end or nil
    remaining = remaining or nil
    return lib.ImFont_CalcTextSizeA_nonUDT2(self,size,max_width,wrap_width,text_begin,text_end,remaining)
end
ImFont.CalcWordWrapPositionA = lib.ImFont_CalcWordWrapPositionA
ImFont.ClearOutputData = lib.ImFont_ClearOutputData
ImFont.FindGlyph = lib.ImFont_FindGlyph
ImFont.FindGlyphNoFallback = lib.ImFont_FindGlyphNoFallback
ImFont.GetCharAdvance = lib.ImFont_GetCharAdvance
ImFont.GetDebugName = lib.ImFont_GetDebugName
ImFont.GrowIndex = lib.ImFont_GrowIndex
function ImFont.__new(ctype)
    local ptr = lib.ImFont_ImFont()
    return ffi.gc(ptr,lib.ImFont_destroy)
end
ImFont.IsLoaded = lib.ImFont_IsLoaded
ImFont.RenderChar = lib.ImFont_RenderChar
function ImFont:RenderText(draw_list,size,pos,col,clip_rect,text_begin,text_end,wrap_width,cpu_fine_clip)
    wrap_width = wrap_width or 0.0
    cpu_fine_clip = cpu_fine_clip or false
    return lib.ImFont_RenderText(self,draw_list,size,pos,col,clip_rect,text_begin,text_end,wrap_width,cpu_fine_clip)
end
ImFont.SetFallbackChar = lib.ImFont_SetFallbackChar
M.ImFont = ffi.metatype("ImFont",ImFont)
--------------------------ImGuiStyle----------------------------
local ImGuiStyle= {}
ImGuiStyle.__index = ImGuiStyle
function ImGuiStyle.__new(ctype)
    local ptr = lib.ImGuiStyle_ImGuiStyle()
    return ffi.gc(ptr,lib.ImGuiStyle_destroy)
end
ImGuiStyle.ScaleAllSizes = lib.ImGuiStyle_ScaleAllSizes
M.ImGuiStyle = ffi.metatype("ImGuiStyle",ImGuiStyle)
--------------------------ImGuiIO----------------------------
local ImGuiIO= {}
ImGuiIO.__index = ImGuiIO
ImGuiIO.AddInputCharacter = lib.ImGuiIO_AddInputCharacter
ImGuiIO.AddInputCharactersUTF8 = lib.ImGuiIO_AddInputCharactersUTF8
ImGuiIO.ClearInputCharacters = lib.ImGuiIO_ClearInputCharacters
function ImGuiIO.__new(ctype)
    local ptr = lib.ImGuiIO_ImGuiIO()
    return ffi.gc(ptr,lib.ImGuiIO_destroy)
end
M.ImGuiIO = ffi.metatype("ImGuiIO",ImGuiIO)
--------------------------ImGuiTextBuffer----------------------------
local ImGuiTextBuffer= {}
ImGuiTextBuffer.__index = ImGuiTextBuffer
function ImGuiTextBuffer.__new(ctype)
    local ptr = lib.ImGuiTextBuffer_ImGuiTextBuffer()
    return ffi.gc(ptr,lib.ImGuiTextBuffer_destroy)
end
function ImGuiTextBuffer:append(str,str_end)
    str_end = str_end or nil
    return lib.ImGuiTextBuffer_append(self,str,str_end)
end
ImGuiTextBuffer.appendf = lib.ImGuiTextBuffer_appendf
ImGuiTextBuffer.appendfv = lib.ImGuiTextBuffer_appendfv
ImGuiTextBuffer.begin = lib.ImGuiTextBuffer_begin
ImGuiTextBuffer.c_str = lib.ImGuiTextBuffer_c_str
ImGuiTextBuffer.clear = lib.ImGuiTextBuffer_clear
ImGuiTextBuffer.empty = lib.ImGuiTextBuffer_empty
ImGuiTextBuffer._end = lib.ImGuiTextBuffer_end
ImGuiTextBuffer.reserve = lib.ImGuiTextBuffer_reserve
ImGuiTextBuffer.size = lib.ImGuiTextBuffer_size
M.ImGuiTextBuffer = ffi.metatype("ImGuiTextBuffer",ImGuiTextBuffer)
--------------------------ImDrawListSplitter----------------------------
local ImDrawListSplitter= {}
ImDrawListSplitter.__index = ImDrawListSplitter
ImDrawListSplitter.Clear = lib.ImDrawListSplitter_Clear
ImDrawListSplitter.ClearFreeMemory = lib.ImDrawListSplitter_ClearFreeMemory
function ImDrawListSplitter.__new(ctype)
    local ptr = lib.ImDrawListSplitter_ImDrawListSplitter()
    return ffi.gc(ptr,lib.ImDrawListSplitter_destroy)
end
ImDrawListSplitter.Merge = lib.ImDrawListSplitter_Merge
ImDrawListSplitter.SetCurrentChannel = lib.ImDrawListSplitter_SetCurrentChannel
ImDrawListSplitter.Split = lib.ImDrawListSplitter_Split
M.ImDrawListSplitter = ffi.metatype("ImDrawListSplitter",ImDrawListSplitter)
--------------------------ImGuiOnceUponAFrame----------------------------
local ImGuiOnceUponAFrame= {}
ImGuiOnceUponAFrame.__index = ImGuiOnceUponAFrame
function ImGuiOnceUponAFrame.__new(ctype)
    local ptr = lib.ImGuiOnceUponAFrame_ImGuiOnceUponAFrame()
    return ffi.gc(ptr,lib.ImGuiOnceUponAFrame_destroy)
end
M.ImGuiOnceUponAFrame = ffi.metatype("ImGuiOnceUponAFrame",ImGuiOnceUponAFrame)
--------------------------ImFontAtlasCustomRect----------------------------
local ImFontAtlasCustomRect= {}
ImFontAtlasCustomRect.__index = ImFontAtlasCustomRect
function ImFontAtlasCustomRect.__new(ctype)
    local ptr = lib.ImFontAtlasCustomRect_ImFontAtlasCustomRect()
    return ffi.gc(ptr,lib.ImFontAtlasCustomRect_destroy)
end
ImFontAtlasCustomRect.IsPacked = lib.ImFontAtlasCustomRect_IsPacked
M.ImFontAtlasCustomRect = ffi.metatype("ImFontAtlasCustomRect",ImFontAtlasCustomRect)
--------------------------ImGuiPayload----------------------------
local ImGuiPayload= {}
ImGuiPayload.__index = ImGuiPayload
ImGuiPayload.Clear = lib.ImGuiPayload_Clear
function ImGuiPayload.__new(ctype)
    local ptr = lib.ImGuiPayload_ImGuiPayload()
    return ffi.gc(ptr,lib.ImGuiPayload_destroy)
end
ImGuiPayload.IsDataType = lib.ImGuiPayload_IsDataType
ImGuiPayload.IsDelivery = lib.ImGuiPayload_IsDelivery
ImGuiPayload.IsPreview = lib.ImGuiPayload_IsPreview
M.ImGuiPayload = ffi.metatype("ImGuiPayload",ImGuiPayload)
--------------------------ImDrawCmd----------------------------
local ImDrawCmd= {}
ImDrawCmd.__index = ImDrawCmd
function ImDrawCmd.__new(ctype)
    local ptr = lib.ImDrawCmd_ImDrawCmd()
    return ffi.gc(ptr,lib.ImDrawCmd_destroy)
end
M.ImDrawCmd = ffi.metatype("ImDrawCmd",ImDrawCmd)
--------------------------ImGuiStorage----------------------------
local ImGuiStorage= {}
ImGuiStorage.__index = ImGuiStorage
ImGuiStorage.BuildSortByKey = lib.ImGuiStorage_BuildSortByKey
ImGuiStorage.Clear = lib.ImGuiStorage_Clear
function ImGuiStorage:GetBool(key,default_val)
    default_val = default_val or false
    return lib.ImGuiStorage_GetBool(self,key,default_val)
end
function ImGuiStorage:GetBoolRef(key,default_val)
    default_val = default_val or false
    return lib.ImGuiStorage_GetBoolRef(self,key,default_val)
end
function ImGuiStorage:GetFloat(key,default_val)
    default_val = default_val or 0.0
    return lib.ImGuiStorage_GetFloat(self,key,default_val)
end
function ImGuiStorage:GetFloatRef(key,default_val)
    default_val = default_val or 0.0
    return lib.ImGuiStorage_GetFloatRef(self,key,default_val)
end
function ImGuiStorage:GetInt(key,default_val)
    default_val = default_val or 0
    return lib.ImGuiStorage_GetInt(self,key,default_val)
end
function ImGuiStorage:GetIntRef(key,default_val)
    default_val = default_val or 0
    return lib.ImGuiStorage_GetIntRef(self,key,default_val)
end
ImGuiStorage.GetVoidPtr = lib.ImGuiStorage_GetVoidPtr
function ImGuiStorage:GetVoidPtrRef(key,default_val)
    default_val = default_val or nil
    return lib.ImGuiStorage_GetVoidPtrRef(self,key,default_val)
end
ImGuiStorage.SetAllInt = lib.ImGuiStorage_SetAllInt
ImGuiStorage.SetBool = lib.ImGuiStorage_SetBool
ImGuiStorage.SetFloat = lib.ImGuiStorage_SetFloat
ImGuiStorage.SetInt = lib.ImGuiStorage_SetInt
ImGuiStorage.SetVoidPtr = lib.ImGuiStorage_SetVoidPtr
M.ImGuiStorage = ffi.metatype("ImGuiStorage",ImGuiStorage)
--------------------------ImGuiTextFilter----------------------------
local ImGuiTextFilter= {}
ImGuiTextFilter.__index = ImGuiTextFilter
ImGuiTextFilter.Build = lib.ImGuiTextFilter_Build
ImGuiTextFilter.Clear = lib.ImGuiTextFilter_Clear
function ImGuiTextFilter:Draw(label,width)
    label = label or "Filter(inc,-exc)"
    width = width or 0.0
    return lib.ImGuiTextFilter_Draw(self,label,width)
end
function ImGuiTextFilter.__new(ctype,default_filter)
    if default_filter == nil then default_filter = "" end
    local ptr = lib.ImGuiTextFilter_ImGuiTextFilter(default_filter)
    return ffi.gc(ptr,lib.ImGuiTextFilter_destroy)
end
ImGuiTextFilter.IsActive = lib.ImGuiTextFilter_IsActive
function ImGuiTextFilter:PassFilter(text,text_end)
    text_end = text_end or nil
    return lib.ImGuiTextFilter_PassFilter(self,text,text_end)
end
M.ImGuiTextFilter = ffi.metatype("ImGuiTextFilter",ImGuiTextFilter)
--------------------------ImGuiInputTextCallbackData----------------------------
local ImGuiInputTextCallbackData= {}
ImGuiInputTextCallbackData.__index = ImGuiInputTextCallbackData
ImGuiInputTextCallbackData.DeleteChars = lib.ImGuiInputTextCallbackData_DeleteChars
ImGuiInputTextCallbackData.HasSelection = lib.ImGuiInputTextCallbackData_HasSelection
function ImGuiInputTextCallbackData.__new(ctype)
    local ptr = lib.ImGuiInputTextCallbackData_ImGuiInputTextCallbackData()
    return ffi.gc(ptr,lib.ImGuiInputTextCallbackData_destroy)
end
function ImGuiInputTextCallbackData:InsertChars(pos,text,text_end)
    text_end = text_end or nil
    return lib.ImGuiInputTextCallbackData_InsertChars(self,pos,text,text_end)
end
M.ImGuiInputTextCallbackData = ffi.metatype("ImGuiInputTextCallbackData",ImGuiInputTextCallbackData)
------------------------------------------------------
function M.AcceptDragDropPayload(type,flags)
    flags = flags or 0
    return lib.igAcceptDragDropPayload(type,flags)
end
M.AlignTextToFramePadding = lib.igAlignTextToFramePadding
M.ArrowButton = lib.igArrowButton
function M.Begin(name,p_open,flags)
    p_open = p_open or nil
    flags = flags or 0
    return lib.igBegin(name,p_open,flags)
end
function M.BeginChild(str_id,size,border,flags)
    border = border or false
    size = size or ImVec2(0,0)
    flags = flags or 0
    return lib.igBeginChild(str_id,size,border,flags)
end
function M.BeginChildID(id,size,border,flags)
    border = border or false
    size = size or ImVec2(0,0)
    flags = flags or 0
    return lib.igBeginChildID(id,size,border,flags)
end
function M.BeginChildFrame(id,size,flags)
    flags = flags or 0
    return lib.igBeginChildFrame(id,size,flags)
end
function M.BeginCombo(label,preview_value,flags)
    flags = flags or 0
    return lib.igBeginCombo(label,preview_value,flags)
end
function M.BeginDragDropSource(flags)
    flags = flags or 0
    return lib.igBeginDragDropSource(flags)
end
M.BeginDragDropTarget = lib.igBeginDragDropTarget
M.BeginGroup = lib.igBeginGroup
M.BeginMainMenuBar = lib.igBeginMainMenuBar
function M.BeginMenu(label,enabled)
    if enabled == nil then enabled = true end
    return lib.igBeginMenu(label,enabled)
end
M.BeginMenuBar = lib.igBeginMenuBar
function M.BeginPopup(str_id,flags)
    flags = flags or 0
    return lib.igBeginPopup(str_id,flags)
end
function M.BeginPopupContextItem(str_id,mouse_button)
    mouse_button = mouse_button or 1
    str_id = str_id or nil
    return lib.igBeginPopupContextItem(str_id,mouse_button)
end
function M.BeginPopupContextVoid(str_id,mouse_button)
    mouse_button = mouse_button or 1
    str_id = str_id or nil
    return lib.igBeginPopupContextVoid(str_id,mouse_button)
end
function M.BeginPopupContextWindow(str_id,mouse_button,also_over_items)
    if also_over_items == nil then also_over_items = true end
    mouse_button = mouse_button or 1
    str_id = str_id or nil
    return lib.igBeginPopupContextWindow(str_id,mouse_button,also_over_items)
end
function M.BeginPopupModal(name,p_open,flags)
    p_open = p_open or nil
    flags = flags or 0
    return lib.igBeginPopupModal(name,p_open,flags)
end
function M.BeginTabBar(str_id,flags)
    flags = flags or 0
    return lib.igBeginTabBar(str_id,flags)
end
function M.BeginTabItem(label,p_open,flags)
    p_open = p_open or nil
    flags = flags or 0
    return lib.igBeginTabItem(label,p_open,flags)
end
M.BeginTooltip = lib.igBeginTooltip
M.Bullet = lib.igBullet
M.BulletText = lib.igBulletText
M.BulletTextV = lib.igBulletTextV
function M.Button(label,size)
    size = size or ImVec2(0,0)
    return lib.igButton(label,size)
end
M.CalcItemWidth = lib.igCalcItemWidth
M.CalcListClipping = lib.igCalcListClipping
function M.CalcTextSize(text,text_end,hide_text_after_double_hash,wrap_width)
    text_end = text_end or nil
    wrap_width = wrap_width or -1.0
    hide_text_after_double_hash = hide_text_after_double_hash or false
    local nonUDT_out = ffi.new("ImVec2")
    lib.igCalcTextSize_nonUDT(nonUDT_out,text,text_end,hide_text_after_double_hash,wrap_width)
    return nonUDT_out
end
function M.CalcTextSize_nonUDT2(text,text_end,hide_text_after_double_hash,wrap_width)
    text_end = text_end or nil
    wrap_width = wrap_width or -1.0
    hide_text_after_double_hash = hide_text_after_double_hash or false
    return lib.igCalcTextSize_nonUDT2(text,text_end,hide_text_after_double_hash,wrap_width)
end
function M.CaptureKeyboardFromApp(want_capture_keyboard_value)
    if want_capture_keyboard_value == nil then want_capture_keyboard_value = true end
    return lib.igCaptureKeyboardFromApp(want_capture_keyboard_value)
end
function M.CaptureMouseFromApp(want_capture_mouse_value)
    if want_capture_mouse_value == nil then want_capture_mouse_value = true end
    return lib.igCaptureMouseFromApp(want_capture_mouse_value)
end
M.Checkbox = lib.igCheckbox
M.CheckboxFlags = lib.igCheckboxFlags
M.CloseCurrentPopup = lib.igCloseCurrentPopup
function M.CollapsingHeader(label,flags)
    flags = flags or 0
    return lib.igCollapsingHeader(label,flags)
end
function M.CollapsingHeaderBoolPtr(label,p_open,flags)
    flags = flags or 0
    return lib.igCollapsingHeaderBoolPtr(label,p_open,flags)
end
function M.ColorButton(desc_id,col,flags,size)
    size = size or ImVec2(0,0)
    flags = flags or 0
    return lib.igColorButton(desc_id,col,flags,size)
end
M.ColorConvertFloat4ToU32 = lib.igColorConvertFloat4ToU32
M.ColorConvertHSVtoRGB = lib.igColorConvertHSVtoRGB
M.ColorConvertRGBtoHSV = lib.igColorConvertRGBtoHSV
function M.ColorConvertU32ToFloat4(_in)
    local nonUDT_out = ffi.new("ImVec4")
    lib.igColorConvertU32ToFloat4_nonUDT(nonUDT_out,_in)
    return nonUDT_out
end
M.ColorConvertU32ToFloat4_nonUDT2 = lib.igColorConvertU32ToFloat4_nonUDT2
function M.ColorEdit3(label,col,flags)
    flags = flags or 0
    return lib.igColorEdit3(label,col,flags)
end
function M.ColorEdit4(label,col,flags)
    flags = flags or 0
    return lib.igColorEdit4(label,col,flags)
end
function M.ColorPicker3(label,col,flags)
    flags = flags or 0
    return lib.igColorPicker3(label,col,flags)
end
function M.ColorPicker4(label,col,flags,ref_col)
    ref_col = ref_col or nil
    flags = flags or 0
    return lib.igColorPicker4(label,col,flags,ref_col)
end
function M.Columns(count,id,border)
    if border == nil then border = true end
    count = count or 1
    id = id or nil
    return lib.igColumns(count,id,border)
end
function M.Combo(label,current_item,items,items_count,popup_max_height_in_items)
    popup_max_height_in_items = popup_max_height_in_items or -1
    return lib.igCombo(label,current_item,items,items_count,popup_max_height_in_items)
end
function M.ComboStr(label,current_item,items_separated_by_zeros,popup_max_height_in_items)
    popup_max_height_in_items = popup_max_height_in_items or -1
    return lib.igComboStr(label,current_item,items_separated_by_zeros,popup_max_height_in_items)
end
function M.ComboFnPtr(label,current_item,items_getter,data,items_count,popup_max_height_in_items)
    popup_max_height_in_items = popup_max_height_in_items or -1
    return lib.igComboFnPtr(label,current_item,items_getter,data,items_count,popup_max_height_in_items)
end
function M.CreateContext(shared_font_atlas)
    shared_font_atlas = shared_font_atlas or nil
    return lib.igCreateContext(shared_font_atlas)
end
M.DebugCheckVersionAndDataLayout = lib.igDebugCheckVersionAndDataLayout
function M.DestroyContext(ctx)
    ctx = ctx or nil
    return lib.igDestroyContext(ctx)
end
function M.DragFloat(label,v,v_speed,v_min,v_max,format,power)
    v_max = v_max or 0.0
    format = format or "%.3f"
    power = power or 1.0
    v_speed = v_speed or 1.0
    v_min = v_min or 0.0
    return lib.igDragFloat(label,v,v_speed,v_min,v_max,format,power)
end
function M.DragFloat2(label,v,v_speed,v_min,v_max,format,power)
    v_max = v_max or 0.0
    format = format or "%.3f"
    power = power or 1.0
    v_speed = v_speed or 1.0
    v_min = v_min or 0.0
    return lib.igDragFloat2(label,v,v_speed,v_min,v_max,format,power)
end
function M.DragFloat3(label,v,v_speed,v_min,v_max,format,power)
    v_max = v_max or 0.0
    format = format or "%.3f"
    power = power or 1.0
    v_speed = v_speed or 1.0
    v_min = v_min or 0.0
    return lib.igDragFloat3(label,v,v_speed,v_min,v_max,format,power)
end
function M.DragFloat4(label,v,v_speed,v_min,v_max,format,power)
    v_max = v_max or 0.0
    format = format or "%.3f"
    power = power or 1.0
    v_speed = v_speed or 1.0
    v_min = v_min or 0.0
    return lib.igDragFloat4(label,v,v_speed,v_min,v_max,format,power)
end
function M.DragFloatRange2(label,v_current_min,v_current_max,v_speed,v_min,v_max,format,format_max,power)
    format_max = format_max or nil
    format = format or "%.3f"
    power = power or 1.0
    v_speed = v_speed or 1.0
    v_min = v_min or 0.0
    v_max = v_max or 0.0
    return lib.igDragFloatRange2(label,v_current_min,v_current_max,v_speed,v_min,v_max,format,format_max,power)
end
function M.DragInt(label,v,v_speed,v_min,v_max,format)
    v_max = v_max or 0
    format = format or "%d"
    v_speed = v_speed or 1.0
    v_min = v_min or 0
    return lib.igDragInt(label,v,v_speed,v_min,v_max,format)
end
function M.DragInt2(label,v,v_speed,v_min,v_max,format)
    v_max = v_max or 0
    format = format or "%d"
    v_speed = v_speed or 1.0
    v_min = v_min or 0
    return lib.igDragInt2(label,v,v_speed,v_min,v_max,format)
end
function M.DragInt3(label,v,v_speed,v_min,v_max,format)
    v_max = v_max or 0
    format = format or "%d"
    v_speed = v_speed or 1.0
    v_min = v_min or 0
    return lib.igDragInt3(label,v,v_speed,v_min,v_max,format)
end
function M.DragInt4(label,v,v_speed,v_min,v_max,format)
    v_max = v_max or 0
    format = format or "%d"
    v_speed = v_speed or 1.0
    v_min = v_min or 0
    return lib.igDragInt4(label,v,v_speed,v_min,v_max,format)
end
function M.DragIntRange2(label,v_current_min,v_current_max,v_speed,v_min,v_max,format,format_max)
    format_max = format_max or nil
    format = format or "%d"
    v_speed = v_speed or 1.0
    v_max = v_max or 0
    v_min = v_min or 0
    return lib.igDragIntRange2(label,v_current_min,v_current_max,v_speed,v_min,v_max,format,format_max)
end
function M.DragScalar(label,data_type,v,v_speed,v_min,v_max,format,power)
    v_max = v_max or nil
    format = format or nil
    v_min = v_min or nil
    power = power or 1.0
    return lib.igDragScalar(label,data_type,v,v_speed,v_min,v_max,format,power)
end
function M.DragScalarN(label,data_type,v,components,v_speed,v_min,v_max,format,power)
    v_max = v_max or nil
    format = format or nil
    v_min = v_min or nil
    power = power or 1.0
    return lib.igDragScalarN(label,data_type,v,components,v_speed,v_min,v_max,format,power)
end
M.Dummy = lib.igDummy
M.End = lib.igEnd
M.EndChild = lib.igEndChild
M.EndChildFrame = lib.igEndChildFrame
M.EndCombo = lib.igEndCombo
M.EndDragDropSource = lib.igEndDragDropSource
M.EndDragDropTarget = lib.igEndDragDropTarget
M.EndFrame = lib.igEndFrame
M.EndGroup = lib.igEndGroup
M.EndMainMenuBar = lib.igEndMainMenuBar
M.EndMenu = lib.igEndMenu
M.EndMenuBar = lib.igEndMenuBar
M.EndPopup = lib.igEndPopup
M.EndTabBar = lib.igEndTabBar
M.EndTabItem = lib.igEndTabItem
M.EndTooltip = lib.igEndTooltip
M.GetBackgroundDrawList = lib.igGetBackgroundDrawList
M.GetClipboardText = lib.igGetClipboardText
function M.GetColorU32(idx,alpha_mul)
    alpha_mul = alpha_mul or 1.0
    return lib.igGetColorU32(idx,alpha_mul)
end
M.GetColorU32Vec4 = lib.igGetColorU32Vec4
M.GetColorU32U32 = lib.igGetColorU32U32
M.GetColumnIndex = lib.igGetColumnIndex
function M.GetColumnOffset(column_index)
    column_index = column_index or -1
    return lib.igGetColumnOffset(column_index)
end
function M.GetColumnWidth(column_index)
    column_index = column_index or -1
    return lib.igGetColumnWidth(column_index)
end
M.GetColumnsCount = lib.igGetColumnsCount
function M.GetContentRegionAvail()
    local nonUDT_out = ffi.new("ImVec2")
    lib.igGetContentRegionAvail_nonUDT(nonUDT_out)
    return nonUDT_out
end
M.GetContentRegionAvail_nonUDT2 = lib.igGetContentRegionAvail_nonUDT2
function M.GetContentRegionMax()
    local nonUDT_out = ffi.new("ImVec2")
    lib.igGetContentRegionMax_nonUDT(nonUDT_out)
    return nonUDT_out
end
M.GetContentRegionMax_nonUDT2 = lib.igGetContentRegionMax_nonUDT2
M.GetCurrentContext = lib.igGetCurrentContext
function M.GetCursorPos()
    local nonUDT_out = ffi.new("ImVec2")
    lib.igGetCursorPos_nonUDT(nonUDT_out)
    return nonUDT_out
end
M.GetCursorPos_nonUDT2 = lib.igGetCursorPos_nonUDT2
M.GetCursorPosX = lib.igGetCursorPosX
M.GetCursorPosY = lib.igGetCursorPosY
function M.GetCursorScreenPos()
    local nonUDT_out = ffi.new("ImVec2")
    lib.igGetCursorScreenPos_nonUDT(nonUDT_out)
    return nonUDT_out
end
M.GetCursorScreenPos_nonUDT2 = lib.igGetCursorScreenPos_nonUDT2
function M.GetCursorStartPos()
    local nonUDT_out = ffi.new("ImVec2")
    lib.igGetCursorStartPos_nonUDT(nonUDT_out)
    return nonUDT_out
end
M.GetCursorStartPos_nonUDT2 = lib.igGetCursorStartPos_nonUDT2
M.GetDragDropPayload = lib.igGetDragDropPayload
M.GetDrawData = lib.igGetDrawData
M.GetDrawListSharedData = lib.igGetDrawListSharedData
M.GetFont = lib.igGetFont
M.GetFontSize = lib.igGetFontSize
function M.GetFontTexUvWhitePixel()
    local nonUDT_out = ffi.new("ImVec2")
    lib.igGetFontTexUvWhitePixel_nonUDT(nonUDT_out)
    return nonUDT_out
end
M.GetFontTexUvWhitePixel_nonUDT2 = lib.igGetFontTexUvWhitePixel_nonUDT2
M.GetForegroundDrawList = lib.igGetForegroundDrawList
M.GetFrameCount = lib.igGetFrameCount
M.GetFrameHeight = lib.igGetFrameHeight
M.GetFrameHeightWithSpacing = lib.igGetFrameHeightWithSpacing
M.GetIDStr = lib.igGetIDStr
M.GetIDRange = lib.igGetIDRange
M.GetIDPtr = lib.igGetIDPtr
M.GetIO = lib.igGetIO
function M.GetItemRectMax()
    local nonUDT_out = ffi.new("ImVec2")
    lib.igGetItemRectMax_nonUDT(nonUDT_out)
    return nonUDT_out
end
M.GetItemRectMax_nonUDT2 = lib.igGetItemRectMax_nonUDT2
function M.GetItemRectMin()
    local nonUDT_out = ffi.new("ImVec2")
    lib.igGetItemRectMin_nonUDT(nonUDT_out)
    return nonUDT_out
end
M.GetItemRectMin_nonUDT2 = lib.igGetItemRectMin_nonUDT2
function M.GetItemRectSize()
    local nonUDT_out = ffi.new("ImVec2")
    lib.igGetItemRectSize_nonUDT(nonUDT_out)
    return nonUDT_out
end
M.GetItemRectSize_nonUDT2 = lib.igGetItemRectSize_nonUDT2
M.GetKeyIndex = lib.igGetKeyIndex
M.GetKeyPressedAmount = lib.igGetKeyPressedAmount
M.GetMouseCursor = lib.igGetMouseCursor
function M.GetMouseDragDelta(button,lock_threshold)
    lock_threshold = lock_threshold or -1.0
    button = button or 0
    local nonUDT_out = ffi.new("ImVec2")
    lib.igGetMouseDragDelta_nonUDT(nonUDT_out,button,lock_threshold)
    return nonUDT_out
end
function M.GetMouseDragDelta_nonUDT2(button,lock_threshold)
    lock_threshold = lock_threshold or -1.0
    button = button or 0
    return lib.igGetMouseDragDelta_nonUDT2(button,lock_threshold)
end
function M.GetMousePos()
    local nonUDT_out = ffi.new("ImVec2")
    lib.igGetMousePos_nonUDT(nonUDT_out)
    return nonUDT_out
end
M.GetMousePos_nonUDT2 = lib.igGetMousePos_nonUDT2
function M.GetMousePosOnOpeningCurrentPopup()
    local nonUDT_out = ffi.new("ImVec2")
    lib.igGetMousePosOnOpeningCurrentPopup_nonUDT(nonUDT_out)
    return nonUDT_out
end
M.GetMousePosOnOpeningCurrentPopup_nonUDT2 = lib.igGetMousePosOnOpeningCurrentPopup_nonUDT2
M.GetScrollMaxX = lib.igGetScrollMaxX
M.GetScrollMaxY = lib.igGetScrollMaxY
M.GetScrollX = lib.igGetScrollX
M.GetScrollY = lib.igGetScrollY
M.GetStateStorage = lib.igGetStateStorage
M.GetStyle = lib.igGetStyle
M.GetStyleColorName = lib.igGetStyleColorName
M.GetStyleColorVec4 = lib.igGetStyleColorVec4
M.GetTextLineHeight = lib.igGetTextLineHeight
M.GetTextLineHeightWithSpacing = lib.igGetTextLineHeightWithSpacing
M.GetTime = lib.igGetTime
M.GetTreeNodeToLabelSpacing = lib.igGetTreeNodeToLabelSpacing
M.GetVersion = lib.igGetVersion
function M.GetWindowContentRegionMax()
    local nonUDT_out = ffi.new("ImVec2")
    lib.igGetWindowContentRegionMax_nonUDT(nonUDT_out)
    return nonUDT_out
end
M.GetWindowContentRegionMax_nonUDT2 = lib.igGetWindowContentRegionMax_nonUDT2
function M.GetWindowContentRegionMin()
    local nonUDT_out = ffi.new("ImVec2")
    lib.igGetWindowContentRegionMin_nonUDT(nonUDT_out)
    return nonUDT_out
end
M.GetWindowContentRegionMin_nonUDT2 = lib.igGetWindowContentRegionMin_nonUDT2
M.GetWindowContentRegionWidth = lib.igGetWindowContentRegionWidth
M.GetWindowDrawList = lib.igGetWindowDrawList
M.GetWindowHeight = lib.igGetWindowHeight
function M.GetWindowPos()
    local nonUDT_out = ffi.new("ImVec2")
    lib.igGetWindowPos_nonUDT(nonUDT_out)
    return nonUDT_out
end
M.GetWindowPos_nonUDT2 = lib.igGetWindowPos_nonUDT2
function M.GetWindowSize()
    local nonUDT_out = ffi.new("ImVec2")
    lib.igGetWindowSize_nonUDT(nonUDT_out)
    return nonUDT_out
end
M.GetWindowSize_nonUDT2 = lib.igGetWindowSize_nonUDT2
M.GetWindowWidth = lib.igGetWindowWidth
function M.Image(user_texture_id,size,uv0,uv1,tint_col,border_col)
    border_col = border_col or ImVec4(0,0,0,0)
    tint_col = tint_col or ImVec4(1,1,1,1)
    uv0 = uv0 or ImVec2(0,0)
    uv1 = uv1 or ImVec2(1,1)
    return lib.igImage(user_texture_id,size,uv0,uv1,tint_col,border_col)
end
function M.ImageButton(user_texture_id,size,uv0,uv1,frame_padding,bg_col,tint_col)
    uv1 = uv1 or ImVec2(1,1)
    bg_col = bg_col or ImVec4(0,0,0,0)
    uv0 = uv0 or ImVec2(0,0)
    tint_col = tint_col or ImVec4(1,1,1,1)
    frame_padding = frame_padding or -1
    return lib.igImageButton(user_texture_id,size,uv0,uv1,frame_padding,bg_col,tint_col)
end
function M.Indent(indent_w)
    indent_w = indent_w or 0.0
    return lib.igIndent(indent_w)
end
function M.InputDouble(label,v,step,step_fast,format,flags)
    step = step or 0.0
    format = format or "%.6f"
    step_fast = step_fast or 0.0
    flags = flags or 0
    return lib.igInputDouble(label,v,step,step_fast,format,flags)
end
function M.InputFloat(label,v,step,step_fast,format,flags)
    step = step or 0.0
    format = format or "%.3f"
    step_fast = step_fast or 0.0
    flags = flags or 0
    return lib.igInputFloat(label,v,step,step_fast,format,flags)
end
function M.InputFloat2(label,v,format,flags)
    format = format or "%.3f"
    flags = flags or 0
    return lib.igInputFloat2(label,v,format,flags)
end
function M.InputFloat3(label,v,format,flags)
    format = format or "%.3f"
    flags = flags or 0
    return lib.igInputFloat3(label,v,format,flags)
end
function M.InputFloat4(label,v,format,flags)
    format = format or "%.3f"
    flags = flags or 0
    return lib.igInputFloat4(label,v,format,flags)
end
function M.InputInt(label,v,step,step_fast,flags)
    step = step or 1
    step_fast = step_fast or 100
    flags = flags or 0
    return lib.igInputInt(label,v,step,step_fast,flags)
end
function M.InputInt2(label,v,flags)
    flags = flags or 0
    return lib.igInputInt2(label,v,flags)
end
function M.InputInt3(label,v,flags)
    flags = flags or 0
    return lib.igInputInt3(label,v,flags)
end
function M.InputInt4(label,v,flags)
    flags = flags or 0
    return lib.igInputInt4(label,v,flags)
end
function M.InputScalar(label,data_type,v,step,step_fast,format,flags)
    step = step or nil
    format = format or nil
    step_fast = step_fast or nil
    flags = flags or 0
    return lib.igInputScalar(label,data_type,v,step,step_fast,format,flags)
end
function M.InputScalarN(label,data_type,v,components,step,step_fast,format,flags)
    step = step or nil
    format = format or nil
    step_fast = step_fast or nil
    flags = flags or 0
    return lib.igInputScalarN(label,data_type,v,components,step,step_fast,format,flags)
end
function M.InputText(label,buf,buf_size,flags,callback,user_data)
    callback = callback or nil
    user_data = user_data or nil
    flags = flags or 0
    return lib.igInputText(label,buf,buf_size,flags,callback,user_data)
end
function M.InputTextMultiline(label,buf,buf_size,size,flags,callback,user_data)
    callback = callback or nil
    user_data = user_data or nil
    size = size or ImVec2(0,0)
    flags = flags or 0
    return lib.igInputTextMultiline(label,buf,buf_size,size,flags,callback,user_data)
end
function M.InputTextWithHint(label,hint,buf,buf_size,flags,callback,user_data)
    callback = callback or nil
    user_data = user_data or nil
    flags = flags or 0
    return lib.igInputTextWithHint(label,hint,buf,buf_size,flags,callback,user_data)
end
M.InvisibleButton = lib.igInvisibleButton
M.IsAnyItemActive = lib.igIsAnyItemActive
M.IsAnyItemFocused = lib.igIsAnyItemFocused
M.IsAnyItemHovered = lib.igIsAnyItemHovered
M.IsAnyMouseDown = lib.igIsAnyMouseDown
M.IsItemActivated = lib.igIsItemActivated
M.IsItemActive = lib.igIsItemActive
function M.IsItemClicked(mouse_button)
    mouse_button = mouse_button or 0
    return lib.igIsItemClicked(mouse_button)
end
M.IsItemDeactivated = lib.igIsItemDeactivated
M.IsItemDeactivatedAfterEdit = lib.igIsItemDeactivatedAfterEdit
M.IsItemEdited = lib.igIsItemEdited
M.IsItemFocused = lib.igIsItemFocused
function M.IsItemHovered(flags)
    flags = flags or 0
    return lib.igIsItemHovered(flags)
end
M.IsItemVisible = lib.igIsItemVisible
M.IsKeyDown = lib.igIsKeyDown
function M.IsKeyPressed(user_key_index,_repeat)
    if _repeat == nil then _repeat = true end
    return lib.igIsKeyPressed(user_key_index,_repeat)
end
M.IsKeyReleased = lib.igIsKeyReleased
function M.IsMouseClicked(button,_repeat)
    _repeat = _repeat or false
    return lib.igIsMouseClicked(button,_repeat)
end
M.IsMouseDoubleClicked = lib.igIsMouseDoubleClicked
M.IsMouseDown = lib.igIsMouseDown
function M.IsMouseDragging(button,lock_threshold)
    lock_threshold = lock_threshold or -1.0
    button = button or 0
    return lib.igIsMouseDragging(button,lock_threshold)
end
function M.IsMouseHoveringRect(r_min,r_max,clip)
    if clip == nil then clip = true end
    return lib.igIsMouseHoveringRect(r_min,r_max,clip)
end
function M.IsMousePosValid(mouse_pos)
    mouse_pos = mouse_pos or nil
    return lib.igIsMousePosValid(mouse_pos)
end
M.IsMouseReleased = lib.igIsMouseReleased
M.IsPopupOpen = lib.igIsPopupOpen
M.IsRectVisible = lib.igIsRectVisible
M.IsRectVisibleVec2 = lib.igIsRectVisibleVec2
M.IsWindowAppearing = lib.igIsWindowAppearing
M.IsWindowCollapsed = lib.igIsWindowCollapsed
function M.IsWindowFocused(flags)
    flags = flags or 0
    return lib.igIsWindowFocused(flags)
end
function M.IsWindowHovered(flags)
    flags = flags or 0
    return lib.igIsWindowHovered(flags)
end
M.LabelText = lib.igLabelText
M.LabelTextV = lib.igLabelTextV
function M.ListBoxStr_arr(label,current_item,items,items_count,height_in_items)
    height_in_items = height_in_items or -1
    return lib.igListBoxStr_arr(label,current_item,items,items_count,height_in_items)
end
function M.ListBoxFnPtr(label,current_item,items_getter,data,items_count,height_in_items)
    height_in_items = height_in_items or -1
    return lib.igListBoxFnPtr(label,current_item,items_getter,data,items_count,height_in_items)
end
M.ListBoxFooter = lib.igListBoxFooter
function M.ListBoxHeaderVec2(label,size)
    size = size or ImVec2(0,0)
    return lib.igListBoxHeaderVec2(label,size)
end
function M.ListBoxHeaderInt(label,items_count,height_in_items)
    height_in_items = height_in_items or -1
    return lib.igListBoxHeaderInt(label,items_count,height_in_items)
end
M.LoadIniSettingsFromDisk = lib.igLoadIniSettingsFromDisk
function M.LoadIniSettingsFromMemory(ini_data,ini_size)
    ini_size = ini_size or 0
    return lib.igLoadIniSettingsFromMemory(ini_data,ini_size)
end
M.LogButtons = lib.igLogButtons
M.LogFinish = lib.igLogFinish
M.LogText = lib.igLogText
function M.LogToClipboard(auto_open_depth)
    auto_open_depth = auto_open_depth or -1
    return lib.igLogToClipboard(auto_open_depth)
end
function M.LogToFile(auto_open_depth,filename)
    auto_open_depth = auto_open_depth or -1
    filename = filename or nil
    return lib.igLogToFile(auto_open_depth,filename)
end
function M.LogToTTY(auto_open_depth)
    auto_open_depth = auto_open_depth or -1
    return lib.igLogToTTY(auto_open_depth)
end
M.MemAlloc = lib.igMemAlloc
M.MemFree = lib.igMemFree
function M.MenuItemBool(label,shortcut,selected,enabled)
    if enabled == nil then enabled = true end
    shortcut = shortcut or nil
    selected = selected or false
    return lib.igMenuItemBool(label,shortcut,selected,enabled)
end
function M.MenuItemBoolPtr(label,shortcut,p_selected,enabled)
    if enabled == nil then enabled = true end
    return lib.igMenuItemBoolPtr(label,shortcut,p_selected,enabled)
end
M.NewFrame = lib.igNewFrame
M.NewLine = lib.igNewLine
M.NextColumn = lib.igNextColumn
M.OpenPopup = lib.igOpenPopup
function M.OpenPopupOnItemClick(str_id,mouse_button)
    mouse_button = mouse_button or 1
    str_id = str_id or nil
    return lib.igOpenPopupOnItemClick(str_id,mouse_button)
end
function M.PlotHistogramFloatPtr(label,values,values_count,values_offset,overlay_text,scale_min,scale_max,graph_size,stride)
    graph_size = graph_size or ImVec2(0,0)
    values_offset = values_offset or 0
    scale_max = scale_max or M.FLT_MAX
    scale_min = scale_min or M.FLT_MAX
    stride = stride or ffi.sizeof("float")
    overlay_text = overlay_text or nil
    return lib.igPlotHistogramFloatPtr(label,values,values_count,values_offset,overlay_text,scale_min,scale_max,graph_size,stride)
end
function M.PlotHistogramFnPtr(label,values_getter,data,values_count,values_offset,overlay_text,scale_min,scale_max,graph_size)
    graph_size = graph_size or ImVec2(0,0)
    values_offset = values_offset or 0
    scale_max = scale_max or M.FLT_MAX
    scale_min = scale_min or M.FLT_MAX
    overlay_text = overlay_text or nil
    return lib.igPlotHistogramFnPtr(label,values_getter,data,values_count,values_offset,overlay_text,scale_min,scale_max,graph_size)
end
function M.PlotLines(label,values,values_count,values_offset,overlay_text,scale_min,scale_max,graph_size,stride)
    graph_size = graph_size or ImVec2(0,0)
    values_offset = values_offset or 0
    scale_max = scale_max or M.FLT_MAX
    scale_min = scale_min or M.FLT_MAX
    stride = stride or ffi.sizeof("float")
    overlay_text = overlay_text or nil
    return lib.igPlotLines(label,values,values_count,values_offset,overlay_text,scale_min,scale_max,graph_size,stride)
end
function M.PlotLinesFnPtr(label,values_getter,data,values_count,values_offset,overlay_text,scale_min,scale_max,graph_size)
    graph_size = graph_size or ImVec2(0,0)
    values_offset = values_offset or 0
    scale_max = scale_max or M.FLT_MAX
    scale_min = scale_min or M.FLT_MAX
    overlay_text = overlay_text or nil
    return lib.igPlotLinesFnPtr(label,values_getter,data,values_count,values_offset,overlay_text,scale_min,scale_max,graph_size)
end
M.PopAllowKeyboardFocus = lib.igPopAllowKeyboardFocus
M.PopButtonRepeat = lib.igPopButtonRepeat
M.PopClipRect = lib.igPopClipRect
M.PopFont = lib.igPopFont
M.PopID = lib.igPopID
M.PopItemWidth = lib.igPopItemWidth
function M.PopStyleColor(count)
    count = count or 1
    return lib.igPopStyleColor(count)
end
function M.PopStyleVar(count)
    count = count or 1
    return lib.igPopStyleVar(count)
end
M.PopTextWrapPos = lib.igPopTextWrapPos
function M.ProgressBar(fraction,size_arg,overlay)
    overlay = overlay or nil
    size_arg = size_arg or ImVec2(-1,0)
    return lib.igProgressBar(fraction,size_arg,overlay)
end
M.PushAllowKeyboardFocus = lib.igPushAllowKeyboardFocus
M.PushButtonRepeat = lib.igPushButtonRepeat
M.PushClipRect = lib.igPushClipRect
M.PushFont = lib.igPushFont
M.PushIDStr = lib.igPushIDStr
M.PushIDRange = lib.igPushIDRange
M.PushIDPtr = lib.igPushIDPtr
M.PushIDInt = lib.igPushIDInt
M.PushItemWidth = lib.igPushItemWidth
M.PushStyleColorU32 = lib.igPushStyleColorU32
M.PushStyleColor = lib.igPushStyleColor
M.PushStyleVarFloat = lib.igPushStyleVarFloat
M.PushStyleVarVec2 = lib.igPushStyleVarVec2
function M.PushTextWrapPos(wrap_local_pos_x)
    wrap_local_pos_x = wrap_local_pos_x or 0.0
    return lib.igPushTextWrapPos(wrap_local_pos_x)
end
M.RadioButtonBool = lib.igRadioButtonBool
M.RadioButtonIntPtr = lib.igRadioButtonIntPtr
M.Render = lib.igRender
function M.ResetMouseDragDelta(button)
    button = button or 0
    return lib.igResetMouseDragDelta(button)
end
function M.SameLine(offset_from_start_x,spacing)
    spacing = spacing or -1.0
    offset_from_start_x = offset_from_start_x or 0.0
    return lib.igSameLine(offset_from_start_x,spacing)
end
M.SaveIniSettingsToDisk = lib.igSaveIniSettingsToDisk
function M.SaveIniSettingsToMemory(out_ini_size)
    out_ini_size = out_ini_size or nil
    return lib.igSaveIniSettingsToMemory(out_ini_size)
end
function M.Selectable(label,selected,flags,size)
    flags = flags or 0
    size = size or ImVec2(0,0)
    selected = selected or false
    return lib.igSelectable(label,selected,flags,size)
end
function M.SelectableBoolPtr(label,p_selected,flags,size)
    size = size or ImVec2(0,0)
    flags = flags or 0
    return lib.igSelectableBoolPtr(label,p_selected,flags,size)
end
M.Separator = lib.igSeparator
function M.SetAllocatorFunctions(alloc_func,free_func,user_data)
    user_data = user_data or nil
    return lib.igSetAllocatorFunctions(alloc_func,free_func,user_data)
end
M.SetClipboardText = lib.igSetClipboardText
M.SetColorEditOptions = lib.igSetColorEditOptions
M.SetColumnOffset = lib.igSetColumnOffset
M.SetColumnWidth = lib.igSetColumnWidth
M.SetCurrentContext = lib.igSetCurrentContext
M.SetCursorPos = lib.igSetCursorPos
M.SetCursorPosX = lib.igSetCursorPosX
M.SetCursorPosY = lib.igSetCursorPosY
M.SetCursorScreenPos = lib.igSetCursorScreenPos
function M.SetDragDropPayload(type,data,sz,cond)
    cond = cond or 0
    return lib.igSetDragDropPayload(type,data,sz,cond)
end
M.SetItemAllowOverlap = lib.igSetItemAllowOverlap
M.SetItemDefaultFocus = lib.igSetItemDefaultFocus
function M.SetKeyboardFocusHere(offset)
    offset = offset or 0
    return lib.igSetKeyboardFocusHere(offset)
end
M.SetMouseCursor = lib.igSetMouseCursor
function M.SetNextItemOpen(is_open,cond)
    cond = cond or 0
    return lib.igSetNextItemOpen(is_open,cond)
end
M.SetNextItemWidth = lib.igSetNextItemWidth
M.SetNextWindowBgAlpha = lib.igSetNextWindowBgAlpha
function M.SetNextWindowCollapsed(collapsed,cond)
    cond = cond or 0
    return lib.igSetNextWindowCollapsed(collapsed,cond)
end
M.SetNextWindowContentSize = lib.igSetNextWindowContentSize
M.SetNextWindowFocus = lib.igSetNextWindowFocus
function M.SetNextWindowPos(pos,cond,pivot)
    cond = cond or 0
    pivot = pivot or ImVec2(0,0)
    return lib.igSetNextWindowPos(pos,cond,pivot)
end
function M.SetNextWindowSize(size,cond)
    cond = cond or 0
    return lib.igSetNextWindowSize(size,cond)
end
function M.SetNextWindowSizeConstraints(size_min,size_max,custom_callback,custom_callback_data)
    custom_callback = custom_callback or nil
    custom_callback_data = custom_callback_data or nil
    return lib.igSetNextWindowSizeConstraints(size_min,size_max,custom_callback,custom_callback_data)
end
function M.SetScrollFromPosX(local_x,center_x_ratio)
    center_x_ratio = center_x_ratio or 0.5
    return lib.igSetScrollFromPosX(local_x,center_x_ratio)
end
function M.SetScrollFromPosY(local_y,center_y_ratio)
    center_y_ratio = center_y_ratio or 0.5
    return lib.igSetScrollFromPosY(local_y,center_y_ratio)
end
function M.SetScrollHereX(center_x_ratio)
    center_x_ratio = center_x_ratio or 0.5
    return lib.igSetScrollHereX(center_x_ratio)
end
function M.SetScrollHereY(center_y_ratio)
    center_y_ratio = center_y_ratio or 0.5
    return lib.igSetScrollHereY(center_y_ratio)
end
M.SetScrollX = lib.igSetScrollX
M.SetScrollY = lib.igSetScrollY
M.SetStateStorage = lib.igSetStateStorage
M.SetTabItemClosed = lib.igSetTabItemClosed
M.SetTooltip = lib.igSetTooltip
M.SetTooltipV = lib.igSetTooltipV
function M.SetWindowCollapsedBool(collapsed,cond)
    cond = cond or 0
    return lib.igSetWindowCollapsedBool(collapsed,cond)
end
function M.SetWindowCollapsedStr(name,collapsed,cond)
    cond = cond or 0
    return lib.igSetWindowCollapsedStr(name,collapsed,cond)
end
M.SetWindowFocus = lib.igSetWindowFocus
M.SetWindowFocusStr = lib.igSetWindowFocusStr
M.SetWindowFontScale = lib.igSetWindowFontScale
function M.SetWindowPosVec2(pos,cond)
    cond = cond or 0
    return lib.igSetWindowPosVec2(pos,cond)
end
function M.SetWindowPosStr(name,pos,cond)
    cond = cond or 0
    return lib.igSetWindowPosStr(name,pos,cond)
end
function M.SetWindowSizeVec2(size,cond)
    cond = cond or 0
    return lib.igSetWindowSizeVec2(size,cond)
end
function M.SetWindowSizeStr(name,size,cond)
    cond = cond or 0
    return lib.igSetWindowSizeStr(name,size,cond)
end
function M.ShowAboutWindow(p_open)
    p_open = p_open or nil
    return lib.igShowAboutWindow(p_open)
end
function M.ShowDemoWindow(p_open)
    p_open = p_open or nil
    return lib.igShowDemoWindow(p_open)
end
M.ShowFontSelector = lib.igShowFontSelector
function M.ShowMetricsWindow(p_open)
    p_open = p_open or nil
    return lib.igShowMetricsWindow(p_open)
end
function M.ShowStyleEditor(ref)
    ref = ref or nil
    return lib.igShowStyleEditor(ref)
end
M.ShowStyleSelector = lib.igShowStyleSelector
M.ShowUserGuide = lib.igShowUserGuide
function M.SliderAngle(label,v_rad,v_degrees_min,v_degrees_max,format)
    v_degrees_min = v_degrees_min or -360.0
    v_degrees_max = v_degrees_max or 360.0
    format = format or "%.0f deg"
    return lib.igSliderAngle(label,v_rad,v_degrees_min,v_degrees_max,format)
end
function M.SliderFloat(label,v,v_min,v_max,format,power)
    power = power or 1.0
    format = format or "%.3f"
    return lib.igSliderFloat(label,v,v_min,v_max,format,power)
end
function M.SliderFloat2(label,v,v_min,v_max,format,power)
    power = power or 1.0
    format = format or "%.3f"
    return lib.igSliderFloat2(label,v,v_min,v_max,format,power)
end
function M.SliderFloat3(label,v,v_min,v_max,format,power)
    power = power or 1.0
    format = format or "%.3f"
    return lib.igSliderFloat3(label,v,v_min,v_max,format,power)
end
function M.SliderFloat4(label,v,v_min,v_max,format,power)
    power = power or 1.0
    format = format or "%.3f"
    return lib.igSliderFloat4(label,v,v_min,v_max,format,power)
end
function M.SliderInt(label,v,v_min,v_max,format)
    format = format or "%d"
    return lib.igSliderInt(label,v,v_min,v_max,format)
end
function M.SliderInt2(label,v,v_min,v_max,format)
    format = format or "%d"
    return lib.igSliderInt2(label,v,v_min,v_max,format)
end
function M.SliderInt3(label,v,v_min,v_max,format)
    format = format or "%d"
    return lib.igSliderInt3(label,v,v_min,v_max,format)
end
function M.SliderInt4(label,v,v_min,v_max,format)
    format = format or "%d"
    return lib.igSliderInt4(label,v,v_min,v_max,format)
end
function M.SliderScalar(label,data_type,v,v_min,v_max,format,power)
    power = power or 1.0
    format = format or nil
    return lib.igSliderScalar(label,data_type,v,v_min,v_max,format,power)
end
function M.SliderScalarN(label,data_type,v,components,v_min,v_max,format,power)
    power = power or 1.0
    format = format or nil
    return lib.igSliderScalarN(label,data_type,v,components,v_min,v_max,format,power)
end
M.SmallButton = lib.igSmallButton
M.Spacing = lib.igSpacing
function M.StyleColorsClassic(dst)
    dst = dst or nil
    return lib.igStyleColorsClassic(dst)
end
function M.StyleColorsDark(dst)
    dst = dst or nil
    return lib.igStyleColorsDark(dst)
end
function M.StyleColorsLight(dst)
    dst = dst or nil
    return lib.igStyleColorsLight(dst)
end
M.Text = lib.igText
M.TextColored = lib.igTextColored
M.TextColoredV = lib.igTextColoredV
M.TextDisabled = lib.igTextDisabled
M.TextDisabledV = lib.igTextDisabledV
function M.TextUnformatted(text,text_end)
    text_end = text_end or nil
    return lib.igTextUnformatted(text,text_end)
end
M.TextV = lib.igTextV
M.TextWrapped = lib.igTextWrapped
M.TextWrappedV = lib.igTextWrappedV
M.TreeNodeStr = lib.igTreeNodeStr
M.TreeNodeStrStr = lib.igTreeNodeStrStr
M.TreeNodePtr = lib.igTreeNodePtr
function M.TreeNodeExStr(label,flags)
    flags = flags or 0
    return lib.igTreeNodeExStr(label,flags)
end
M.TreeNodeExStrStr = lib.igTreeNodeExStrStr
M.TreeNodeExPtr = lib.igTreeNodeExPtr
M.TreeNodeExVStr = lib.igTreeNodeExVStr
M.TreeNodeExVPtr = lib.igTreeNodeExVPtr
M.TreeNodeVStr = lib.igTreeNodeVStr
M.TreeNodeVPtr = lib.igTreeNodeVPtr
M.TreePop = lib.igTreePop
M.TreePushStr = lib.igTreePushStr
function M.TreePushPtr(ptr_id)
    ptr_id = ptr_id or nil
    return lib.igTreePushPtr(ptr_id)
end
function M.Unindent(indent_w)
    indent_w = indent_w or 0.0
    return lib.igUnindent(indent_w)
end
function M.VSliderFloat(label,size,v,v_min,v_max,format,power)
    power = power or 1.0
    format = format or "%.3f"
    return lib.igVSliderFloat(label,size,v,v_min,v_max,format,power)
end
function M.VSliderInt(label,size,v,v_min,v_max,format)
    format = format or "%d"
    return lib.igVSliderInt(label,size,v,v_min,v_max,format)
end
function M.VSliderScalar(label,size,data_type,v,v_min,v_max,format,power)
    power = power or 1.0
    format = format or nil
    return lib.igVSliderScalar(label,size,data_type,v,v_min,v_max,format,power)
end
M.ValueBool = lib.igValueBool
M.ValueInt = lib.igValueInt
M.ValueUint = lib.igValueUint
function M.ValueFloat(prefix,v,float_format)
    float_format = float_format or nil
    return lib.igValueFloat(prefix,v,float_format)
end
return M
----------END_AUTOGENERATED_LUA-----------------------------