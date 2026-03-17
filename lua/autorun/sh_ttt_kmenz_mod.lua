if SERVER then
    AddCSLuaFile()
end

local HOOK_ID = "TTTKMENZMOD"
local NET_MSG_MESSAGE = HOOK_ID .."Message"
local NET_MSG_BYPASS_TRAITOR_ACTIVATED = HOOK_ID .. "BypassTraitorActivated"
local NET_MSG_BYPASS_TRAITOR_USED = HOOK_ID .. "BypassTraitorUsed"

local PLZ_LOG = false
local function log_stuff(text)
    if PLZ_LOG then
        net.Start(NET_MSG_MESSAGE)
        net.WriteString("[TTTKMENZMOD] " .. text)
        print("[TTTKMENZMOD] " .. text)
        net.Broadcast()
    end
end

local function RegisterPostGameMode()
    print("[TTTKMENZMOD] sh_kmenz_mod.lua loaded", SERVER, CLIENT)

    local role_strings = {
        [ROLE_TRAITOR]   = "traitor",
        [ROLE_INNOCENT]  = "innocent",
        [ROLE_DETECTIVE] = "detective",
        [3] = "any role"
    }

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

    local function _GetPlayerRole(ply)
        return (GetRoundState() == ROUND_PREP) and ROLE_INNOCENT or ply:GetRole()
    end

    local function _GetScriptedEnt(scripted_ent_name)
        local scripted_ent = scripted_ents.GetStored(scripted_ent_name)
        if not scripted_ent or not scripted_ent.t then
            ErrorNoHalt("[" .. HOOK_ID .. "] Can't find " .. scripted_ent_name .. ".")
            return nil
        end

        return scripted_ent.t
    end

    local function _RemoveEquipTraitorBypass(ply)
        ply.equipment_items = bit.band(ply.equipment_items, bit.bnot(EQUIP_TRAITOR_BYPASS))
        ply:SendEquipment()
    end

    local function _SendUsedTraitorBypassMsg(ply)
        net.Start(NET_MSG_BYPASS_TRAITOR_USED)
        net.Send(ply)
    end

    local function _DisableKmenzBypass(ply)
        if not IsValid(ply) then
            return
        end

        ply.kmenz_bypass_active = nil
        log_stuff("Disabled kmenz_bypass_active")
    end

    local function _EnableKmenzBypassTimer(ply)
        ply.kmenz_bypass_active = true
        timer.Simple(5, function() _DisableKmenzBypass(ply) end)
    end

    -- Gefunden auf Otto.de
    local function VectorInside(vec, mins, maxs)
        return (vec.x > mins.x and vec.x < maxs.x
                and vec.y > mins.y and vec.y < maxs.y
                and vec.z > mins.z and vec.z < maxs.z)
    end

    local function _NetClientRecvMessage(len, ply)
        chat.AddText(Color(255, 255, 255), net.ReadString())
    end

    local function _HookServerTTTOrderedEquipment(ply, id, is_item)
        if id ~= EQUIP_TRAITOR_BYPASS then return end

        net.Start(NET_MSG_BYPASS_TRAITOR_ACTIVATED)
        net.Send(ply)
    end

    local function _NetClientRecvBypassTraitorActivated(len, ply)
        chat.AddText(
            Color(255, 255, 255), "You activated the ",
            Color(255, 0, 0), "traitor",
            Color(255, 255, 255), " test bypass. Your next text will be ",
            Color(100, 255, 100), "green",
            Color(255, 255, 255), "."
        )
        chat.PlaySound()
    end

    local function _NetClientRecvBypassTraitorUsed(len, ply)
        chat.AddText(Color(255, 255, 255), "You used your traitor test bypass.")
    end

    local function _HandleTraitorBypass(ply)
        if ply:HasEquipmentItem(EQUIP_TRAITOR_BYPASS) then
            _RemoveEquipTraitorBypass(ply)
            _SendUsedTraitorBypassMsg(ply)
            _EnableKmenzBypassTimer(ply)

            return true
        elseif ply.kmenz_bypass_active then
            return true
        end

        return false
    end

    local function _TttLogicRoleInjection(name, activator, roleToTestFor)
        if not IsValid(activator) or not activator:IsPlayer() or name ~= "TestActivator" then
            return nil
        end

        local activator_role = _GetPlayerRole(activator)
        log_stuff("Player role is " .. role_strings[activator_role] .. " expected " .. role_strings[roleToTestFor])

        if activator_role ~= ROLE_TRAITOR or roleToTestFor ~= ROLE_TRAITOR and roleToTestFor ~= ROLE_INNOCENT then
            return nil
        end

        if not _HandleTraitorBypass(activator) then
            return nil
        end
        
        if roleToTestFor == ROLE_TRAITOR then
            return "OnFail"
        end

        return "OnPass"
    end

    local function _PatchTttLogicRole()
        local tttLogicRole = _GetScriptedEnt("ttt_logic_role")
        if not tttLogicRole then
            return
        end

        local oldAcceptInput = tttLogicRole.AcceptInput
        function tttLogicRole:AcceptInput(name, activator)
            local injectResult = _TttLogicRoleInjection(name, activator, self.Role)

            if injectResult then
                self:TriggerOutput(injectResult, activator)
                return true
            end

            return oldAcceptInput(self, name, activator)
        end
    end

    local function _TttTraitorCheckInjection(traitorCheckEntity, oldCountTraitors)
        local mins = traitorCheckEntity:LocalToWorld(traitorCheckEntity:OBBMins())
        local maxs = traitorCheckEntity:LocalToWorld(traitorCheckEntity:OBBMaxs())

        local plyOldActiveTraitorMap = {}

        for _, ply in player.Iterator() do
            if IsValid(ply) and VectorInside(ply:GetPos(), mins, maxs) and _HandleTraitorBypass(ply) then
                plyOldActiveTraitorMap[ply] = ply.IsActiveTraitor
                function ply:IsActiveTraitor()
                    return false
                end
            end
        end

        oldCountTraitors(traitorCheckEntity)

        for ply, oldIsActiveTraitor in ipairs(plyOldActiveTraitorMap) do
            if IsValid(ply) then
                ply.IsActiveTraitor = oldIsActiveTraitor
            end
        end
    end

    local function _PatchTttTraitorCheck()
        local tttTraitorCheck = _GetScriptedEnt("ttt_traitor_check")
        if not tttTraitorCheck then
            return
        end

        local oldCountTraitors = tttTraitorCheck.CountTraitors
        function tttTraitorCheck:CountTraitors()
            _TttTraitorCheckInjection(self, oldCountTraitors)
        end
    end

    if SERVER then
        util.AddNetworkString(NET_MSG_BYPASS_TRAITOR_ACTIVATED)
        util.AddNetworkString(NET_MSG_BYPASS_TRAITOR_USED)
        util.AddNetworkString(NET_MSG_MESSAGE)

        _PatchTttLogicRole()
        _PatchTttTraitorCheck()

        hook.Add("TTTOrderedEquipment", HOOK_ID .. "OrderedEquipment", _HookServerTTTOrderedEquipment)
    end

    if CLIENT then
        net.Receive(NET_MSG_BYPASS_TRAITOR_ACTIVATED, _NetClientRecvBypassTraitorActivated)
        net.Receive(NET_MSG_BYPASS_TRAITOR_USED, _NetClientRecvBypassTraitorUsed)
        net.Receive(NET_MSG_MESSAGE, _NetClientRecvMessage)
    end
end

hook.Add("PostGamemodeLoaded", HOOK_ID .. "Register", RegisterPostGameMode)
