ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Landing Beacon"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetupDataTables()
    self:NetworkVar("Vector", 0, "BeaconColor")   -- Vector(R,G,B)
    self:NetworkVar("Float",  0, "DieTime")       -- absolute CurTime() when it should die
    self:NetworkVar("Vector", 1, "CeilingPos")    -- rope end
    self:NetworkVar("Bool",   0, "Active")        -- becomes true when E-used
end
