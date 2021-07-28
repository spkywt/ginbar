--[[
* Ashita - Copyright (c) 2014 - 2016 atom0s [atom0s@live.com]
*
* This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
* To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/ or send a letter to
* Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
*
* By using Ashita, you agree to the above license and its terms.
*
*      Attribution - You must give appropriate credit, provide a link to the license and indicate if changes were
*                    made. You must do so in any reasonable manner, but not in any way that suggests the licensor
*                    endorses you or your use.
*
*   Non-Commercial - You may not use the material (Ashita) for commercial purposes.
*
*   No-Derivatives - If you remix, transform, or build upon the material (Ashita), you may not distribute the
*                    modified material. You are, however, allowed to submit the modified works back to the original
*                    Ashita project in attempt to have it added to the original project.
*
* You may not apply legal terms or technological measures that legally restrict others
* from doing anything the license permits.
*
* No warranties are given.
]]--

_addon.author   = 'spkywt';
_addon.name     = 'ginbar';
_addon.version  = '1.0.0';

-- Ashita Libs
require 'common'
require 'd3d8'

-- Addon Files
require 'helpers'

----------------------------------------------------------------------------------------------------
-- Config -- Only edit this section unless you know what you are doing.
----------------------------------------------------------------------------------------------------
local ShowGil						=	true;
local ShowInv						=	true;

-- Container display order
local ContainerList					=	{0, 5, 6, 7, 8, 10, 11, 12, 1, 9, 2, 4, 3};
	--[[
		Inventory = 0,
		Safe = 1,
		Storage = 2,
		Temporary = 3,
		Locker = 4,
		Satchel = 5,
		Sack = 6,
		Case = 7,
		Wardrobe = 8,
		Safe2 = 9,
		Wardrobe2 = 10,
		Wardrobe3 = 11,
		Wardrobe4 = 12,
	]]--

----------------------------------------------------------------------------------------------------
-- Theme
----------------------------------------------------------------------------------------------------
local colors = imgui.style.Colors;
colors[ImGuiCol_Button] 		=	ImVec4(0.0, 0.6, 0.9, 0.5);
colors[ImGuiCol_ButtonHovered]	=	ImVec4(0.0, 0.6, 0.9, 1.0);
colors[ImGuiCol_ButtonActive]	=	ImVec4(1.0, 1.0, 1.0, 0.3);
colors[ImGuiCol_Header]			=	ImVec4(0.0, 0.6, 0.9, 0.5);
colors[ImGuiCol_HeaderHovered]	=	ImVec4(0.0, 0.6, 0.9, 1.0);
colors[ImGuiCol_HeaderActive]	=	ImVec4(0.0, 0.6, 0.9, 0.5);
colors[ImGuiCol_Text]			=	ImVec4(1.0, 1.0, 1.0, 1.0);
colors[ImGuiCol_TitleBgActive]	=	colors[ImGuiCol_TitleBg];
imgui.style.Colors = colors;

local s = imgui.style;
s.Alpha = 1.1;
s.ChildWindowRounding = 4;
s.FrameRounding = 3;
s.WindowRounding = 7;
s.AntiAliasedLines = true;
s.AntiAliasedShapes = true;

----------------------------------------------------------------------------------------------------
-- Vars (required by other lua files)
----------------------------------------------------------------------------------------------------
local player					=	AshitaCore:GetDataManager():GetPlayer();
local inventory					=	AshitaCore:GetDataManager():GetInventory();
local resource					=	AshitaCore:GetResourceManager();
local ContainersInverted		=	table_invert(Containers);
local BMWidth_Gil				=	0;
local BMWidth_Storage			=	0;
local variables					=
{
	['var_ShowBottomMenu']		=	{ nil, ImGuiVar_BOOLCPP, true },
	['var_ShowBottomMenu_Gil']	=	{ nil, ImGuiVar_BOOLCPP, ShowGil },
	['var_ShowBottomMenu_Inv']	=	{ nil, ImGuiVar_BOOLCPP, ShowInv }
};

