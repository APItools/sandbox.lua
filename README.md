sandbox.lua
===========

A pure-lua solution for running untrusted Lua code.

The default behavior is restricting access to "dangerous" functions in Lua, such as `os.execute`.

It's possible to provide extra functions via the `options.env` parameter.

Infinite loops are prevented via the `debug` library.

For now, sandbox.lua only works with Lua 5.1.x.

Usage
=====

Require the module like this:

``` lua
local sandbox = require 'sandbox'
```

### sandbox.protect

`sandbox.protect(f)` (or `sandbox(f)`) produces a sandboxed version of `f`. `f` can be a Lua function or a string with Lua code.

A sandboxed function works as regular functions as long as they don't access any insecure features:

```lua
local sandboxed_f = sandbox(function() return 'hey' end)
local msg = sandboxed_f() -- msg is now 'hey'
```

Sandboxed options can not access unsafe Lua modules. (See the [source code](https://github.com/kikito/sandbox.lua/blob/master/sandbox.lua#L35) for a list)

When a sandboxed function tries to access an unsafe module, an error is produced.

```lua
local sf = sandbox.protect(function()
  os.execute('rm -rf /') -- this will throw an error, no damage done
end)

sf() -- error: os.execute not found
```

Sandboxed functions will eventually throw an error if they contain infinite loops:

```lua
local sf = sandbox.protect(function()
  while true do end
end)

sf() -- error: quota exceeded
```

### options.quota

`sandbox.lua` prevents infinite loops from halting the program by hooking the `debug` library to the sandboxed function, and "counting instructions". When
the instructions reach a certain limit, an error is produced.

This limit can be tweaked via the `quota` option. But default, it is 500000.

It is not possible to exhaust the machine with infinite loops; the following will throw an error after invoking 500000 instructions:

``` lua
sandbox.run('while true do end') -- raise errors after 500000 instructions
sandbox.run('while true do end', {quota=10000}) -- raise error after 10000 instructions
```

Note that if the quota is low enough, sandboxed functions that do lots of calculations might fail:

``` lua
local f = function()
  local count = 1
  for i=1, 400 do count = count + 1 end
  return count
end

sandbox.run(f, {quota=100}) -- raises error before the function ends
```

### options.env

Use the `env` option to inject additional variables to the environment in which the sandboxed function is executed.

    local msg = sandbox.run('return foo', {env = {foo = 'This is a global var on the the environment'}})

Note that the `env` variable will be modified by the sandbox (adding base modules like `string`). The sandboxed code can also modify it. It is
recommended to discard it after use.

    local env = {amount = 1}
    sandbox.run('amount = amount + 1', {env = env})
    assert(env.amount == 2)


### sandbox.run

`sandbox.run(f)` sanboxes and executes `f` in a single line. `f` can be either a string or a function

You can pass `options` param, and it will work like in `sandbox.protect`.
Any extra parameters will just be passed to the sandboxed function when executed.

In other words, `sandbox.run(f, o, ...)` is equivalent to `sandbox.protect(f,o)(...)`.

Notice that if `f` throws an error, it is *NOT* captured by `sandbox.run`. Use `pcall` if you want your app to be immune to errors, like this:

``` lua
local ok, result = pcall(sandbox.run, 'error("this just throws an error")')
```


Installation
============

Just copy sandbox.lua wherever you need it.

License
=======

This library is released under the MIT license. See MIT-LICENSE.txt for details

Specs
=====

This project uses [telescope](https://github.com/norman/telescope) for its specs. In order to run them, install it and then:

```
cd /path/to/where/the/spec/folder/is
tsc spec/*
```

I would love to use [busted](http://olivinelabs.com/busted/), but it has some incompatibility with `debug.sethook(f, "", quota)` and the tests just hanged up.
