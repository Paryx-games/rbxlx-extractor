local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

-- These are the services we want to extract from the place file
-- You can modify this list to include services as needed. Keep in mind that StarterPlayer includes
-- starterplayerscripts and startercharacterscripts as children, which are handled separately.
local SERVICES_TO_EXTRACT = {
	"Workspace",
	"Lighting",
	"ReplicatedFirst",
	"ReplicatedStorage",
	"ServerScriptService",
	"ServerStorage",
	"StarterGui",
	"StarterPack",
	"StarterPlayer",
	"SoundService",
}

-- You can remove one of these if you don't want to extract both
-- You must extract StarterPlayer itself first before extracting these children
local STARTER_PLAYER_CHILDREN = {
	"StarterPlayerScripts",
	"StarterCharacterScripts",
}

-- ANSI color codes for terminal output
-- You can customize these colors as desired
local COLORS = {
	reset = "\27[0m",
	red = "\27[91m",
	green = "\27[92m",
	yellow = "\27[93m",
	blue = "\27[94m",
	magenta = "\27[95m",
	cyan = "\27[96m",
	white = "\27[97m",
	orange = "\27[38;5;214m",
	gold = "\27[38;5;226m",
	purple = "\27[38;5;177m",
	pink = "\27[38;5;219m",
	lime = "\27[38;5;155m",
}

local function color(text: string, colorCode: string): string
	return colorCode .. text .. COLORS.reset
end

local currentPath = ""

local function progressBar(current: number, total: number, label: string, barColor: string)
	local width = 40
	local percent = math.min(current / total, 1.0)
	local filled = math.floor(width * percent)
	local empty = width - filled

	local bar = string.rep("█", filled) .. string.rep("░", empty)
	local percentText = string.format("%.1f%%", percent * 100)

	local pathDisplay = currentPath
	if #pathDisplay > 80 then
		pathDisplay = "..." .. string.sub(pathDisplay, -77)
	end

	stdio.write("\27[2K\r")

	stdio.write(
		color(label .. " ", barColor)
			.. "["
			.. color(bar, barColor)
			.. "] "
			.. color(percentText, COLORS.cyan)
			.. " "
			.. color(pathDisplay, COLORS.white)
	)

	if current >= total then
		print()
	end
end

local function findRbxlx(): string?
	local dirsToCheck = { ".", "extraction", "../extraction" }

	for _, dir in dirsToCheck do
		local success, files = pcall(function()
			return fs.readDir(dir)
		end)

		if success and files then
			for _, file in files do
				if file:match("%.rbxlx$") then
					return dir .. "/" .. file
				end
			end
		end
	end

	return nil
end

local function ensureDir(path: string)
	local parts = string.split(path, "/")
	local current = ""
	for i = 1, #parts do
		current = current .. parts[i]
		if not fs.isDir(current) then
			fs.writeDir(current)
		end
		if i < #parts then
			current = current .. "/"
		end
	end
end

local function serializeProperties(instance: Instance): { [string]: any }
	local properties = {}
	local success, result = pcall(function()
		return roblox.getProperties(instance)
	end)
	if success and result then
		for key, value in result do
			if key ~= "Parent" and key ~= "Name" then
				properties[key] = value
			end
		end
	end
	return properties
end

local function serializeAttributes(instance: Instance): { [string]: any }
	local attributes = {}
	local success, result = pcall(function()
		return roblox.getAttributes(instance)
	end)
	if success and result then
		for key, value in result do
			attributes[key] = value
		end
	end
	return attributes
end

local function writeProjectFile(basePath: string, instance: Instance, className: string)
	ensureDir(basePath)

	local properties = serializeProperties(instance)
	local attributes = serializeAttributes(instance)

	if next(properties) or next(attributes) then
		local projectData: any = {}

		if next(properties) then
			projectData.properties = properties
		end

		if next(attributes) then
			projectData.attributes = attributes
		end

		local initPath = basePath .. "/init.meta.json"
		fs.writeFile(initPath, serde.encode("json", projectData, true))
	end
end

local itemsProcessed = 0
local totalItems = 0

local function countInstances(instance: Instance): number
	local count = 0
	for _, child in instance:GetChildren() do
		count = count + 1 + countInstances(child)
	end
	return count
end

