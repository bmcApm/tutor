--
-- Created by IntelliJ IDEA.
-- User: kavraham
-- Date: 2/8/2016
-- Time: 2:11 PM
-- To change this template use File | Settings | File Templates.
--


local pluginHelper = {}


---------------------------------------------------------------------------------------------------------
-- Download functions
---------------------------------------------------------------------------------------------------------

local lfs = require ("lfs")

local function downloadFile(fileLocation, fileDestination, fileName)
    lfs.mkdir(fileDestination)
    local http = require("socket.http")
    local body, code = http.request(fileLocation .. fileName)
    if not body then error(code) end

    -- save the content to a file
    local f = assert(io.open(fileDestination .. fileName, 'wb')) -- open in "binary" mode
    f:write(body)
    f:close()
end


---------------------------------------------------------------------------------------------------------
-- OS functions
---------------------------------------------------------------------------------------------------------

local function getOsName()
    local BinaryFormat = package.cpath:match("%p[\\|/]?%p(%a+)")
    if BinaryFormat == "dll" then
        return "windows"
    elseif BinaryFormat == "so" then
        return "linux"
    elseif BinaryFormat == "dylib" then
        return "mac"
    end
    BinaryFormat = nil
end

local function isSupportedWinOSVersion()
    local result = false
    local verCommand = "ver"
    local verHandle = io.popen(verCommand)
    local verResult = verHandle:read("*a")
    verHandle:close()
    if (string.find(verResult, "Version 6.")) then result=true end
    return result
end

local function is64BitWinOSVersion()
    local osBit = nil
    local bitCommand = "wmic os get osarchitecture"
    local bitHandle = io.popen(bitCommand)
    local bitResult = bitHandle:read("*a")
    bitHandle:close()
    if (string.find(bitResult, "64")) then
        return true else return false
    end
    return osBit
end



---------------------------------------------------------------------------------------------------------
-- Zip functions
---------------------------------------------------------------------------------------------------------

local unzip = require "zip"

local function Extract(zipPath, zipFilename, destinationPath)
    local zfile, err = unzip.open(zipPath .. zipFilename)
    -- iterate through each file insize the zip file
    for file in zfile:files() do
        local currFile, err = zfile:open(file.filename)
        local currFileContents = currFile:read("*a") -- read entire contents of current file

        local binaryOutput = io.open(destinationPath .. file.filename, "wb")

        -- write current file inside zip to a file outside zip
        if(binaryOutput)then
            binaryOutput:write(currFileContents)
            binaryOutput:close()
        end
        currFile:close()
    end

    zfile:close()
end


---------------------------------------------------------------------------------------------------------
-- Files functions
---------------------------------------------------------------------------------------------------------

local function updateModuleConfFile(confFileName, installDirectory)
    local confFile = io.open( installDirectory .. confFileName, "r" )
    local confStr = confFile:read( "*a" )
    confStr = string.gsub( confStr, "C:/MyInstallDir/", installDirectory)
    confFile:close()

    confFile = io.open( installDirectory .. confFileName, "w" )
    confFile:write( confStr )
    confFile:close()
end


local function createBackupHttpdConfFile(httpdConfFilePath)
    local backupConfFile = io.open( httpdConfFilePath, "r" )
    local backuoConfStr = backupConfFile:read( "*a" )
    backupConfFile:close()

    backupConfFile = io.open( httpdConfFilePath .. ".bmc.backup", "w" )
    backupConfFile:write( backuoConfStr )
    backupConfFile:close()
end


local function updateHttpdConfFile(httpdConfFilePath, confFileName)
    local confFile = io.open( httpdConfFilePath, "a" )
    confFile:write( " \n" )
    confFile:write( "## Include for BMC Apache plugin\n" )
    confFile:write( "include "..confFileName )
    confFile:close()
end


---------------------------------------------------------------------------------------------------------
-- Restart Apache functions
---------------------------------------------------------------------------------------------------------

local function winApacheRestart(apacheRootDirectory)
    local Command = apacheRootDirectory.."bin/httpd.exe -k restart"
    local Handle = io.popen(Command)
    local Result = Handle:read("*a")
    Handle:close()
    return Result
end

local function linuxApacheRestart()
    local Command = "hapachectl –k graceful"
    local Handle = io.popen(Command)
    local Result = Handle:read("*a")
    Handle:close()
    return Result
end

---------------------------------------------------------------------------------------------------------
-- Parser functions
---------------------------------------------------------------------------------------------------------


function lines(str)
    local t = {}
    local function helper(line) table.insert(t, line) return "" end
    helper((str:gsub("(.-)\r?\n", helper)))
    return t
end


local function get_win_binary_path()
    local commandOutput = nil
    local result = nil

    local ver22Handle = io.popen("sc qc apache2.2")
    local ver22Result = ver22Handle:read("*a")
    ver22Handle:close()
    if string.find(ver22Result, "SUCCES") then commandOutput = ver22Result end

    local ver24Handle = io.popen("sc qc apache2.4")
    local ver24Result = ver24Handle:read("*a")
    ver24Handle:close()
    if string.find(ver24Result, "SUCCES") then commandOutput = ver24Result end

    if (commandOutput ~= nil) then
        local _lines = {}
        _lines = lines(commandOutput)
        for i=1,#_lines do
            if (string.find(_lines[i], "BINARY_PATH_NAME")) then
                for token in string.gmatch(_lines[i], "[^\"]+") do
                    if (string.find(token, ".exe")) then
                        result = string.gsub(string.sub(token, 0, -1), "\\", "/")
                        break
                    end
                end
            end

        end
    end
    return result
end


local function get_win_apache_root_directory(path)
    local i = string.find(path, "/bin")
    return string.sub(path, 0, i)
end


local function get_win_apache_properties(path)
    local serverVersion = nil
    local serverArchitecture = nil
    local serverConfigFile = nil
    local apacheProperties = {}
    local Handle = io.popen(path.." -V")
    local Result = Handle:read("*a")
    Handle:close()

    if (Result ~= nil) then
        local _lines = {}
        _lines = lines(Result)
        for i=1,#_lines do
            if (string.find(_lines[i], "Server version:")) then
                apacheProperties["serverVersion"] = string.sub(string.sub(_lines[i], 16):match( "^%s*(.+)" ), 8, -8)
            end
            if (string.find(_lines[i], "Architecture:")) then
                apacheProperties["serverArchitecture"] = string.sub(string.sub(_lines[i], 14):match( "^%s*(.+)" ), 0, -5)
            end
            if (string.find(_lines[i], "-D SERVER_CONFIG_FILE=")) then apacheProperties["serverConfigFile"]= string.sub(_lines[i], 25, -2)
            end
            i = i+1
        end
    end
    return apacheProperties
end


---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

pluginHelper.is64BitWinOSVersion = is64BitWinOSVersion
pluginHelper.isSupportedWinOSVersion = isSupportedWinOSVersion
pluginHelper.getOsName = getOsName
pluginHelper.downloadFile = downloadFile
pluginHelper.Extract = Extract
pluginHelper.get_win_binary_path = get_win_binary_path
pluginHelper.get_win_apache_properties = get_win_apache_properties
pluginHelper.get_win_apache_root_directory = get_win_apache_root_directory
pluginHelper.updateModuleConfFile = updateModuleConfFile
pluginHelper.updateHttpdConfFile = updateHttpdConfFile
pluginHelper.createBackupHttpdConfFile = createBackupHttpdConfFile
pluginHelper.winApacheRestart = winApacheRestart
pluginHelper.linuxApacheRestart = linuxApacheRestart



return pluginHelper