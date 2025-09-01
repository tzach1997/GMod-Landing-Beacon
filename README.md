# Landing Beacon (GMod)

A throwable beacon you **stick to a surface**. A player presses **E** on it to **activate**; it lights up, spawns a **red laser rope** up to the ceiling (or a sky-height fallback), and **auto-removes** after a configurable time. The **server controls the model** and (optionally) skin indices for idle/active states.

---

## 📦 Installation

1. Put the folder in:
   ```
   garrysmod/addons/landing_beacon
   ```
2. Restart your server (or `lua_reloadents` + `lua_openscript_cl` if you know what you’re doing).

---

## 🕹️ How to Use (in-game)

- Give yourself the SWEP: **Landing Beacon** (category: *Tools*).
- **Primary fire**: throw a beacon (10s built-in cooldown).
- The beacon **sticks** where it lands and waits.
- Walk up and press **E** on it → it **activates** (light + red rope).
- After the configured time, it **despawns** and cleans up the rope.

> Note: If you changed the world model via ConVar, new spawns / re-equips will use it.

---

## ⚙️ Server Configuration

### ConVars

| ConVar | Default | Type | What it does |
|---|---:|:---:|---|
| `beacon_time` | `45` | number (sec) | Lifetime **after activation**. When time is up, the beacon auto-removes. Min 5, max 600. |
| `beacon_color` | `"0 180 255"` | string `"R G B"` | Color of the dynamic light/glow on the beacon when active. Each 0–255. |
| `beacon_light_distance` | `600` | number | Dynamic-light radius (visual brightness falloff). |
| `beacon_light_brightness` | `3` | number (1–5) | Dynamic-light brightness multiplier. |
| `beacon_rope` | `1` | bool (0/1) | Draw the **rope** upward when activated. (Uses `cable/redlaser` material.) |
| `beacon_rope_width` | `10` | number (1–16) | Visual thickness of the rope/laser. |
| `beacon_rope_fallback_height` | `1200` | number (units) | If no ceiling is detected (e.g., open sky), place the rope end this far above the beacon. |
| `beacon_model` | `"models/props_combine/combine_mine01.mdl"` | string (model path) | **Server-chosen** model for both the beacon **entity** and the **SWEP worldmodel**. Must be a valid model path. |
| `beacon_skin_idle` | `0` | integer | Skin index to use while **idle** (before E-press). |
| `beacon_skin_active` | `1` | integer | Skin index to use when **active** (after E-press). |

**Notes**
- The rope uses **`cable/redlaser`** and looks best with widths **8–12**.
- The addon **pre-caches** `beacon_model` on server start/change if valid.

### Quick examples

```cfg
// Longer visibility + warmer color
beacon_time 90
beacon_color "255 120 80"
beacon_light_distance 900
beacon_light_brightness 5

// Make the rope more prominent (and always visible outdoors)
beacon_rope 1
beacon_rope_width 12
beacon_rope_fallback_height 1800

// Use your custom compiled model + skins
beacon_model "models/beacon/landing_beacon.mdl"
beacon_skin_idle 0
beacon_skin_active 1
```

---

## 🔧 Admin Tips

- You can change ConVars **live** in server console; new beacons will obey immediately.
- If you change `beacon_model`, players may need to re-equip the SWEP to update the world model they’re holding (entity beacons spawned afterward will already use the new model).
- Model must be valid (`util.IsValidModel`). If invalid, the code falls back to `combine_mine01`.

---

## 🗂️ File Layout

```
lua/
  autorun/
    beacon_convars.lua        // the ConVars listed above
  weapons/
    weapon_beacon.lua         // throwable SWEP (10s cooldown)
  entities/
    ent_beacon/
      shared.lua              // network vars
      init.lua                // server: stick, E-to-activate, rope, cleanup
      cl_init.lua             // client: glow + dynamic light when active
```

---

## ❓ FAQ / Troubleshooting

**No rope shows up outdoors.**  
Increase `beacon_rope_fallback_height` (e.g., `1800`–`2400`). The system uses a ceiling trace; if it hits sky, it anchors at fallback height.

**Rope looks too thin or faint.**  
Bump `beacon_rope_width` to `12` or `14`. It uses `cable/redlaser`, which looks best slightly thicker.

**Beacon doesn’t glow brightly enough.**  
Raise `beacon_light_brightness` (max `5`) and/or `beacon_light_distance`.

**Model didn’t change when I set `beacon_model`.**  
Make sure the path is correct and valid. Re-equip the SWEP for the held model; spawned entities already use the new model.
