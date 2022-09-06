local libpath = (...):match("(.-)[^%.]+$")
local crc32 = require(libpath.."crc32")
local bit = bit or require("bit")

local bor,band,lshift,rshift,tohex = bit.bor,bit.band,bit.lshift,bit.rshift,bit.tohex
local char = string.char

--[[

  [local file header 1]
  [encryption header 1]
  [file data 1]
  [data descriptor 1]
  . 
  .
  .
  [local file header n]
  [encryption header n]
  [file data n]
  [data descriptor n]
  [archive decryption header] 
  [archive extra data record] 
  [central directory header 1]
  .
  .
  .
  [central directory header n]
  [zip64 end of central directory record]
  [zip64 end of central directory locator] 
  [end of central directory record]
  
]]

--== Helper functions ==--

local function newStringFile(data)
  local str = data or ""
  
  local file = {}
  
  local pos = 0
  
  function file:getSize() return #str end
  function file:seek(p) pos = p end
  function file:tell() return pos end
  function file:read(bytes)
    if bytes then
      if pos+bytes > #str then bytes = #str-pos end
      
      local substr = str:sub(pos+1,pos+bytes)
      
      pos = pos + bytes
      
      return substr, bytes
    else
      return str
    end
  end
  
  function file:write(d,s)
    str = str:sub(1,pos)..d..str:sub(pos+#d+1,-1)
    
    pos = pos + #d
    
    return #d
  end
  
  function file:flush() end
  function file:close() end
  
  return file
end

local chars = {}
for i = 0, 255 do
  chars[i] = char(i)
end

local function short(num)
  local lo = num%256
  local hi = rshift(num, 8)
  return chars[lo]..chars[hi]
end

local function long(num)
  local lo = num%65536
  local hi = rshift(num, 16)
  return short(lo)..short(hi)
end

--== Internal functions ==--
local header = "\80\75\3\4"..short(20)..char(2)..char(8)..short(8)..short(0)..short(0)

local function writeFile(zipFile,fileName,fileData,modTime,extraField,fileComment,attributes)
  local fileOffset = zipFile:tell()
  
  --[[
  Local file header:
    local file header signature     4 bytes  (0x04034b50)
    version needed to extract       2 bytes
    general purpose bit flag        2 bytes
    compression method              2 bytes
    last mod file time              2 bytes
    last mod file date              2 bytes
    crc-32                          4 bytes
    compressed size                 4 bytes
    uncompressed size               4 bytes
    file name length                2 bytes
    extra field length              2 bytes

    file name (variable size)
    extra field (variable size)
  ]]

  --zipFile:write("\80\75\3\4") --local file header signature - 4 bytes - (0x04034b50)
  
  --zipFile:write(short(20)) --version needed to extract - 2 bytes
  --2.0 - File is compressed using Deflate compression
  
  --zipFile:write(char(2)..char(8)) --general purpose bit flag - 2 bytes
  --[[(For Methods 8 and 9 - Deflating)
    Bit 2  Bit 1
      0      0    Normal (-en) compression option was used.
      0      1    Maximum (-exx/-ex) compression option was used. <----
      1      0    Fast (-ef) compression option was used.
      1      1    Super Fast (-es) compression option was used.
  ]]
  --[[Bit 11: Language encoding flag (EFS).  If this bit is set,
    the filename and comment fields for this file
    MUST be encoded using UTF-8. (see APPENDIX D)]]
  
  --zipFile:write(short(8)) --compression method - 2 bytes
  --8 - The file is Deflated
  
  --zipFile:write(short(0)) --last mod file time - 2 bytes
  --Leave as zero, it doesn't worth calculating.
  
  --zipFile:write(short(0)) --last mod file date - 2 bytes
  --Leave as zero, it doesn't worth calculating.

  zipFile:write(header)
  
  local fileCRC32 = crc32(fileData)
  zipFile:write(long(fileCRC32)) --crc-32 - 4 bytes
  --crc32 of uncompressed file data.
  local compressedData = love.data.compress("string","deflate",fileData,9)
  zipFile:write(long(#compressedData)) --compressed size - 4 bytes
  zipFile:write(long(#fileData)) --uncompressed size - 4 bytes
  zipFile:write(short(fileName and #fileName or 0)) --file name length - 2 bytes
  zipFile:write(short(extraField and #extraField or 0)) --extra field length - 2 bytes
  zipFile:write(fileName or "") --file name (variable size)
  zipFile:write(extraField or "") --extra field (variable size)
  --File data
  zipFile:write(compressedData)

  --[[
  Data descriptor:

    crc-32                          4 bytes
    compressed size                 4 bytes
    uncompressed size               4 bytes
  ]]
  
  zipFile:write("\80\75\7\8") --signature - 4 bytes - (0x08074b50)
  zipFile:write(long(fileCRC32)) --crc-32 - 4 bytes
  --crc32 of uncompressed file data.
  zipFile:write(long(#compressedData)) --compressed size - 4 bytes
  zipFile:write(long(#fileData)) --uncompressed size - 4 bytes
  
  --Return file info, used when writing the centeral directory.
  return {
    fileOffset = fileOffset,
    modTime = modTime or 0,
    fileCRC32 = fileCRC32,
    compressedSize = #compressedData,
    uncompressedSize = #fileData,
    fileName = fileName or "",
    extraField = extraField or "",
    comment = fileComment or "",
    attributes = attributes or 0
  }
end

local function writeCenteralDirectory(zipFile,filesInfos)
  local centeralDirectorySize = 0
  local centeralDirectoryOffset = zipFile:tell()

  --[[
  Central directory structure:

    central file header signature   4 bytes  (0x02014b50)
    version made by                 2 bytes
    version needed to extract       2 bytes
    general purpose bit flag        2 bytes
    compression method              2 bytes
    last mod file time              2 bytes
    last mod file date              2 bytes
    crc-32                          4 bytes
    compressed size                 4 bytes
    uncompressed size               4 bytes
    file name length                2 bytes
    extra field length              2 bytes
    file comment length             2 bytes
    disk number start               2 bytes
    internal file attributes        2 bytes
    external file attributes        4 bytes
    relative offset of local header 4 bytes

    file name (variable size)
    extra field (variable size)
    file comment (variable size)
  ]]
  
  for _, fileInfo in pairs(filesInfos) do
    
    zipFile:write("\80\75\1\2") --central file header signature - 4 bytes - (0x02014b50)
    --version made by - 2 bytes
    zipFile:write(char(63)) --Spec file version: 6.3.4
    zipFile:write(char(3)) --3 - UNIX
    zipFile:write(short(20)) --version needed to extract - 2 bytes
    --2.0 - File is compressed using Deflate compression
    
    zipFile:write(char(2)..char(8)) --general purpose bit flag - 2 bytes
    --[[(For Methods 8 and 9 - Deflating)
      Bit 2  Bit 1
        0      0    Normal (-en) compression option was used.
        0      1    Maximum (-exx/-ex) compression option was used. <----
        1      0    Fast (-ef) compression option was used.
        1      1    Super Fast (-es) compression option was used.
    ]]
    --[[Bit 11: Language encoding flag (EFS).  If this bit is set,
      the filename and comment fields for this file
      MUST be encoded using UTF-8. (see APPENDIX D)]]
    
    zipFile:write(short(8)) --compression method - 2 bytes
    --8 - The file is Deflated
    
    zipFile:write(short(0)) --last mod file time - 2 bytes
    --Leave as zero, it doesn't worth calculating.
    
    zipFile:write(short(0)) --last mod file date - 2 bytes
    --Leave as zero, it doesn't worth calculating.
    
    zipFile:write(long(fileInfo.fileCRC32)) --crc-32 - 4 bytes
    --crc32 of uncompressed file data.
    
    zipFile:write(long(fileInfo.compressedSize)) --compressed size - 4 bytes
    zipFile:write(long(fileInfo.uncompressedSize)) --uncompressed size - 4 bytes
    zipFile:write(short(#fileInfo.fileName)) --file name length - 2 bytes
    zipFile:write(short(#fileInfo.extraField)) --extra field length - 2 bytes
    zipFile:write(short(#fileInfo.comment)) --file comment length - 2 bytes
    zipFile:write(short(0)) --disk number start - 2 bytes
    zipFile:write(short(0)) --internal file attributes - 2 bytes
    zipFile:write(long(fileInfo.attributes)) --external file attributes - 4 bytes
    zipFile:write(long(fileInfo.fileOffset)) --relative offset of local header - 4 bytes
    zipFile:write(fileInfo.fileName) --file name (variable size)
    zipFile:write(fileInfo.extraField) --extra field (variable size)
    zipFile:write(fileInfo.comment) --file comment (variable size)
    centeralDirectorySize = centeralDirectorySize + 46 + #fileInfo.fileName + #fileInfo.extraField + #fileInfo.comment
  end
  
  --Return centeral directory info
  return {
    offset = centeralDirectoryOffset,
    size = centeralDirectorySize,
    entries = #filesInfos
  }
end

local function writeEndOfCenteralDirectory(zipFile,centeralDirectoryInfo,zipComment)
  --[[
  End of central directory record:
  
    end of central dir signature    4 bytes  (0x06054b50)
    number of this disk             2 bytes
    number of the disk with the
    start of the central directory  2 bytes
    total number of entries in the
    central directory on this disk  2 bytes
    total number of entries in
    the central directory           2 bytes
    size of the central directory   4 bytes
    offset of start of central
    directory with respect to
    the starting disk number        4 bytes
    .ZIP file comment length        2 bytes
    .ZIP file comment       (variable size)
  ]]
  
  zipFile:write("\80\75\5\6") --end of central dir signature - 4 bytes - (0x06054b50)
  zipFile:write(short(0)) --number of this disk - 2 bytes
  zipFile:write(short(0)) --number of the disk with the start of the central directory - 2 bytes
  zipFile:write(short(centeralDirectoryInfo.entries)) --total number of entries in the central directory on this disk - 2 bytes
  zipFile:write(short(centeralDirectoryInfo.entries)) --total number of entries in the central directory - 2 bytes
  zipFile:write(long(centeralDirectoryInfo.size)) --size of the central directory - 4 bytes
  zipFile:write(long(centeralDirectoryInfo.offset)) --offset of start of central directory with respect to the starting disk number - 4 bytes
  zipFile:write(short(zipComment and #zipComment or 0)) --.ZIP file comment length - 2 bytes
  zipFile:write(zipComment or "") --.ZIP file comment (variable size) 
end

--== User API ==--

local zapi = {}

function zapi.newZipWriter(zipFile)
  zipFile = zipFile or newStringFile()
  
  local filesInfos = {}
  local zipFinished = false
  local writer = {}
  
  function writer.addFile(fileName,fileData,modTime,extraField,fileComment,attributes)
    if zipFinished then
      return error("The .ZIP file is finished !")
    end
    filesInfos[#filesInfos+1] = writeFile(zipFile,fileName,fileData,modTime,extraField,fileComment,attributes)
  end
  
  function writer.finishZip(zipComment)
    if zipFinished then
      return error("The .ZIP file is already finished !")
    end
    local centeralDirectoryInfo = writeCenteralDirectory(zipFile,filesInfos)
    writeEndOfCenteralDirectory(zipFile,centeralDirectoryInfo,zipComment)
    zipFinished = true
    return zipFile
  end
  
  return writer
end

function zapi.createZip(path, zipFile)  
  local writer = zapi.newZipWriter(zipFile)
  local function index(dir)
    local dirInfo = love.filesystem.getInfo(dir)
    if dirInfo.type == "file" then
      local fileData = love.filesystem.read(dir)
      local fileName = dir:sub(#path+2, -1)
      local modTime = dirInfo.modTime
      writer.addFile(fileName,fileData,modTime)
    elseif dirInfo.type == "directory" then
      local items = love.filesystem.getDirectoryItems(dir)
      for _,item in ipairs(items) do
        index(dir.."/"..item)
      end
    end
  end
  if not love.filesystem.getInfo(path) then
    return false, "Source doesn't exist!"
  end

  index(path)

  local zipData = writer.finishZip()
  
  if not zipFile then
    return true, zipData:read()
  end
  
  zipFile:flush()
  zipFile:close()
  
  return true
end

function zapi.writeZip(path,destination)
  local zipFile, zipFileErr = love.filesystem.newFile(destination,"w")
  if not zipFile then return false, "Failed to open destination zip file: "..tostring(zipFileErr) end

  path = path:gsub("\\","/")
  if path:sub(1,1) == "/" then
    path = path:sub(2,-1)
  end
  if path:sub(-1,-1) == "/" then
    path = path:sub(1,-2)
  end
  
  return zapi.createZip(path, zipFile)
end

return zapi