----------------------------------------------------------------------------------------------------
-- Create Textures from Images
----------------------------------------------------------------------------------------------------
local hres, imgGilIcon = ashita.d3dx.CreateTextureFromFileA(_addon.path .. '\\images\\65535.png');
if (hres ~= 0) then print('Error loading file.'); end
local hres, imgInvIcon = ashita.d3dx.CreateTextureFromFileA(_addon.path .. '\\images\\sack.png');
if (hres ~= 0) then print('Error loading file.'); end

----------------------------------------------------------------------------------------------------
-- func: GetContainerName
-- desc: Return container names with proper spacing.
----------------------------------------------------------------------------------------------------
function GetContainerName(cID)
	local cName = ContainersInverted[cID];
	cName = cName:gsub("%u", function(c) return ' ' .. c; end):sub(2);
	cName = cName:gsub("%d", function(d) return ' ' .. d; end);
	cName = cName:gsub("Safe", 'Mog Safe');
	return cName or '';
end

----------------------------------------------------------------------------------------------------
-- func: GetContainerSize
-- desc: Return count of items in container as well as table of item types.
----------------------------------------------------------------------------------------------------
local function GetContainerSize(cID)
    local size = 0;
	local types = {};
	for i = 0, inventory:GetContainerMax(cID), 1 do
		local item = inventory:GetItem(cID, i);
		if (item.Id ~= 0 and item.Id ~= 65535) then
			local item = resource:GetItemById(item.Id);
			if item then
				size = size + 1;
				if (not types[item.ItemType]) then types[item.ItemType] = true; end
			end
		end
	end
    return size, types;
end

----------------------------------------------------------------------------------------------------
-- func: UpdateContainerInfo
-- desc: Update config table with current container info.
----------------------------------------------------------------------------------------------------
local ContainerInfo = {};
local function SetContainerInfo()
	if (table.getn(ContainerInfo) == 0) then
		for i = 1, table.getn(ContainerList), 1 do
			local cID = ContainerList[i];
			ContainerInfo[cID] = {};
			ContainerInfo[cID].name = GetContainerName(cID);
			if (inventory:GetContainerMax(cID) == 0) then
				ContainerInfo[cID].max = 0;
			else
				ContainerInfo[cID].max = inventory:GetContainerMax(cID) - 1;
			end
			local types = {};
			ContainerInfo[cID].size, types = GetContainerSize(cID);
			ContainerInfo[cID].types = {};
			for k,v in pairs(ItemType) do if (types[v]) then ContainerInfo[cID].types[k] = v; end end
			ContainerInfo.Gil = inventory:GetItem(0,0).Count;
		end
	else
		for i = 1, table.getn(ContainerList), 1 do
			local cID = ContainerList[i];
			if (inventory:GetContainerMax(cID) ~= 0) then
				ContainerInfo[cID].max = inventory:GetContainerMax(cID) - 1;
			end
			local types = {};
			ContainerInfo[cID].size, types = GetContainerSize(cID);
			ContainerInfo[cID].types = {};
			for k,v in pairs(ItemType) do if (types[v]) then ContainerInfo[cID].types[k] = v; end end
			ContainerInfo.Gil = inventory:GetItem(0,0).Count;
		end
	end
end

----------------------------------------------------------------------------------------------------
-- func: StorageCurrentAndMax
-- desc: Return formatted string of used and max storage for a container.
----------------------------------------------------------------------------------------------------
local function StorageCurrentAndMax(cID)
	if (ContainerInfo[cID].max == 0) then
		return '--/--';
	else
		return string.format("%5s", ContainerInfo[cID].size .. '/' .. ContainerInfo[cID].max);
	end
end

----------------------------------------------------------------------------------------------------
-- func: ContainerButton
-- desc: Create button for containers.
----------------------------------------------------------------------------------------------------
local function ContainerButton(cID, cLabel)
	if (inventory:GetContainerMax(cID) > 0) then
		if     (cID == 2 and ContainerInfo[cID].size == 0) then
		elseif (cID == 3 and ContainerInfo[cID].size == 0) then
		elseif (cID == 9 and ContainerInfo[cID].size == 0) then
		else
			if (cID ~= 0) then
				imgui.SameLine();
				imgui.TextColored(1, 1, 1, 0.25,'::');
			end
			imgui.SameLine();
			imgui.Text(string.format('%-12s', cLabel) .. StorageCurrentAndMax(cID));
		end
	end
end

