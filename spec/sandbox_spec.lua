local sandbox = require 'sandbox'

local assert_equal = assert.are.same
local assert_error = assert.error
local assert_not_error = function(...) assert(pcall(...)) end

describe('sandbox.run', function()

  describe('when handling base cases', function()
    it('can run harmless functions', function()
      local r = sandbox.run(function() return 'hello' end)
      assert_equal(r, 'hello')
    end)

    it('can run harmless strings', function()
      local r = sandbox.run("return 'hello'")
      assert_equal(r, 'hello')
    end)

    it('has access to safe methods', function()
      assert_equal(10,      sandbox.run("return tonumber('10')"))
      assert_equal('HELLO', sandbox.run("return string.upper('hello')"))
      assert_equal(1,       sandbox.run("local a = {3,2,1}; table.sort(a); return a[1]"))
      assert_equal(10,      sandbox.run("return math.max(1,10)"))
    end)

    it('does not allow access to not-safe stuff', function()
      assert_error(function() sandbox.run('return setmetatable({}, {})') end)
      assert_error(function() sandbox.run('return string.rep("hello", 5)') end)
    end)
  end)

  describe('when handling string.rep', function()
    it('does not allow pesky string:rep', function()
      assert_error(function() sandbox.run('return ("hello"):rep(5)') end)
    end)

    it('restores the value of string.rep', function()
      sandbox.run("")
      assert_equal('hellohello', string.rep('hello', 2))
    end)

    it('restores string.rep even if there is an error', function()
      assert_error(function() sandbox.run("error('foo')") end)
      assert_equal('hellohello', string.rep('hello', 2))
    end)

    it('passes parameters to the function', function()
      assert_equal(sandbox.run(function(a,b) return a + b end, {}, 1,2), 3)
    end)
  end)


  describe('when the sandboxed function tries to modify the base environment', function()

    it('does not allow modifying the modules', function()
      assert_error(function() sandbox.run("string.foo = 1") end)
      assert_error(function() sandbox.run("string.char = 1") end)
    end)

    it('does not persist modifications of base functions', function()
      sandbox.run('error = function() end')
      assert_error(function() sandbox.run("error('this should be raised')") end)
    end)

    it('DOES persist modification to base functions when they are provided by the base env', function()
      local env = {['next'] = 'hello'}
      sandbox.run('next = "bye"', {env=env})
      assert_equal(env['next'], 'bye')
    end)
  end)


  describe('when given infinite loops', function()

    it('throws an error with infinite loops', function()
      assert_error(function() sandbox.run("while true do end") end)
    end)

    it('restores string.rep even after a while true', function()
      assert_error(function() sandbox.run("while true do end") end)
      assert_equal('hellohello', string.rep('hello', 2))
    end)

    it('accepts a quota param', function()
      assert_not_error(function() sandbox.run("for i=1,100 do end") end)
      assert_error(function() sandbox.run("for i=1,100 do end", {quota = 20}) end)
    end)

    it('does not use quotes if the quote param is false', function()
      assert_not_error(function() sandbox.run("for i=1,1000000 do end", {quota = false}) end)
    end)

  end)


  describe('when given an env option', function()
    it('is available on the sandboxed env as the _G variable', function()
      local env = {foo = 1}
      assert_equal(1, sandbox.run("return foo", {env = env}))
      assert_equal(env, sandbox.run("return _G", {env = env}))
    end)

    it('does not hide base env', function()
      assert_equal('HELLO', sandbox.run("return string.upper(foo)", {env = {foo = 'hello'}}))
    end)

    it('can modify the env', function()
      local env = {foo = 1}
      sandbox.run("foo = 2", {env = env})
      assert_equal(env.foo, 2)
    end)
  end)

end)
