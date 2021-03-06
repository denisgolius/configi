--- Ensure that a package managed by Portage is installed or absent.
-- @module portage
-- @author Eduardo Tongson <propolice@gmail.com>
-- @license MIT <http://opensource.org/licenses/MIT>
-- @added 0.9.0

local M, portage = {}, {}
local string = string
local cfg = require"cfg-core.lib"
local lib = require"lib"
local path, table, os = lib.path, lib.table, lib.os
local cmd = lib.exec.cmd
local stat = require"posix.sys.stat"
local dirent = require"posix.dirent"
_ENV = nil

M.required = { "atom" }

local decompose = function(P)
  local A = {}
  if string.find(P.atom, "^[%<%>%=]+%g*$") then
    -- package ">=net-misc/rsync-3.0.9-r3"
    A.lead = string.match(P.atom, "[%<%>%=]+") -- >=
    A.category, A.package = path.split(P.atom) -- >=net-misc, rsync-3.0.9-r3
    A.category = string.match(A.category, "[%<%>%=]+([%w%-]+)") -- net-misc
    A.version = "" -- version is already at the end of A.package
    --[[
    A.revision = string.match(A.package, "%-(r[%d]+)", -3) -- r3
    A.version = string.match(A.package, "[%w%-]+%-([%d%._]+)%-" .. A.revision) -- 3.0.9
    A.package = string.match(A.package, "([%w%-]+)" .. "%-" .. A.version .. "%-" .. A.revision) -- rsync
    ]]
  elseif P.version then
    --[[
      package "net-misc/rsync"
      version ">=3.0.9-r3"
    ]]
    A.lead = string.match(P.version, "[%<%>%=]+")
    A.category, A.package = path.split(P.atom)
    A.version = string.match(P.version, "[%<%>%=]+([%g]+)")
    A.version = "-" .. A.version
    if A.lead == nil then
      A.lead = "="
    end
  else
    -- package "net-misc/rsync"
    A.category, A.package = path.split(P.atom)
    A.lead, A.version = "", ""
  end
  return A
end

local found = function(P)
  local A = decompose(P)
  if os.is_dir("/var/db/pkg/" .. A.category) then
    if A.lead == "" then
      -- package "net-misc/rsync"
      for packages in dirent.files("/var/db/pkg/" .. A.category) do
        if string.find(packages, "^" .. A.package .. "%-%g*$") then
          return true
        end
      end
    else
      if stat.stat(string.format("/var/db/pkg/%s/%s%s", A.category, A.package, A.version)) then
        return true
      end
    end
  end
end

--- Install package atom.
--- See emerge(1).
-- @Promiser package atom. Can be "category/package" or "category/package-version"
-- @Aliases installed
-- @Aliases add
-- @param version package version
-- @param deep evaluate entire dependency tree [Default: false]
-- @param newuse reinstall packages that had a change in its USE flags [Default: false]
-- @param nodeps do not merge dependencies [Default: false]
-- @param noreplace skip already installed packages [Default: false]
-- @param oneshot do not update the world file [Default: true]
-- @param onlydeps only merge dependencies [Default: false]
-- @param sync perform an `emerge --sync` before installing packages) [Default: false]
-- @param update update package to the best version [Default: false]
-- @param unmask enable auto-unmask and auto-unmask-write options [Default: false]
-- @usage portage.present("dev-util/strace"){
--   version = "4.8"
-- }
-- portage.present("dev-util/strace-4.8")()
-- portage.present("dev-util/strace")()
function portage.present(S)
  M.parameters = {
    "deep", "newuse", "nodeps", "noreplace", "oneshot", "onlydeps", "sync", "unmask", "update", "version"
  }
  M.report = {
    repaired = "portage.present: Successfully installed package.",
    kept = "portage.present: Package already installed.",
    failed = "portage.present: Error installing package."
  }
  return function(P)
    P.atom = S
    local F, R = cfg.init(P, M)
    if R.kept then
      return F.kept(P.atom)
    end
    if P.oneshot == nil then
      P.oneshot = true -- oneshot "yes" is default
    end
    -- `emerge --sync` mode
    if P.sync == true then
      if F.run(cmd["/usr/bin/emerge"], { "--sync" }) then
        F.msg("sync", "Sync finished", true)
      else
        return F.result("sync", nil, "Sync failed")
      end
    end
    if found(P) then
      return F.kept(P.atom)
    end
    local A = decompose(P)
    local atom = string.format("%s%s/%s%s", A.lead or "", A.category, A.package, A.version)
    local args = { "--quiet", "--quiet-build", atom }
    local set = {
      deep = "--deep",
      newuse = "--newuse",
      nodeps = "--nodeps",
      noreplace = "--noreplace",
      oneshot = "-1",
      onlydeps = "--onlydeps"
    }
    P:insert_if(set, args, 3)
    if P.unmask then
      table.insert(args, 3, "--auto-unmask-write")
      table.insert(args, 3, "--auto-unmask")
      if not F.run(cmd["/usr/bin/emerge"], args) then
        return F.result(atom, nil, M.report.failed)
      end
      table.remove(args, 3)
      table.remove(args, 3)
    end
    return F.result(atom, F.run(cmd["/usr/bin/emerge"], args))
  end
end

--- Remove package atom.
-- @Promiser package atom. Can be "category/package" or "category/package-version"
-- @Aliases uninstalled
-- @Aliases remove
-- @param atom package atom to unmerge [REQUIRED] [ALIAS: package]
-- @param depclean Remove packages not associated with explicitly installed packages [DEFAULT: false]
-- @usage portage.absent("dev-util/strace")()
function portage.absent(S)
  M.parameters = { "depclean" }
  M.report = {
    repaired = "portage.absent: Successfully removed package.",
    kept = "portage.absent: Package not installed.",
    failed = "portage.absent: Error removing package."
  }
  return function(P)
    P.atom = S
    local F, R = cfg.init(P, M)
    if R.kept or not found(P) then
      return F.kept(P.atom)
    end
    local env = { "CLEAN_DELAY=0", "PATH=/bin:/usr/bin:/sbin:/usr/sbin" } -- PORTAGE_BZIP2_COMMAND needs $PATH
    local A = decompose(P)
    local atom = string.format("%s%s/%s%s", A.lead or "", A.category, A.package, A.version)
    local args = { env = env, "--quiet", "-C", atom }
    table.insert_if(P.depclean, args, 2, "--depclean")
    return F.result(atom, F.run(cmd["/usr/bin/emerge"], args))
  end
end

portage.installed = portage.present
portage.add = portage.present
portage.uninstalled = portage.absent
portage.remove = portage.absent
return portage
