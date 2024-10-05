# love.maker
This library was written in Lua specifically for the [LÖVE](https://love2d.org) framework.
love.maker is a library that can minify, compile and compress your project folder.
If you choose to compile your Lua script files, the resulting .love file will only run on the exact same version of LÖVE or LuaJIT that was used when building.
This library allows you to output .love files anywhere on your system using absolute paths.


The source code available on [GitHub](https://github.com/2dengine/love.maker) and the official documentation is from [2dengine.com](https://2dengine.com/doc/maker.html)

## Example

```Lua
love.maker = require("maker")
love.maker.setExtensions('lua', 'png', 'txt') -- include only the specified extensions

local build = love.maker.newBuild("C://path/to/project/folder/") -- create from source folder
build:ignore('/readme.txt') -- exclude a specific file
build:ignoreMatch('^/%.git') -- exclude based on pattern matching
build:allow('/images/exception.jpg') -- whitelist a specific file

build:save('C://path/to/output/game.love', 'DEMO') -- build the .love project file
local comment = love.maker.getComment(dest)
print(comment)
```

## Credits
[Source code](https://github.com/2dengine/love.maker) by 2dengine LLC (MIT License)

[Compression](https://github.com/Rami-Sabbagh/LoveZip) by Rami Sabbagh (MIT License) 

[Minification](https://github.com/ReFreezed/DumbLuaParser) by Marcus 'ReFreezed' Thunström (MIT License) 

[Un-Restricted File System](https://github.com/rgrams/urfs) by Ross Grams (MIT License)  

Testing by gphg and the LÖVE community

Please support our work so we can release more free software in the future.
