include("shared.lua")

local spriteMat = Material("sprites/light_glow02_add")

function ENT:Initialize()
    self._dlID = self:EntIndex()
    self._nextDL = 0
end

function ENT:Draw()
    self:DrawModel()

    -- Only show glow when active
    if not self:GetActive() then return end

    local colVec = self:GetBeaconColor()
    local col = Color(colVec.x or 0, colVec.y or 180, colVec.z or 255, 255)

    local pos = self:GetPos() + self:GetUp() * 6
    render.SetMaterial(spriteMat)
    render.DrawSprite(pos, 64, 64, col)
end

function ENT:Think()
    if not self:GetActive() then return end
    if self._nextDL > CurTime() then return end
    self._nextDL = CurTime() + 0.05

    local dl = DynamicLight(self._dlID)
    if dl then
        local colVec = self:GetBeaconColor()
        dl.pos = self:GetPos() + self:GetUp() * 8
        dl.r = math.Clamp(colVec.x or 0, 0, 255)
        dl.g = math.Clamp(colVec.y or 180, 0, 255)
        dl.b = math.Clamp(colVec.z or 255, 0, 255)
        dl.brightness = math.Clamp(GetConVar("beacon_light_brightness"):GetFloat(), 1, 5)
        dl.Decay = 1000
        dl.Size = math.max(200, GetConVar("beacon_light_distance"):GetInt())
        dl.DieTime = CurTime() + 0.1
    end
end
