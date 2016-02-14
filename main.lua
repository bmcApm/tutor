--
-- Created by IntelliJ IDEA.
-- User: kavraham
-- Date: 1/28/2016
-- Time: 11:53 AM
-- To change this template use File | Settings | File Templates.
--

local _helper = require("pluginHelper")
local _windowsOS = require("windowsOS")
local _macOS = require("macOS")
local _linuxOS = require("linuxOS")



if (_helper.getOsName()) == "windows" then _windowsOS.execute() end
if (_helper.getOsName()) == "linux" then _macOS.execute() end
if (_helper.getOsName()) == "mac" then _linuxOS.execute() end


