if SERVER then
    AddCSLuaFile()
end

local HOOK_ID = "TTTKMENZMOD"
local NET_MSG_BYPASS_TRAITOR_ACTIVATED = "TTTKMENZMODBypassTraitorActivated"
local NET_MSG_BYPASS_TRAITOR_USED = "TTTKMENZMODBypassTraitorUsed"
local NET_MSG_MESSAGE = "TTTKMENZMODMessage"
local ITEM_CLASS_NAME = "item_ttt_kmenz_traitor_bypass"

ITEM.material = "vgui/ttt/icon_armor"
ITEM.EquipMenuData = {
    type = "item_passive",
    name = "Traitor Bypass",
    desc = "Bypass the traitor pass once. Buy before use."
}
ITEM.corpseDesc = "Mfs have been cheating the test"
ITEM.CanBuy = {ROLE_TRAITOR}
ITEM.oldId = EQUIP_TRAITOR_BYPASS

ITEM.limited = false
ITEM.globalLimited = false
ITEM.teamLimited = false

local function TableToString(tbl)
    if not istable(tbl) then
        return "<not a table>"
    end

    local parts = {}

    for k, v in pairs(tbl) do
        parts[#parts + 1] = tostring(k) .. "=" .. tostring(v)
    end

    return "{ " .. table.concat(parts, ", ") .. " }"
end


local function log_stuff(ply, text)
    net.Start(NET_MSG_MESSAGE)
    net.WriteString("[TTTKMENZMOD]" .. text)
    net.Send(ply)
end

local function _HookServerTTT2ModifyLogicRoleCheck (ply, entity, ...)
    local plyTeam = ply:GetTeam()

    -- log_stuff(ply, tostring(ply:HasEquipmentItem(EQUIP_TRAITOR_BYPASS)) .. tostring(entity.checkingRole ~= nil) .. tostring(entity.checkingRole ~= ROLE_INNOCENT) .. tostring(util.IsEvilTeam(plyTeam)))

    -- log_stuff(ply, TableToString(ply.equipmentItems))

    -- log_stuff(ply, "Bought Items: " .. TableToString(ply.bought))

    if not ply:HasEquipmentItem(ITEM_CLASS_NAME) or entity.checkingRole ~= nil and entity.checkingRole ~= ROLE_INNOCENT or not util.IsEvilTeam(plyTeam) then
        return ply:GetBaseRole(), plyTeam
    end

    -- ply:RemoveEquipmentItem(ITEM_CLASS_NAME)
    -- ply:RemoveBought(ITEM_CLASS_NAME)
    ply:RemoveItem(ITEM_CLASS_NAME)

    --[[
    local sid64 = ply:SteamID64()
    -- log_stuff(ply, sid64)
    if sid64 and shop.buyTable[sid64] then
        log_stuff(ply, "Removed stufff")
        shop.buyTable[sid64][ITEM_CLASS_NAME] = nil
    end
    ]]

    -- log_stuff(ply, "BuyTable" .. TableToString(shop.buyTable))
    -- log_stuff(ply, TableToString(ply:GetEquipmentItems()))

    -- log_stuff(ply, tostring(ply:HasEquipmentItem(ITEM_CLASS_NAME)))

    net.Start(NET_MSG_BYPASS_TRAITOR_USED)
    net.Send(ply)

    return ROLE_INNOCENT, TEAM_INNOCENT
end

if SERVER then
    function ITEM:Bought(ply)
        net.Start(NET_MSG_BYPASS_TRAITOR_ACTIVATED)
        net.Send(ply)
    end

    hook.Add("TTT2ModifyLogicRoleCheck", HOOK_ID .. "TTT2ModifyLogicRoleCheck", _HookServerTTT2ModifyLogicRoleCheck)
end
