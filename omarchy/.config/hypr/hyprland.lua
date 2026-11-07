-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- 更新前と同じく、ワークスペース番号をPC全体で共有する。
-- 標準のキー割り当てが作られる前に、モニター別の番号変換を置き換える。
require("default.hypr.helpers")
local workspaces = require("default.hypr.monitor-workspaces")
workspaces.reconcile = function() end
workspaces.focus = function(id)
  return hl.dsp.focus({ workspace = tostring(id) })
end
workspaces.move_window = function(id, follow)
  return hl.dsp.window.move({ workspace = tostring(id), follow = follow ~= false })
end
workspaces.move_to_monitor = function(direction)
  return hl.dsp.workspace.move({ monitor = direction })
end

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })
