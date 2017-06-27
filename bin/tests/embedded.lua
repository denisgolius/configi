_ENV = require "bin/tests/ENV"
function test(p)
  local r, o = cfg("-x", "-m", "-e", p)
  T.policy = function()
    T.equal(r, 0)
  end
  T.ordering = function()
    T.is_not_nil(string.find(o.stderr[1], "[%g%s^#]+#test includes"))
    T.is_not_nil(string.find(o.stderr[2], "[%g%s^#]+#test includes"))
    T.is_not_nil(string.find(o.stderr[3], "[%g%s^#]+"))
    T.is_not_nil(string.find(o.stderr[4], "[%g%s^#]+"))
    T.is_not_nil(string.find(o.stderr[5], "[%g%s^#]+"))
    T.is_not_nil(string.find(o.stderr[6], "[%g%s^#]+"))
    T.is_not_nil(string.find(o.stderr[7], "[%g%s^#]+#test handlers"))
    T.is_not_nil(string.find(o.stderr[8], "[%g%s^#]+#test handlers"))
  end
  T.structure = function()
    T.is_not_nil(stat.stat(dir.."core-embedded-structure"))
  end
  T.handlers = function()
    T.is_not_nil(stat.stat(dir.."core-embedded-handlers"))
  end
  T.functionality = function()
   T.is_not_nil(stat.stat(dir.."core-embedded.txt"))
    local st = stat.stat(dir.."core-embedded.txt")
    T.equal(string.format("%o", st.st_mode), "100777")
    os.remove(dir.."core-embedded-structure")
    os.remove(dir.."core-embedded-handlers")
    os.remove(dir.."core-embedded.txt")
  end
end
test "init.lua"
T.summary()
