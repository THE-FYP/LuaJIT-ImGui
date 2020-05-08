﻿
local igwin = require"imgui.window"
--local win = igwin:SDL(800,400, "font loader")
local win = igwin:GLFW(800,400, "font loader")
local ffi = require"ffi"

local function codepoint_to_utf8(c)
    if     c < 128 then
        return                                                          string.char(c)
    elseif c < 2048 then
        return                                     string.char(192 + c/64, 128 + c%64)
    elseif c < 55296 or 57343 < c and c < 65536 then
        return                    string.char(224 + c/4096, 128 + c/64%64, 128 + c%64)
    elseif c < 1114112 then
        return string.char(240 + c/262144, 128 + c/4096%64, 128 + c/64%64, 128 + c%64)
    end
end

--table with choosed characters-icons
local cps = {}
local identifiers = {}
local function AddCP(name,cp)
	--check not added already
	for i,v in ipairs(cps) do
		if v.cp == cp then return end
	end
	table.insert(cps,{cp=cp,font=name,utf8=codepoint_to_utf8(cp),identifier=tostring(cp)})
	identifiers[cp] = tostring(cp)
end


local ITcb = ffi.cast("ImGuiInputTextCallback", function(data)
  --print(data)
  --io.write"callback"
  if data.EventFlag == win.ig.lib.ImGuiInputTextFlags_CallbackCompletion then
	print"completion"
  end
  return 0
end)

--this will run outside of imgui NewFrame-Render
local function ChangeFont(font,fontsize)
	local ig = win.ig

	
	local FontsAt = ig.GetIO().Fonts
	------destroy old
	FontsAt:Clear()
	ig.lib.ImGui_ImplOpenGL3_DestroyFontsTexture()
	
	------reconstruct
	--load default
	FontsAt:AddFontDefault()
	
	--prepare config for extra font
	local fnt_cfg = ig.ImFontConfig()
	fnt_cfg.PixelSnapH = true
	--use merge to see results without changing font
	--fnt_cfg.MergeMode = true
	fnt_cfg.GlyphMinAdvanceX = fontsize -- 13.0
	fnt_cfg.GlyphMaxAdvanceX = fontsize --13.0
	fnt_cfg.OversampleH = 1
	
	--maximal range allowed with ImWchar16
	local ranges = ffi.new("ImWchar[3]",{0x0001,0xFFFF,0})

	local theFONT= FontsAt:AddFontFromFileTTF(font, fontsize, fnt_cfg,ranges)
	if (theFONT == nil) then return false end
	
	--regenerate 
	ig.lib.ImGui_ImplOpenGL3_CreateFontsTexture()
	--set as default
	--ig.GetIO().FontDefault = theFONT
	return true
end

local function GetVisibleCP(font)
	local visible = {}
	for cp=0x0001,0xFFFF do
		local glyph = font:FindGlyphNoFallback(cp);
		if glyph~=nil and glyph.Visible == 1 then 
			visible[#visible + 1] = cp
		end
	end
	return visible
end


local gui = require"filebrowser"(win.ig)

local ffi = require"ffi"
local fontsize = ffi.new("float[1]",13)
local fontscale = ffi.new("float[1]",1)
local fontcps 
local init_dir = jit.os=="Windows" and [[c:/windows/Fonts]] or ""
--init_dir = [[c:/anima/lua/anima/fonts]]
local fB = gui.FileBrowser(nil,{curr_dir=init_dir,pattern=[[%.ttf$]]},function(f)
	--this will be executed before NewFrame
	win.preimgui = function()
		fontcps = nil
		if ChangeFont(f,fontsize[0]) then
			fontcps = GetVisibleCP(win.ig.GetIO().Fonts.Fonts.Data[1])
		end
		win.preimgui=nil
	end
end)

function win:draw(ig)
	if ig.Begin"Fonts" then
		if ig.Button("Load") then
			fB.open()
		end
		ig.SetNextItemWidth(200)
		ig.DragFloat("fontsize",fontsize,nil,5,20)
		ig.SetNextItemWidth(200)
		ig.DragFloat("font scale",fontscale,0.05,0.1,2)
		ig.GetIO().FontGlobalScale = fontscale[0]
		fB.draw()
	
		local Fonts = ig.GetIO().Fonts.Fonts
		if Fonts.Size > 1 then
			local font = Fonts.Data[1]
			ig.Text(font:GetDebugName());
			ig.SameLine();ig.Text(#fontcps.." visible glyphs")
			ig.PushFont(font)
			if ig.BeginChild("glyphs",ig.ImVec2(0,ig.GetFrameHeightWithSpacing() * 12),true, ig.lib.ImGuiWindowFlags_HorizontalScrollbar) then
				local txsize = ig.CalcTextSize(codepoint_to_utf8(fontcps[1]))
				local cols = math.floor(ig.GetWindowContentRegionMax().x/(txsize.x + ig.GetStyle().ItemSpacing.x +2*ig.GetStyle().FramePadding.x ))
				local base_pos = ig.GetCursorScreenPos();
				local scrly = ig.GetScrollY()
				local canvas_size = ig.GetContentRegionAvail()
				ig.PushClipRect(base_pos + ig.ImVec2(0,scrly), ig.ImVec2(base_pos.x + canvas_size.x, base_pos.y + canvas_size.y + scrly), true);
				local linenum =  math.ceil(#fontcps/cols)
				local clipper = ig.ImGuiListClipper(linenum)
				while (clipper:Step()) do
					for line = clipper.DisplayStart,clipper.DisplayEnd-1 do
						for N=line*cols+1,line*cols+cols do
							if N <=#fontcps then
								local cp = fontcps[N]
								local glyph = font:FindGlyphNoFallback(cp);
								if glyph~=nil and glyph.Visible == 1 then 
									if ig.Button(codepoint_to_utf8(cp)) then
										AddCP(font:GetDebugName(),cp)
									end
									if not ((N)%cols == 0) then ig.SameLine() end
								end
							end
						end
					end
				end
				ig.PopClipRect()
			end
			ig.EndChild()
			ig.PopFont()
			
			if ig.BeginChild("picked_gliphs",ig.ImVec2(0, -1),true) then
				ig.Columns(4)
				for i,v in ipairs(cps) do
					ig.PushFont(font)
					ig.Text(v.utf8)
					ig.PopFont()
					ig.NextColumn()
					ig.Text(string.format("0x%X",v.cp))
					ig.NextColumn()
					ig.Text(v.font)
					ig.NextColumn()
					local ttt = ffi.new("char[20]",v.identifier or "")
                    --if ig.InputText("##"..tostring(v.cp), ttt, 20,bit.bor(ig.lib.ImGuiInputTextFlags_CharsNoBlank, ig.lib.ImGuiInputTextFlags_EnterReturnsTrue, ig.lib.ImGuiInputTextFlags_CallbackCompletion),ITcb) then
					if ig.InputText("##"..tostring(v.cp), ttt, 20,bit.bor(ig.lib.ImGuiInputTextFlags_CharsNoBlank, ig.lib.ImGuiInputTextFlags_EnterReturnsTrue)) then
						print"inp"
						v.identifier = ffi.string(ttt)
					end
					ig.NextColumn()
				end
				ig.Columns(1)
			end
			ig.EndChildFrame()
		end
	end
	ig.End()
	
	ig.ShowDemoWindow()
end

win:start()