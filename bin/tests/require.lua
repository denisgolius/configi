_ENV = require "bin/tests/ENV"
function test(p1, p2)
  local r, o
  T.policy = function()
    r, o = cfg("-x", "-m", "-f", p1)
  end
  T.ordering = function()
    T.is_not_nil(string.find(o.stderr[1], "[%g%s^#]+#1st"))
    T.is_not_nil(string.find(o.stderr[2], "[%g%s^#]+#2nd"))
    T.is_not_nil(string.find(o.stderr[3], "[%g%s^#]+#2nd"))
    T.is_not_nil(string.find(o.stderr[4], "[%g%s^#]+#3rd"))
    T.is_not_nil(string.find(o.stderr[5], "[%g%s^#]+#3rd"))
    T.is_not_nil(string.find(o.stderr[6], "[%g%s^#]+#4th"))
    T.is_not_nil(string.find(o.stderr[7], "[%g%s^#]+#4th"))
    T.is_not_nil(string.find(o.stderr[8], "[%g%s^#]+#nodeps"))
    T.is_not_nil(string.find(o.stderr[9], "[%g%s^#]+#nodeps"))
    T.is_not_nil(string.find(o.stderr[10], "[%g%s^#]+#delete%-nodeps"))
    T.is_not_nil(string.find(o.stderr[11], "[%g%s^#]+#delete%-nodeps"))
    T.is_not_nil(string.find(o.stderr[12], "[%g%s^#]+#last"))
    T.is_not_nil(string.find(o.stderr[13], "[%g%s^#]+#last"))
    T.is_not_nil(string.find(o.stderr[14], "[%g%s^#]+#delete%-last"))
    T.is_not_nil(string.find(o.stderr[15], "[%g%s^#]+#delete%-last"))
    os.remove(dir.."core-require-first")
    os.remove(dir.."core-require-another")
    os.remove(dir.."core-require")
  end
  T.policy = function()
    r, o = cfg("-x", "-m", "-f", p2)
  end
  T.nodeps = function()
    T.is_not_nil(string.find(o.stderr[1], "[%g%s^#]+#nodeps"))
    T.is_not_nil(string.find(o.stderr[2], "[%g%s^#]+#nodeps"))
    T.is_not_nil(string.find(o.stderr[3], "[%g%s^#]+#2nd"))
    T.is_not_nil(string.find(o.stderr[4], "[%g%s^#]+#2nd"))
    T.is_not_nil(string.find(o.stderr[5], "[%g%s^#]+#3rd"))
    T.is_not_nil(string.find(o.stderr[6], "[%g%s^#]+#3rd"))
    T.is_not_nil(string.find(o.stderr[7], "[%g%s^#]+#4th"))
    T.is_not_nil(string.find(o.stderr[8], "[%g%s^#]+#4th"))
    os.remove(dir.."core-require-nodeps")
    os.remove(dir.."core-require-last")
  end
end
test("test/core-require.lua",
  "test/core-require-nodeps.lua")
