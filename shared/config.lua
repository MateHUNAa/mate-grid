Config = {
     lan = "en",
     PedRenderDistance = 80.0,
     target = true,
     eventPrefix = "mhScripts"
}

Config.MHAdminSystem = GetResourceState("mate-admin") == "started"

Config.ApprovedLicenses = {
     "license:123",
     "fivem:123",
     "discord:123",
     "live:123",
     "steam:123",
     "xbl:123"
}


Config.AimEntity = {
     Enabled             = true,         -- Enable or disable the whole aimingEntity thing.
     Distance            = 3,            -- Maximum distance to search for aimingEntity.
     RefreshRateMS       = 100,          -- ShapeTest ticking MS
     Key                 = 'm',          -- Default key to bind the cursor showing
     CenterCursorOnOpen  = true,
     EnableDrawLine      = false,        -- Enable drawline between hitcoord and playercoords.
     EnableSprite        = false,        -- Enable the sprite rendering on the hitcoords.
     SpriteDict          = 'mphud',      -- If EnableSprite enabled
     SpriteName          = 'spectating', -- If EnableSprite enabled
     CursorSpriteOnAim   = 1,            -- Cursor sprite when aimed on cell
     CursorSpriteDefault = 2,            -- Cursor sprite default
     CursorSpriteOnHold  = 4,            -- Cursor sprite when holding  cell
}

Loc = {}
