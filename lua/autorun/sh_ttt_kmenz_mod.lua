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

        local tttLogicRole = scripted_ents.GetStored("ttt_logic_role")
        if not tttLogicRole or not tttLogicRole.t then
            ErrorNoHalt("[" .. HOOK_ID .. "] Can't find ttt_logic_role.")
            return
        end

        local tttLogicEntity = tttLogicRole.t
        local oldAcceptInput = tttLogicEntity.AcceptInput
        function tttLogicEntity:AcceptInput(name, activator)
            if activator.ttt_kmenz_mod_bypass_traitor and name == "TestActivator" then
                if IsValid(activator) and activator:IsPlayer() then
                    local activator_role = (GetRoundState() == ROUND_PREP) and ROLE_INNOCENT or activator:GetRole()

                    if self.Role == ROLE_INNOCENT and activator_role == ROLE_TRAITOR then
                        Dev(2, activator, "passed logic_role test via bypass of", self:GetName())
                        activator.ttt_kmenz_mod_bypass_traitor = false
                        self:TriggerOutput("OnPass", activator)
                        return true
                    end
                end
            end
            return oldAcceptInput(self, name, activator)
        end

        hook.Add("TTTPrepareRound", HOOK_ID .. "PrepareRound", _HookServerTTTPrepareRound)
        hook.Add("TTTOrderedEquipment", HOOK_ID .. "OrderedEquipment", _HookServerTTTOrderedEquipment)
    end

    if CLIENT then
        net.Receive(NET_MSG_BYPASS_TRAITOR_ACTIVATED, _NetClientRecvBypassTraitorActivated)
    end
end

hook.Add("PostGamemodeLoaded", HOOK_ID .. "Register", RegisterPostGameMode)