local function extractInstance(instance: Instance, path: string, serviceName: string)
	ensureDir(path)

	local children = instance:GetChildren()
	for _, child in children do
		local childName = child.Name
		local childPath = path .. "/" .. childName
		local className = child.ClassName

		currentPath = childPath
		itemsProcessed = itemsProcessed + 1
		progressBar(itemsProcessed, totalItems, "Extracting " .. serviceName, COLORS.cyan)

		if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") then
			local ext = ".luau"
			if className == "LocalScript" then
				ext = ".client.luau"
			elseif className == "Script" then
				ext = ".server.luau"
			end

			local success, source = pcall(function()
				return child.Source
			end)

			if success and source then
				fs.writeFile(childPath .. ext, source)
			else
				fs.writeFile(childPath .. ext, "")
			end

			local props = serializeProperties(child)
			local attrs = serializeAttributes(child)
			if next(props) or next(attrs) then
				local metaData: any = {}
				if next(props) then
					metaData["properties"] = props
				end
				if next(attrs) then
					metaData["attributes"] = attrs
				end
				fs.writeFile(childPath .. ".meta.json", serde.encode("json", metaData, true))
			end
		else
			ensureDir(childPath)

			local props = serializeProperties(child)
			local attrs = serializeAttributes(child)
			local hasMetadata = next(props) ~= nil or next(attrs) ~= nil

			if hasMetadata then
				local metaData: any = {
					className = className,
				}
				if next(props) then
					metaData["properties"] = props
				end
				if next(attrs) then
					metaData["attributes"] = attrs
				end
				fs.writeFile(childPath .. ".meta.json", serde.encode("json", metaData, true))
			end

			extractInstance(child, childPath, serviceName)
		end
	end
end

local function extractService(dataModel: Instance, serviceName: string, outputPath: string)
	local service = dataModel:FindFirstChild(serviceName)
	if not service then
		print(color(`[!] Service {serviceName} not found in place file`, COLORS.orange))
		return
	end

	totalItems = countInstances(service)
	itemsProcessed = 0
	currentPath = ""

	writeProjectFile(outputPath, service, serviceName)

	if totalItems > 0 then
		extractInstance(service, outputPath, serviceName)
		progressBar(totalItems, totalItems, "Extracting " .. serviceName, COLORS.cyan)
	else
		progressBar(1, 1, "Extracting " .. serviceName, COLORS.cyan)
	end

	print(color(`[✓] {serviceName} extracted\n`, COLORS.lime))
end

local function main()
	print(color("[>] Scanning for .rbxlx file...", COLORS.blue))
	local rbxlxPath = findRbxlx()

	if not rbxlxPath then
		print(color("[X] No .rbxlx file found in extraction/ folder", COLORS.red))
		process.exit(1)
	end

	print(color(`[>] Found: {rbxlxPath}`, COLORS.green))
	print(color("[>] Reading place file...", COLORS.purple))

	local placeData = fs.readFile(rbxlxPath)

	print(color("[>] Deserializing place file...", COLORS.magenta))
	local dataModel = roblox.deserializePlace(placeData)

	print(color("\n[>] Starting extraction...\n", COLORS.magenta))

	local srcPath = "../src"
	if fs.isDir(srcPath) then
		print(color("[>] Removing old src/ directory...", COLORS.yellow))
		fs.removeDir(srcPath)
	end

	for _, serviceName in SERVICES_TO_EXTRACT do
		local outputPath = srcPath .. "/" .. serviceName

		if serviceName == "StarterPlayer" then
			extractService(dataModel, serviceName, outputPath)

			local starterPlayer = dataModel:FindFirstChild("StarterPlayer")
			if starterPlayer then
				for _, childServiceName in STARTER_PLAYER_CHILDREN do
					local childService = starterPlayer:FindFirstChild(childServiceName)
					if childService then
						local childPath = outputPath .. "/" .. childServiceName

						totalItems = countInstances(childService)
						itemsProcessed = 0
						currentPath = ""

						writeProjectFile(childPath, childService, childServiceName)

						if totalItems > 0 then
							extractInstance(childService, childPath, `StarterPlayer/{childServiceName}`)
							progressBar(
								totalItems,
								totalItems,
								`Extracting StarterPlayer/{childServiceName}`,
								COLORS.cyan
							)
						else
							progressBar(1, 1, `Extracting StarterPlayer/{childServiceName}`, COLORS.cyan)
						end

						print(color(`[✓] StarterPlayer/{childServiceName} extracted\n`, COLORS.lime))
					end
				end
			end
		else
			extractService(dataModel, serviceName, outputPath)
		end
	end

	print(color("\n[✓] Extraction complete!", COLORS.gold))
end

main()
