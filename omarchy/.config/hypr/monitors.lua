-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = "auto"

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Built-in panel: 1920x1080 / 1.5 = 1280x720 logical pixels.
-- Keep it at the origin, including when the external screen is disconnected.
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1.5 })

-- External screen above, centered: (1280 - 1920) / 2 = -320.
-- Its bottom edge meets the built-in panel's top edge at y = 0.
hl.monitor({
	output = "HDMI-A-1",
	mode = "1920x1080@60",
	position = "100x-1920",
	scale = 1,
	transform = 1,
})