----------------------------------------------------------------------------------------------------
-- func: ShowBottomBar
-- desc: Shows storage summary window.
----------------------------------------------------------------------------------------------------
local function ShowBottomMenu()
	local xChest		=	0;
	local xGil			=	0;
	local Window_Flags	=	ImGuiWindowFlags_NoTitleBar + ImGuiWindowFlags_NoResize +
							ImGuiWindowFlags_NoFocusOnAppearing + ImGuiWindowFlags_NoMove +
							ImGuiWindowFlags_NoBringToFrontOnFocus +
							ImGuiWindowFlags_NoScrollbar + ImGuiWindowFlags_NoScrollWithMouse +
							ImGuiWindowFlags_ShowBorders + ImGuiWindowFlags_NoSavedSettings;
							
	-- Initialize the window draw.
	imgui.PushStyleVar(ImGuiStyleVar_WindowRounding, 0);
	imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, 0, 2);
	imgui.PushStyleVar(ImGuiStyleVar_ChildWindowRounding, 0);
	imgui.PushStyleColor(ImGuiCol_WindowBg, 0.15, 0.15, 0.15, 0.85);
	imgui.SetNextWindowSize(imgui.io.DisplaySize.x, 20, ImGuiSetCond_Always);
	imgui.SetNextWindowPos(0, imgui.io.DisplaySize.y - 17);
	if (imgui.Begin('BottomBar', variables['var_ShowBottomMenu'][1], Window_Flags)) then
		-- Spacing
		if (BMWidth_Gil ~= 0 and BMWidth_Storage ~= 0) then
			imgui.SameLine((imgui.GetWindowWidth() - BMWidth_Storage) / 2);
		elseif (BMWidth_Gil ~= 0 or BMWidth_Storage ~= 0) then
			imgui.SameLine((imgui.GetWindowWidth() - BMWidth_Storage - BMWidth_Gil) / 2);
		end
		-- Gil
		if (imgui.GetVarValue(variables['var_ShowBottomMenu_Gil'][1])) then
			xGil = imgui.GetCursorPos();
			imgui.Text('     ');
			imgui.SameLine();
			imgui.Text(comma_value(ContainerInfo.Gil) ..  '    ');
			imgui.SameLine();
			if (BMWidth_Gil == 0) then BMWidth_Gil = imgui.GetCursorScreenPos(); end
		end
		-- Storage
		if (imgui.GetVarValue(variables['var_ShowBottomMenu_Inv'][1])) then
			xChest = imgui.GetCursorPos();
			imgui.Text('     ');
			imgui.PushStyleColor(ImGuiCol_Button, ImVec4(1, 1, 1, 0.4));
			imgui.PushStyleColor(ImGuiCol_Border, ImVec4(1, 1, 1, 0));
			for i = 1, table.getn(ContainerList), 1 do
				local cid = ContainerList[i];
				ContainerButton(cid, GetContainerName(cid));
			end
			imgui.PopStyleColor(2);
			imgui.SameLine();
			if (BMWidth_Storage == 0) then BMWidth_Storage = imgui.GetCursorScreenPos(); end
		end
    end
	imgui.End();
	imgui.PopStyleColor(1);
	imgui.PopStyleVar();
	imgui.PopStyleVar();
	imgui.PopStyleVar();
	
	local Window_Flags	=	ImGuiWindowFlags_NoTitleBar + ImGuiWindowFlags_NoResize +
							ImGuiWindowFlags_NoMove + ImGuiWindowFlags_NoScrollbar +
							ImGuiWindowFlags_NoScrollWithMouse + ImGuiWindowFlags_NoSavedSettings;
	imgui.PushStyleColor(ImGuiCol_WindowBg, 0, 0, 0, 0);
	if (imgui.GetVarValue(variables['var_ShowBottomMenu_Inv'][1])) then
		if (BMWidth_Storage ~= 0) then
			imgui.SetNextWindowSize(60, 60, ImGuiSetCond_Always);
			imgui.SetNextWindowPos(xChest, imgui.io.DisplaySize.y - 28);
			if (imgui.Begin('imgInvIcon', variables['var_ShowBottomMenu_Inv'][1], Window_Flags)) then
				imgui.Image(imgInvIcon:Get(), 32, 32);
			end
			imgui.End();
		end
	end
	if (imgui.GetVarValue(variables['var_ShowBottomMenu_Gil'][1])) then
		if (BMWidth_Gil ~= 0) then
			imgui.SetNextWindowSize(60, 60, ImGuiSetCond_Always);
			imgui.SetNextWindowPos(xGil - 2, imgui.io.DisplaySize.y - 26);
			if (imgui.Begin('imgGilIcon', variables['var_ShowBottomMenu_Gil'][1], Window_Flags)) then
				imgui.Image(imgGilIcon:Get(), 32, 32);
			end
			imgui.End();
		end
	end
	imgui.PopStyleColor(1);
