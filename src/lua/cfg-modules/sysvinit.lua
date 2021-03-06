--- Ensure that a service managed by sysvinit is started or stopped.
-- Tested on OpenWRT only.
-- @module sysvinit
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local ENV, M, sysvinit = {}, {}, {}
local cfg = require"cfg"
local lib = require"lib"
local cmd = lib.exec.cmd
_ENV = ENV

M.required = { "service" }

local pgrep = function(service)
  local ok, ret = cmd.pgrep{ service }
  if ok then
  return true, ret.stdout[1]
  else
  return false
  end
end

--- Start a service.
-- @Promiser service
-- @Aliases present
-- @param None
-- @usage sysvinit.started("ntpd")()
function sysvinit.started(S)
  M.report = {
    repaired = "sysvinit.started: Successfully started service.",
      kept = "sysvinit.started: Service already started.",
      failed = "sysvinit.started: Error restarting service."
  }
  return function(P)
    P.service = S
    local F, R = cfg.init(P, M)
    if R.kept or pgrep(P.service) then
      return F.kept(P.service)
    end
    F.run(cmd["-/etc/init.d/" .. P.service], { "start", ignore = true })
    return F.result(P.service, pgrep(P.service))
  end
end

--- Stop a service.
-- @Promiser service
-- @Aliases absent
-- @param None
-- @usage sysvinit.stopped("telnetd")()
function sysvinit.stopped(S)
  M.report = {
    repaired = "sysvinit.stopped: Successfully stopped service.",
      kept = "sysvinit.stopped: Service already stopped.",
      failed = "sysvinit.stopped: Error stopping service."
  }
  return function(P)
    P.service = S
    local F, R = cfg.init(P, M)
    if R.kept or not pgrep(P.service) then
      return F.kept(P.service)
    end
    F.run(cmd["-/etc/init.d/" .. P.service], { "stop", ignore = true })
    return F.result(P.service, (pgrep(P.service) == false))
  end
end

--- Restart a service.
-- @Promiser service
-- @param None
-- @usage sysvinit.restart("ntpd")()
function sysvinit.restart(S)
  M.report = {
    repaired = "sysvinit.restart: Successfully restarted service.",
      kept = "sysvinit.restart: Service not yet started.",
      failed = "sysvinit.restart: Error restarting service."
  }
  return function(P)
    P.service = S
    local F, R = cfg.init(P, M)
    local _, pid = pgrep(P.service)
    if R.kept or not pid then
      return F.kept(P.service)
    end
    F.run(cmd["-/etc/init.d/" .. P.service], { "restart", ignore = true })
    local _, npid = pgrep(P.service)
    return F.result(P.service, (pid ~= npid))
  end
end

--- Reload a service.
-- @Promiser service
-- @Note OpenWRT sysvinit can not detect reload failures
-- @param None
-- @usage sysvinit.reload("ntpd")()
function sysvinit.reload(S)
  M.report = {
    repaired = "sysvinit.reload: Successfully reloaded service.",
      kept = "sysvinit.reload: Service not yet started.",
      failed = "sysvinit.reload: Error reloading service."
  }
  return function(P)
    P.service = S
    local F, R = cfg.init(P, M)
    local _, pid = pgrep(P.service)
    if R.kept or not pid then
      return F.kept(P.service)
    end
    -- Assumed to always succeed
    F.run(cmd["-/etc/init.d/" .. P.service], { "reload", ignore = true })
    return F.result(P.service, true)
  end
end

--- Enable a service
-- @Promiser service
-- @param None
-- @usage sysvinit.enabled("ntpd")()
function sysvinit.enabled(S)
  M.report = {
    repaired = "sysvinit.enabled: Successfully enabled service.",
      kept = "sysvinit.enabled: Service already enabled.",
      failed = "sysvinit.enabled: Error enabling service."
  }
  return function(P)
    P.service = S
    local F, R = cfg.init(P, M)
    if R.kept then
      return F.kept(P.service)
    end
    if F.run(cmd["-/etc/init.d/" .. P.service], { "enabled" }) then
      return F.kept(P.service)
    end
    F.run(cmd["-/etc/init.d/" .. P.service], { "enable", ignore = true })
    return F.result(P.service, F.run(cmd["-/etc/init.d/" .. P.service], { "enabled"}))
  end
end

--- Disable a service.
-- @Promiser service
-- @param None
-- @usage sysvinit.disabled("ntpd")()
function sysvinit.disabled(S)
  M.report = {
    repaired = "sysvinit.disabled: Successfully disabled service.",
    kept = "sysvinit.disabled: Service already disabled.",
    failed = "sysvinit.disabled: Error disabling service."
  }
  return function(P)
    P.service = S
    local F, R = cfg.init(P, M)
    local ok = cmd["-/etc/init.d/" .. P.service]{ "enabled" }
    if R.kept or not ok then
      return F.kept(P.service)
    end
    F.run(cmd["-/etc/init.d/" .. P.service], { "disable", ignore = true })
    ok = cmd["-/etc/init.d/" .. P.service]{ "enabled" }
    return F.result(P.service, (not ok))
  end
end

sysvinit.present = sysvinit.started
sysvinit.absent = sysvinit.stopped
return sysvinit
