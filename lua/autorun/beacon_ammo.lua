-- Define custom ammo type for Landing Beacons
game.AddAmmoType({
    name = "beacon_ammo",
    dmgtype = DMG_GENERIC
})

if CLIENT then
    language.Add("beacon_ammo_ammo", "Beacon Charges")
end
