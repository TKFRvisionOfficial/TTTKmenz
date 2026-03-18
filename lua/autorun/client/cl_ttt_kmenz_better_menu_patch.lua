local HOOK_ID = "TTTKMENZMOD"

local function PatchBetterMenu()
    if engine.ActiveGamemode() ~= "terrortown" then
        return
    end

    local function _ReceiveEquipment()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        ply.equipment_items = net.ReadInt(util.BitsRequired(EQUIP_MAX, true))
    end

    net.Receive("TTT_Equipment", _ReceiveEquipment)
end

hook.Add("PostGamemodeLoaded", HOOK_ID .. "PatchBetterMenu", PatchBetterMenu)
