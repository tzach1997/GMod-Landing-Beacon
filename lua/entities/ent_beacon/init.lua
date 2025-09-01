AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- ========= helpers =========

local function parseColorCVar()
    local s = GetConVar("beacon_color"):GetString() or "0 180 255"
    local r,g,b = s:match("(%d+)%s+(%d+)%s+(%d+)")
    r, g, b = tonumber(r or 0), tonumber(g or 180), tonumber(b or 255)
    return Vector(math.Clamp(r,0,255), math.Clamp(g,0,255), math.Clamp(b,0,255))
end

local function makeAnchorAt(pos)
    local anchor = ents.Create("prop_physics")
    if not IsValid(anchor) then return nil end
    anchor:SetModel("models/hunter/blocks/cube025x025x025.mdl")
    anchor:SetPos(pos)
    anchor:Spawn()
    anchor:SetNoDraw(true)
    anchor:SetNotSolid(true)
    local phys = anchor:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    return anchor
end

local function ceilingOrFallback(self)
    local startPos = self:GetPos()
    local tr = util.TraceLine({
        start  = startPos,
        endpos = startPos + Vector(0,0,8192),
        mask   = MASK_SOLID,
        filter = self
    })
    if tr.Hit and not tr.HitSky then
        return tr.HitPos
    end
    local h = math.Clamp(GetConVar("beacon_rope_fallback_height"):GetInt(), 128, 8192)
    local target = startPos + Vector(0,0,h)
    local trDown = util.TraceLine({
        start  = target,
        endpos = target - Vector(0,0,32),
        mask   = MASK_ALL,
        filter = self
    })
    return trDown.Hit and (trDown.HitPos + Vector(0,0,-2)) or target
end

local function buildRopeOn(self)
    if not GetConVar("beacon_rope"):GetBool() then
        self:SetCeilingPos(vector_origin)
        return
    end

    local endPos = ceilingOrFallback(self)
    self:SetCeilingPos(endPos)

    if IsValid(self.Anchor) then self.Anchor:Remove() end
    self.Anchor = makeAnchorAt(endPos)
    if not IsValid(self.Anchor) then return end

    local startName = "beacon_" .. self:EntIndex()
    local endName   = "beacon_anchor_" .. self:EntIndex()
    self:SetName(startName)
    self.Anchor:SetName(endName)

    local len   = self:GetPos():Distance(endPos)
    local width = math.Clamp(GetConVar("beacon_rope_width"):GetInt(), 1, 16)

    -- Physics rope (harmless if invisible due to movetype)
    if IsValid(self.Rope) then self.Rope:Remove() end
    self.Rope = constraint.Rope(
        self, self.Anchor,
        0, 0,
        vector_origin, vector_origin,
        len, 0, 0, width, "cable/redlaser", false
    )

    -- Visual rope (always visible)
    if IsValid(self.KeyframeRope) then self.KeyframeRope:Remove() end
    local kr = ents.Create("keyframe_rope")
    if not IsValid(kr) then return end
    kr:SetPos(self:GetPos())
    kr:SetKeyValue("Width", tostring(width))
    kr:SetKeyValue("Slack", "0")
    kr:SetKeyValue("Type", "0")
    kr:SetKeyValue("Subdiv", "2")
    kr:SetMaterial("cable/redlaser")
    kr:SetKeyValue("StartEntityName", startName)
    kr:SetKeyValue("EndEntityName",   endName)
    kr:Spawn()
    kr:Activate()
    kr:Fire("SetStartEntity", startName, 0)
    kr:Fire("SetEndEntity",   endName,   0)
    kr:Fire("TurnOn", "", 0)
    kr:SetParent(self)
    self.KeyframeRope = kr
end

-- ========= entity =========

function ENT:Initialize()
    -- Server-chosen model
    local mdl = GetConVar("beacon_model"):GetString()
    if not util.IsValidModel(mdl) then
        mdl = "models/props_combine/combine_mine01.mdl"
    end
    self:SetModel(mdl)
    if util.IsValidModel(mdl) then util.PrecacheModel(mdl) end

    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end

    self:SetBeaconColor(parseColorCVar())
    self:SetActive(false)
    self:SetDieTime(0)

    -- Skin control (server decides indices)
    self:SetSkin(math.max(0, GetConVar("beacon_skin_idle"):GetInt()))

    self.Sticky = true
    self._armed = false
    self.Anchor = nil
    self.Rope = nil
    self.KeyframeRope = nil
end

-- Stick hard on first decent impact; do NOT activate yet
function ENT:PhysicsCollide(data, phys)
    if not self.Sticky then return end
    if data.Speed <= 30 then return end

    -- Uncomment to force ground-only:
    -- if data.HitNormal.z < 0.6 then return end

    timer.Simple(0, function()
        if not IsValid(self) or not IsValid(phys) then return end

        local snapPos = data.HitPos + data.HitNormal * 1.5
        self:SetPos(snapPos)

        phys:EnableMotion(false)
        self:SetMoveType(MOVETYPE_NONE)

        local ang = data.HitNormal:Angle()
        ang:RotateAroundAxis(ang:Right(), 90)
        self:SetAngles(ang)

        self.Sticky = false
        self._armed = true
        self:EmitSound("buttons/button3.wav", 60, 100)
    end)
end

-- Press E to activate: light on, rope up, life timer starts
function ENT:Use(activator, caller)
    if not self._armed then return end
    if self:GetActive() then return end

    self:SetActive(true)
    self:SetSkin(math.max(0, GetConVar("beacon_skin_active"):GetInt()))

    local lifetime = math.max(5, GetConVar("beacon_time"):GetFloat())
    self:SetDieTime(CurTime() + lifetime)

    buildRopeOn(self)

    self:EmitSound("buttons/button14.wav", 65, 100)
end

function ENT:Think()
    if self:GetActive() and CurTime() >= self:GetDieTime() then
        self:Remove()
        return
    end
    self:NextThink(CurTime() + 0.1)
    return true
end

function ENT:OnRemove()
    if self:GetActive() then
        self:EmitSound("buttons/button19.wav", 60, 120)
    end
    if IsValid(self.KeyframeRope) then self.KeyframeRope:Remove() end
    if IsValid(self.Rope) then self.Rope:Remove() end
    if IsValid(self.Anchor) then self.Anchor:Remove() end
end
