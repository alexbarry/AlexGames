TODO:

calling createMyModule() from alexgames index.html seems to be what's causing the crash.


In `alexgames_wasm.js` (generated), I think this is the line that is crashing the runtime:

```js
	function doRun() {
	...
		if (shouldRunNow) callMain();
```

It seems to be due to having two main functions defined: one from Lua, the other from `emscripten_api.c`.

When I remove one, it doesn't crash, but it's still not working for some reason... 

I'm not able to reproduce it by making a minimal example of two main functions like this

I'll try including Lua next, I guess