end

----------------------------------------------------------------------------------------------------
-- func: load
-- desc: Event called when the addon is being loaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
	-- Initialize the custom variables..
    for k, v in pairs(variables) do
        if (v[2] >= ImGuiVar_CDSTRING) then 
            variables[k][1] = imgui.CreateVar(variables[k][2], variables[k][3]);
        else
            variables[k][1] = imgui.CreateVar(variables[k][2]);
        end
        if (#v > 2 and v[2] < ImGuiVar_CDSTRING) then
            imgui.SetVarValue(variables[k][1], variables[k][3]);
        end        
    end
end);

----------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Called when the addon is unloaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
    -- Cleanup the custom variables..
    for k, v in pairs(variables) do
        if (variables[k][1] ~= nil) then
            imgui.DeleteVar(variables[k][1]);
        end
        variables[k][1] = nil;
    end
	
	if (imgGilIcon ~= nil ) then imgGilIcon:Release(); end
	if (imgInvIcon ~= nil ) then imgInvIcon:Release(); end
end);

----------------------------------------------------------------------------------------------------
-- func: command
-- desc: Event called when a command was entered.
----------------------------------------------------------------------------------------------------
ashita.register_event('command', function(command, ntype)
    -- Get the arguments of the command..
    local args = command:args();
	local echomsg;
	
	-- UI commands
	if (args[1] == '/ginbar' or args[1] == '/gin') then
		if (args[2] == 'toggle') then
			if (args[3] == 'bar') then
				imgui.SetVarValue(variables['var_ShowBottomMenu'][1], not imgui.GetVarValue(variables['var_ShowBottomMenu'][1]));
				BMWidth_Storage = 0;
				BMWidth_Gil = 0;
			elseif (args[3] == 'gil') then
				imgui.SetVarValue(variables['var_ShowBottomMenu_Gil'][1], not imgui.GetVarValue(variables['var_ShowBottomMenu_Gil'][1]));
				BMWidth_Storage = 0;
				BMWidth_Gil = 0;
			elseif (args[3] == 'inventory' or args[3] == 'inv') then
				imgui.SetVarValue(variables['var_ShowBottomMenu_Inv'][1], not imgui.GetVarValue(variables['var_ShowBottomMenu_Inv'][1]));
				BMWidth_Storage = 0;
				BMWidth_Gil = 0;
			else
				echo('toggle commands: bar, gil, inv or inventory');
			end
		elseif (args[2] == 'reload') then
			AshitaCore:GetChatManager():QueueCommand(string.format('/addon reload %s', _addon.name), 1);
		elseif (args[2] == 'unload') then
			AshitaCore:GetChatManager():QueueCommand(string.format('/addon unload %s', _addon.name), 1);
		elseif (args[2] == 'test') then
			echo('No test commands.');
		else
			echo('commands: toggle, reload, unload');
		end
	end
	
    return false;
end);
		
----------------------------------------------------------------------------------------------------
-- func: render
-- desc: Called when the addon is rendering.
----------------------------------------------------------------------------------------------------
ashita.register_event('render', function()
	if (player:GetMainJobLevel() ~= 0) then
		if (imgui.GetVarValue(variables['var_ShowBottomMenu' ][1])) then
			if (inventory:GetContainerMax(0) ~= 0) then
				if (table.getn(ContainerInfo) == 0) then SetContainerInfo(); end
				ShowBottomMenu();
			end
		end
	end
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, packet)
	if (id == 0x01D or id == 0x01E or id == 0x01F or id == 0x020) then
		SetContainerInfo();
	end
	
	return false;
end);
