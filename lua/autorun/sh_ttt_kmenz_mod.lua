if SERVER then
    AddCSLuaFile()
end

local HOOK_ID = "TTTKMENZMOD"

local function RegisterPostGameMode()
    print("[TTTKMENZMOD] sh_kmenz_mod.lua loaded", SERVER, CLIENT)

    EQUIP_TRAITOR_BYPASS = GenerateNewEquipmentID()
    local TraitorBypass = {
        id = EQUIP_TRAITOR_BYPASS,
        loadout = false,
        type = "item_passive",
        material = "vgui/ttt/icon_armor",
        name = "Traitor Bypass",
        desc = "Bypass the traitor pass once. Buy before use.",
        hud = true
    }

    table.insert(EquipmentItems[ROLE_TRAITOR], TraitorBypass)

    local NET_MSG_BYPASS_TRAITOR_ACTIVATED = "TTTKMENZMODBypassTraitorActivated"

    local function _HookServerTTTOrderedEquipment (ply, id, is_item)
        if id ~= EQUIP_TRAITOR_BYPASS then return end

        ply.ttt_kmenz_mod_bypass_traitor = true

        net.Start(NET_MSG_BYPASS_TRAITOR_ACTIVATED)
        net.Send(ply)
    end

    local function _HookServerTTTPrepareRound()
        for _, ply in ipairs(player.GetAll()) do
            ply.ttt_kmenz_mod_bypass_traitor = nil
        end
    end

    local function _NetClientRecvBypassTraitorActivated (len, ply)
        chat.AddText(
            Color(255, 255, 255), "You activated the ",
            Color(255, 0, 0), "traitor",
            Color(255, 255, 255), " test bypass. Your next text will be ",
            Color(100, 255, 100), "green",
            Color(255, 255, 255), "."
        )
        chat.PlaySound()
    end

    if SERVER then
        util.AddNetworkString(NET_MSG_BYPASS_TRAITOR_ACTIVATED)

        hook.Add("TTTPrepareRound", HOOK_ID .. "PrepareRound", _HookServerTTTPrepareRound)
        hook.Add("TTTOrderedEquipment", HOOK_ID .. "OrderedEquipment", _HookServerTTTOrderedEquipment)
    end

    if CLIENT then
        net.Receive(NET_MSG_BYPASS_TRAITOR_ACTIVATED, _NetClientRecvBypassTraitorActivated)
    end
end

local 

hook.Add("RegisterPostGameMode", HOOK_ID .. "Register", RegisterMutterGladbach)
