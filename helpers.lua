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

----------------------------------------------------------------------------------------------------
-- func: echo
-- desc: Prints out a message with the Itemwatch tag at the front.
----------------------------------------------------------------------------------------------------
function echo(msg, label)
	label = label or _addon.name;
	local txt = '\31\200[\31\05' .. label .. '\31\200] \31\130' .. msg;
    print(txt);
end

----------------------------------------------------------------------------------------------------
-- from sam_lie
-- Compatible with Lua 5.0 and 5.1.
-- Disclaimer : use at own risk especially for hedge fund reports :-)
-- add comma to separate thousands
----------------------------------------------------------------------------------------------------
function comma_value(amount)
	local formatted = amount or 0;
	while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2');
		if (k == 0) then break; end
	end
	return formatted;
end

----------------------------------------------------------------------------------------------------
-- func: table_invert
-- desc: Returns inverted table.
----------------------------------------------------------------------------------------------------
function table_invert(t)
	local t_i = {};
	for k,v in pairs(t) do
		t_i[v] = k;
	end
	return t_i;
end

----------------------------------------------------------------------------------------------------
-- func: get_container_from_index
-- desc: Get container id from item index.
----------------------------------------------------------------------------------------------------
function get_container_from_index(index)
	if     (index < 2048) then return 0;
	elseif (index < 2560) then return 8;
	elseif (index < 2816) then return 10;
	elseif (index < 3072) then return 11;
	elseif (index < 3328) then return 12;
	else                       return 0;
	end
end

----------------------------------------------------------------------------------------------------
-- func: get_item_id_from_index
-- desc: Get item id from item index.
----------------------------------------------------------------------------------------------------
function get_item_id_from_index(index)
	-- item is in inventory
	if     (index < 2048) then return inventory:GetItem(0, index).Id;
	elseif (index < 2560) then return inventory:GetItem(8, index - 2048).Id;
	elseif (index < 2816) then return inventory:GetItem(10, index - 2560).Id;
	elseif (index < 3072) then return inventory:GetItem(11, index - 2816).Id;
	elseif (index < 3328) then return inventory:GetItem(12, index - 3072).Id;
	else                       return 0;
	end
end