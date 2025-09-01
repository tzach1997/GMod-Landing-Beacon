if SERVER then AddCSLuaFile() end

SWEP.PrintName = "Landing Beacon"
SWEP.Author = "YourName"
SWEP.Instructions = "Primary Fire: Throw beacon (10s cooldown). Press E on it to activate."
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Category = "Tools"

SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_arms.mdl"

-- WorldModel is overridden by server ConVar (fallback shown here)
SWEP.WorldModel = "models/props_junk/TrafficCone001a.mdl"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 3      -- start with 3 charges by default
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "beacon_ammo" -- custom ammo type

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.DrawAmmo = true              -- show ammo in HUD

local THROW_FORCE = 900
local COOLDOWN = 10 -- seconds between throws

function SWEP:Initialize()
    self:SetHoldType("normal")
    self._nextThrow = 0

    if SERVER then
        local mdl = GetConVar("beacon_model"):GetString()
        if util.IsValidModel(mdl) then
            self.WorldModel = mdl
            util.PrecacheModel(mdl)
        end
    end
end

function SWEP:CanPrimaryAttack()
    if self:Ammo1() <= 0 then
        if SERVER and IsValid(self.Owner) then
            self.Owner:ChatPrint("[Beacon] Out of charges!")
        end
        self:EmitSound("buttons/button10.wav", 60, 100)
        return false
    end
    return CurTime() >= (self._nextThrow or 0)
end

local function tellCooldown(ply, secs)
    if not IsValid(ply) then return end
    ply:EmitSound("buttons/button10.wav", 55, 100)
    if SERVER then
        ply:ChatPrint(("[Beacon] Cooldown: %.1fs"):format(secs))
    end
end

function SWEP:PrimaryAttack()
    if not IsValid(self.Owner) then return end
    if not self:CanPrimaryAttack() then
        local left = (self._nextThrow or 0) - CurTime()
        if left > 0 then tellCooldown(self.Owner, left) end
        self:SetNextPrimaryFire(CurTime() + 0.2)
        return
    end

    self:SetNextPrimaryFire(CurTime() + COOLDOWN)
    self._nextThrow = CurTime() + COOLDOWN

    if SERVER then
        local ent = ents.Create("ent_beacon")
        if not IsValid(ent) then return end

        local ang = self.Owner:EyeAngles()
        local srcPos = self.Owner:EyePos() + ang:Forward() * 16 + ang:Right() * 8
        ent:SetPos(srcPos)
        ent:SetAngles(Angle(0, ang.y, 0))
        ent:SetOwner(self.Owner)
        ent:Spawn()

        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetVelocity(ang:Forward() * THROW_FORCE + self.Owner:GetVelocity())
            phys:AddAngleVelocity(VectorRand() * 200)
        end

        -- Consume 1 ammo
        self:TakePrimaryAmmo(1)
    end

    self.Owner:EmitSound("weapons/slam/throw.wav", 60, 100)
end

function SWEP:SecondaryAttack() end
function SWEP:Reload() end
