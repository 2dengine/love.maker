# love.maker
This library was written in Lua specifically for the LÖVE2D framework.
love.maker is a library that can minify, compile and compress your LÖVE2D project folder.
If you choose to compile your Lua script files, the resulting .love file will only run on the same version of LÖVE2D or LuaJIT.
This library allows you to output .love files anywhere on your system using absolute paths.
The complete documentation is available here: https://2dengine.com/doc/maker.html

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
Source code by 2dengine LLC (MIT License) https://github.com/2dengine/love.maker

Compression by Rami Sabbagh (MIT License) https://github.com/Rami-Sabbagh/LoveZip

Minification by Marcus 'ReFreezed' Thunström (MIT License) https://github.com/ReFreezed/DumbLuaParser

Un-Restricted File System by Ross Grams (MIT License)  https://github.com/rgrams/urfs

## Testing
Linux testing by gphg

Additional testing by the Love2D community https://love2d.org/forums/viewtopic.php?t=86893
