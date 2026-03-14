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
    local NET_MSG_BYPASS_TRAITOR_USED = "TTTKMENZMODBypassTraitorUsed"

    local function VectorInside(vec, mins, maxs)
        return (vec.x > mins.x and vec.x < maxs.x
                and vec.y > mins.y and vec.y < maxs.y
                and vec.z > mins.z and vec.z < maxs.z)
    end

    local function _HookServerTTTOrderedEquipment (ply, id, is_item)
        if id ~= EQUIP_TRAITOR_BYPASS then return end

        net.Start(NET_MSG_BYPASS_TRAITOR_ACTIVATED)
        net.Send(ply)
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

    local function _NetClientRecvBypassTraitorUsed (len, ply)
        chat.AddText(Color(255, 255, 255), "You used your traitor test bypass.")
    end

    if SERVER then
        util.AddNetworkString(NET_MSG_BYPASS_TRAITOR_ACTIVATED)
        util.AddNetworkString(NET_MSG_BYPASS_TRAITOR_USED)

        local tttLogicRole = scripted_ents.GetStored("ttt_logic_role")
        if not tttLogicRole or not tttLogicRole.t then
            ErrorNoHalt("[" .. HOOK_ID .. "] Can't find ttt_logic_role.")
            return
        end

        local tttLogicEntity = tttLogicRole.t
        local oldAcceptInput = tttLogicEntity.AcceptInput
        function tttLogicEntity:AcceptInput(name, activator)
            if activator:HasEquipmentItem(EQUIP_TRAITOR_BYPASS) and name == "TestActivator" then
                if IsValid(activator) and activator:IsPlayer() then
                    local activator_role = (GetRoundState() == ROUND_PREP) and ROLE_INNOCENT or activator:GetRole()

                    if self.Role ~= ROLE_ANY and self.Role ~= activator_role then
                        Dev(2, activator, "passed logic_role test via bypass of", self:GetName())
                        activator.equipment_items = bit.band(activator.equipment_items, bit.bnot(EQUIP_TRAITOR_BYPASS))
                        activator:SendEquipment()

                        net.Start(NET_MSG_BYPASS_TRAITOR_USED)
                        net.Send(activator)

                        self:TriggerOutput("OnPass", activator)
                        return true
                    end
                end
            end
            return oldAcceptInput(self, name, activator)
        end

        local tttTraitorCheck = scripted_ents.GetStored("ttt_traitor_check")
        if not tttLogicRole or not tttLogicRole.t then
            ErrorNoHalt("[" .. HOOK_ID .. "] Can't find ttt_traitor_check.")
            return
        end

        local tttTraitorCheckEntity = tttTraitorCheck.t
        function tttTraitorCheckEntity:CountTraitors()
            local mins = self:LocalToWorld(self:OBBMins())
            local maxs = self:LocalToWorld(self:OBBMaxs())

            local trs = 0
            for _,ply in player.Iterator() do
                if IsValid(ply) and ply:IsActiveTraitor() and ply:Alive() then
                    local pos = ply:GetPos()
                    if VectorInside(pos, mins, maxs) then
                        if ply:HasEquipmentItem(EQUIP_TRAITOR_BYPASS) then
                            ply.equipment_items = bit.band(ply.equipment_items, bit.bnot(EQUIP_TRAITOR_BYPASS))
                            ply:SendEquipment()

                            net.Start(NET_MSG_BYPASS_TRAITOR_USED)
                            net.Send(ply)
                        else
                            trs = trs + 1
                        end
                    end
                end
            end

            return trs
        end


        hook.Add("TTTOrderedEquipment", HOOK_ID .. "OrderedEquipment", _HookServerTTTOrderedEquipment)
    end

    if CLIENT then
        net.Receive(NET_MSG_BYPASS_TRAITOR_ACTIVATED, _NetClientRecvBypassTraitorActivated)
        net.Receive(NET_MSG_BYPASS_TRAITOR_USED, _NetClientRecvBypassTraitorUsed)
    end
end

hook.Add("PostGamemodeLoaded", HOOK_ID .. "Register", RegisterPostGameMode)
