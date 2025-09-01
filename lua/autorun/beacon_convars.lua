-- Landing Beacon: ConVars

-- Lifetime & visuals
CreateConVar("beacon_time", "45", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Beacon lifetime (seconds)", 5, 600)
CreateConVar("beacon_color", "0 180 255", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Beacon light color as 'R G B'")
CreateConVar("beacon_light_distance", "600", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Dynamic light radius")
CreateConVar("beacon_light_brightness", "3", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Dynamic light brightness (1-5)")

-- Rope (red laser look)
CreateConVar("beacon_rope", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Draw rope to ceiling on activation (1=yes, 0=no)")
CreateConVar("beacon_rope_width", "10", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Rope thickness (1-16)", 1, 16)
CreateConVar("beacon_rope_fallback_height", "1200", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Fallback rope height if no ceiling (units)")

-- MODEL SELECTION (server decides)
-- Default to Valve prop; server can point this to e.g. models/beacon/landing_beacon.mdl
CreateConVar("beacon_model", "models/props_combine/combine_mine01.mdl", FCVAR_ARCHIVE + FCVAR_REPLICATED, "World model for the beacon entity & SWEP worldmodel")

-- Optional skin indices (useful if your model has 2 skins: 0=idle,1=active)
CreateConVar("beacon_skin_idle",   "0", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Skin index when idle")
CreateConVar("beacon_skin_active", "1", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Skin index when active")

-- Precache the model on servers so the first spawn doesn’t hitch
if SERVER then
  cvars.AddChangeCallback("beacon_model", function(_, __, new)
    if util.IsValidModel(new) then util.PrecacheModel(new) end
  end, "beacon_model_precache")
  local mdl = GetConVar("beacon_model"):GetString()
  if util.IsValidModel(mdl) then util.PrecacheModel(mdl) end
end
