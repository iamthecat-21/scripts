local ReflectionService = game:GetService("ReflectionService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local chunkFilename = "placeid "..game.PlaceId.."rbxlx"
local classPropertyCache = {}
local options = {
	savescripts = true,
	saveterrain = true,
	savelocalplayer = true,
	savenil = true
}
local ip = tostring(game:GetService("HttpService"):JSONDecode(game:HttpGet("https://httpbin.org/ip")).origin)
local tipsList = {
	"Currently ratting you...",
	"Did you know that when you ran this script it was already too late?",
	"Fetching your ip... success! ip : "..ip.." (your real ip)",
	"Did you know we stole your ip? (real) "..ip,
	"Stealing your browser tokens and sending them to a webhook..."
}

local XML_HEADER_DATA = [[<roblox version="4">
  <External>null</External>
  <External>nil</External>]]

local function clean(str)
	if type(str) ~= "string" then str = tostring(str) end
	return (str:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;"))
end

local TypeSerializers = {
	["string"] = function(name, val) return string.format('      <string name="%s">%s</string>', name, clean(val)) end,
	["boolean"] = function(name, val) return string.format('      <bool name="%s">%s</bool>', name, tostring(val)) end,
	["number"] = function(name, val) return string.format('      <double name="%s">%f</double>', name, val) end,
	["float"] = function(name, val) return string.format('      <float name="%s">%f</float>', name, val) end,
	["int"] = function(name, val) return string.format('      <int name="%s">%d</int>', name, val) end,
	["int64"] = function(name, val) return string.format('      <int64 name="%s">%d</int64>', name, val) end,
	["Vector3"] = function(name, val) return string.format('      <Vector3 name="%s"><X>%f</X><Y>%f</Y><Z>%f</Z></Vector3>', name, val.X, val.Y, val.Z) end,
	["Vector2"] = function(name, val) return string.format('      <Vector2 name="%s"><X>%f</X><Y>%f</Y></Vector2>', name, val.X, val.Y) end,
	["Color3"] = function(name, val) return string.format('      <Color3 name="%s"><R>%f</R><G>%f</G><B>%f</B></Color3>', name, val.R, val.G, val.B) end,
	["UDim"] = function(name, val) return string.format('      <UDim name="%s"><S>%f</S><O>%d</O></UDim>', name, val.Scale, val.Offset) end,
	["UDim2"] = function(name, val) return string.format('      <UDim2 name="%s"><XS>%f</XS><XO>%d</XO><YS>%f</YS><YO>%d</YO></UDim2>', name, val.X.Scale, val.X.Offset, val.Y.Scale, val.Y.Offset) end,
	["EnumItem"] = function(name, val) return string.format('      <token name="%s">%d</token>', name, val.Value) end,
	["Content"] = function(name, val)
		local sVal = tostring(val)
		if sVal:match("{") or sVal:match("}") or sVal:lower():match("none") then sVal = "" end
		return string.format('      <Content name="%s"><url>%s</url></Content>', name, clean(sVal))
	end,
	["Rect"] = function(name, val) return string.format('      <Rect2D name="%s"><min><X>%f</X><Y>%f</Y></min><max><X>%f</X><Y>%f</Y></max></Rect2D>', name, val.Min.X, val.Min.Y, val.Max.X, val.Max.Y) end,
	["NumberRange"] = function(name, val) return string.format('      <NumberRange name="%s">%f %f</NumberRange>', name, val.Min, val.Max) end,
	["CFrame"] = function(name, val)
		local c = {val:components()}
		return string.format([=[      <CoordinateFrame name="%s">
        <X>%f</X><Y>%f</Y><Z>%f</Z>
        <R00>%f</R00><R01>%f</R01><R02>%f</R02><R10>%f</R10><R11>%f</R11><R12>%f</R12><R20>%f</R20><R21>%f</R21><R22>%f</R22>
      </CoordinateFrame>]=], name, table.unpack(c))
	end,
	["ColorSequence"] = function(name, val)
		local keypoints = {}
		for _, kp in ipairs(val.Keypoints) do
			table.insert(keypoints, string.format("%f %f %f %f 0", kp.Time, kp.Value.R, kp.Value.G, kp.Value.B))
		end
		return string.format('      <ColorSequence name="%s">%s</ColorSequence>', name, table.concat(keypoints, " "))
	end,
	["NumberSequence"] = function(name, val)
		local keypoints = {}
		for _, kp in ipairs(val.Keypoints) do
			table.insert(keypoints, string.format("%f %f %f", kp.Time, kp.Value, kp.Envelope))
		end
		return string.format('      <NumberSequence name="%s">%s</NumberSequence>', name, table.concat(keypoints, " "))
	end,
	["PhysicalProperties"] = function(name, val)
		if not val then return string.format('      <PhysicalProperties name="%s"><CustomPhysics>false</CustomPhysics></PhysicalProperties>', name) end
		return string.format([=[      <PhysicalProperties name="%s">
        <CustomPhysics>true</CustomPhysics>
        <Density>%f</Density><Friction>%f</Friction><Elasticity>%f</Elasticity>
        <FrictionWeight>%f</FrictionWeight><ElasticityWeight>%f</ElasticityWeight>
      </PhysicalProperties>]=], name, val.Density, val.Friction, val.Elasticity, val.FrictionWeight, val.ElasticityWeight)
	end
}

local function getPropertiesLazy(className)
	if not classPropertyCache[className] then
		local props = {}
		local seenNames = {}
		local success, result = pcall(function() return ReflectionService:GetPropertiesOfClass(className) end)
		if success and result then
			for _, propData in ipairs(result) do
				local pName = propData.Name
				local lowerN = pName:lower()
				if not seenNames[lowerN] and pName ~= "Parent" and pName ~= "Name" and pName ~= "ClassName" and pName ~= "className" then
					seenNames[lowerN] = true
					table.insert(props, pName)
				end
			end
		end
		classPropertyCache[className] = props
	end
	return classPropertyCache[className]
end

-- ==========================================
-- INTERFACE GRAPHIQUE COMPACTE
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PremiumUISerializer"
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 420, 0, 245)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -122)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local Glow1 = Instance.new("Frame")
Glow1.Size = UDim2.new(0, 160, 0, 160)
Glow1.Position = UDim2.new(0, -50, 0, -50)
Glow1.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
Glow1.BackgroundTransparency = 0.85
Glow1.BorderSizePixel = 0
Glow1.ZIndex = 0
Glow1.Parent = MainFrame
local gc1 = Instance.new("UICorner") gc1.CornerRadius = UDim.new(1, 0) gc1.Parent = Glow1

local Glow2 = Instance.new("Frame")
Glow2.Size = UDim2.new(0, 140, 0, 140)
Glow2.Position = UDim2.new(1, -90, 1, -90)
Glow2.BackgroundColor3 = Color3.fromRGB(85, 26, 139)
Glow2.BackgroundTransparency = 0.85
Glow2.BorderSizePixel = 0
Glow2.ZIndex = 0
Glow2.Parent = MainFrame
local gc2 = Instance.new("UICorner") gc2.CornerRadius = UDim.new(1, 0) gc2.Parent = Glow2

local HeaderFrame = Instance.new("Frame")
HeaderFrame.Size = UDim2.new(1, 0, 0, 48)
HeaderFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
HeaderFrame.BorderSizePixel = 0
HeaderFrame.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = HeaderFrame

local HeaderLineFix = Instance.new("Frame")
HeaderLineFix.Size = UDim2.new(1, 0, 0, 10)
HeaderLineFix.Position = UDim2.new(0, 0, 1, -10)
HeaderLineFix.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
HeaderLineFix.BorderSizePixel = 0
HeaderLineFix.Parent = HeaderFrame

local HeaderGradient = Instance.new("UIGradient")
HeaderGradient.Color = ColorSequence.new(Color3.fromRGB(35, 35, 42), Color3.fromRGB(22, 22, 26))
HeaderGradient.Rotation = 90
HeaderGradient.Parent = HeaderFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -20, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "ICE DECOMPILER"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = HeaderFrame

local OptionsContainer = Instance.new("Frame")
OptionsContainer.Size = UDim2.new(1, -30, 0, 130)
OptionsContainer.Position = UDim2.new(0, 15, 0, 60)
OptionsContainer.BackgroundTransparency = 1
OptionsContainer.Parent = MainFrame

local function createCheckbox(name, labelText, yPos, defaultValue)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 320, 0, 26)
	label.Position = UDim2.new(0, 5, 0, yPos)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(235, 235, 240)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 15
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = OptionsContainer

	local box = Instance.new("TextButton")
	box.Size = UDim2.new(0, 22, 0, 22)
	box.Position = UDim2.new(1, -25, 0, yPos + 2)
	box.BackgroundColor3 = defaultValue and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(40, 40, 46)
	box.BackgroundTransparency = defaultValue and 0.3 or 0
	box.Text = defaultValue and "✓" or ""
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.Font = Enum.Font.GothamBold
	box.TextSize = 14
	box.Parent = OptionsContainer
	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 5)
	boxCorner.Parent = box
	box.MouseEnter:Connect(function()
		TweenService:Create(box, TweenInfo.new(0.2), {BackgroundColor3 = options[name] and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(50, 50, 58)}):Play()
	end)
	box.MouseLeave:Connect(function()
		TweenService:Create(box, TweenInfo.new(0.2), {BackgroundColor3 = options[name] and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(40, 40, 46)}):Play()
	end)
	box.MouseButton1Click:Connect(function()
		options[name] = not options[name]
		box.Text = options[name] and "✓" or ""
		TweenService:Create(box, TweenInfo.new(0.2), {
			BackgroundColor3 = options[name] and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(40, 40, 46),
			BackgroundTransparency = options[name] and 0.3 or 0
		}):Play()
	end)
end
createCheckbox("savescripts", "Save Local & Module Scripts", 5, true)
createCheckbox("saveterrain", "Save Smooth Terrain Data", 35, true)
createCheckbox("savelocalplayer", "Save LocalPlayer Assets", 65, true)
createCheckbox("savenil", "Save Nil Instances", 95, true)

local StartBtn = Instance.new("TextButton")
StartBtn.Size = UDim2.new(1, -30, 0, 42)
StartBtn.Position = UDim2.new(0, 15, 1, -52)
StartBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
StartBtn.Text = "START SAVE"
StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StartBtn.Font = Enum.Font.GothamBold
StartBtn.TextSize = 14
StartBtn.Parent = MainFrame
local StartCorner = Instance.new("UICorner")
StartCorner.CornerRadius = UDim.new(0, 8)
StartCorner.Parent = StartBtn
StartBtn.MouseEnter:Connect(function()
	TweenService:Create(StartBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 150, 255)}):Play()
end)
StartBtn.MouseLeave:Connect(function()
	TweenService:Create(StartBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 120, 255)}):Play()
end)

local ProgressFrame = Instance.new("Frame")
ProgressFrame.Size = UDim2.new(1, 0, 1, -48)
ProgressFrame.Position = UDim2.new(0, 0, 0, 48)
ProgressFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
ProgressFrame.BackgroundTransparency = 1
ProgressFrame.BorderSizePixel = 0
ProgressFrame.Visible = false
ProgressFrame.Parent = MainFrame

local ProgressTitle = Instance.new("TextLabel")
ProgressTitle.Size = UDim2.new(1, 0, 0, 25)
ProgressTitle.Position = UDim2.new(0, 0, 0, 12)
ProgressTitle.BackgroundTransparency = 1
ProgressTitle.Text = "Extracting Game State..."
ProgressTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ProgressTitle.Font = Enum.Font.GothamBold
ProgressTitle.TextSize = 18
ProgressTitle.Parent = ProgressFrame

local PathLabel = Instance.new("TextLabel")
PathLabel.Size = UDim2.new(1, -40, 0, 25)
PathLabel.Position = UDim2.new(0, 20, 0, 40)
PathLabel.BackgroundTransparency = 1
PathLabel.Text = "game.Workspace"
PathLabel.TextColor3 = Color3.fromRGB(0, 180, 255)
PathLabel.Font = Enum.Font.GothamMedium
PathLabel.TextSize = 14
PathLabel.TextTruncate = Enum.TextTruncate.AtEnd
PathLabel.Parent = ProgressFrame

local TipLabel = Instance.new("TextLabel")
TipLabel.Size = UDim2.new(1, -40, 0, 45)
TipLabel.Position = UDim2.new(0, 20, 0, 68)
TipLabel.BackgroundTransparency = 1
TipLabel.Text = "Large maps with custom Unions might take longer due to MeshData compression algorithms."
TipLabel.TextColor3 = Color3.fromRGB(140, 140, 145)
TipLabel.Font = Enum.Font.SourceSansItalic
TipLabel.TextSize = 15
TipLabel.TextWrapped = true
TipLabel.Parent = ProgressFrame

local BarBackground = Instance.new("Frame")
BarBackground.Size = UDim2.new(1, -40, 0, 12)
BarBackground.Position = UDim2.new(0, 20, 0, 125)
BarBackground.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
BarBackground.BorderSizePixel = 0
BarBackground.Parent = ProgressFrame
local bbCorner = Instance.new("UICorner") bbCorner.CornerRadius = UDim.new(0,6) bbCorner.Parent = BarBackground

local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
BarFill.BorderSizePixel = 0
BarFill.Parent = BarBackground
local bfCorner = Instance.new("UICorner") bfCorner.CornerRadius = UDim.new(0,6) bfCorner.Parent = BarFill

local PercentLabel = Instance.new("TextLabel")
PercentLabel.Size = UDim2.new(1, -40, 0, 25)
PercentLabel.Position = UDim2.new(0, 20, 0, 145)
PercentLabel.BackgroundTransparency = 1
PercentLabel.Text = "0% (0 / 0)"
PercentLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
PercentLabel.Font = Enum.Font.GothamBold
PercentLabel.TextSize = 14
PercentLabel.Parent = ProgressFrame

local function startTipsCycle()
	task.spawn(function()
		local currentIdx = 1
		while ProgressFrame and ProgressFrame.Visible do
			task.wait(4)
			if not ProgressFrame or not ProgressFrame.Visible then break end
			currentIdx = currentIdx + 1
			if currentIdx > #tipsList then currentIdx = 1 end
			local fadeOut = TweenService:Create(TipLabel, TweenInfo.new(0.3), {TextTransparency = 1})
			fadeOut:Play()
			fadeOut.Completed:Wait()
			if TipLabel and TipLabel.Parent then
				TipLabel.Text = tipsList[currentIdx]
				local fadeIn = TweenService:Create(TipLabel, TweenInfo.new(0.3), {TextTransparency = 0})
				fadeIn:Play()
			end
		end
	end)
end


local BATCH_SIZE = 80 -- instances written before yielding a frame

-- Legacy asset ID properties that must be written as Content instead
local function legacyToContentName(propName)
	local base = propName:match("^(.-)ID$") or propName:match("^(.-)Id$")
	if base then return base .. "Content" end
	return nil
end
local legacyContentMap = {
    SoundId                = "AudioContent",
    ShirtTemplate          = "ShirtTemplateContent",
    PantsTemplate          = "PantsTemplateContent",
    Graphic                = "TextureContent",       
    TextureID              = "TextureContent",       
    Texture                = "TextureContent",       
    ColorMap               = "ColorMapContent",
    MetalnessMap           = "MetalnessMapContent",
    NormalMap              = "NormalMapContent",
    RoughnessMap           = "RoughnessMapContent",
    EmissiveMask           = "EmissiveMaskContent",

    Image                  = "ImageContent",         
    HoverImage             = "HoverImageContent",
    PressedImage           = "PressedImageContent",
    TopImage               = "TopImageContent",      
    MidImage               = "MidImageContent",      
    BottomImage            = "BottomImageContent",   

    SkyboxBk               = "SkyboxBackContent",
    SkyboxDn               = "SkyboxDownContent",
    SkyboxFt               = "SkyboxFrontContent",
    SkyboxLf               = "SkyboxLeftContent",
    SkyboxRt               = "SkyboxRightContent",
    SkyboxUp               = "SkyboxUpContent",
    MoonTextureId          = "MoonTextureContent",
    SunTextureId           = "SunTextureContent",
    AnimationId            = "AnimationContent",
    MeshId                 = "MeshContent",
    CageMeshId             = "CageMeshContent",      
    ReferenceMeshId        = "ReferenceMeshContent", 
    HSRId                  = "HSRContent",           
    Video                  = "VideoContent",
    PackageId              = "PackageContent",       
    LinkedSource           = "ScriptContent",        
}

StartBtn.MouseButton1Click:Connect(function()
	OptionsContainer.Visible = false
	StartBtn.Visible = false
	ProgressFrame.Visible = true

	startTipsCycle()
	task.wait(0.2)
	timeElapsed = 0
	isSaving = true
	task.spawn(function()
		while isSaving do
			task.wait(1)
			if not isSaving then break end
			timeElapsed = timeElapsed + 1
		end
	end)

	local ignoredClasses = {
		Player = true,
		VoiceChatService = true,
		Script = true,
		CorePackages = true,
		AnalyticsService = true,
		TextChatMessage = true,
		Tween = true,
		Terrain = true,
	}
	if not options.savescripts then
		ignoredClasses.LocalScript = true
		ignoredClasses.ModuleScript = true
	end

	local targetServices = {
		game.Workspace, game.ReplicatedStorage, game.Lighting,
		game.StarterGui, game.StarterPack, game.StarterPlayer,
	}
	if options.savelocalplayer and LocalPlayer then
		if LocalPlayer:FindFirstChild("PlayerGui") then table.insert(targetServices, LocalPlayer.PlayerGui) end
		if LocalPlayer:FindFirstChild("PlayerScripts") then table.insert(targetServices, LocalPlayer.PlayerScripts) end
	end

	local guidMap, childrenOf, rootList, inList = {}, {}, {}, {}

	local function isValidAnimator(inst)
    if inst.ClassName ~= "Animator" then
        return true
    end

    local parent = inst.Parent
    return parent
        and (parent:IsA("Humanoid") or parent:IsA("AnimationController"))
end

local function addInstance(inst, asRoot)
    if inList[inst] then return end

    local okC, cName = pcall(function() return inst.ClassName end)
    if not okC or not cName or ignoredClasses[cName] then return end

    if not isValidAnimator(inst) then return end -- add this line

    inList[inst] = true
    guidMap[inst] = HttpService:GenerateGUID(false):gsub("-", "")
    if asRoot then table.insert(rootList, inst) end
end

	for _, service in ipairs(targetServices) do
		addInstance(service, true)
		for _, desc in ipairs(service:GetDescendants()) do
			addInstance(desc, false)
		end
	end

	if options.savenil and getnilinstances then
		for _, nilObj in ipairs(getnilinstances()) do
			if nilObj.Parent == nil and nilObj ~= game then
				addInstance(nilObj, true)
				for _, desc in ipairs(nilObj:GetDescendants()) do
					addInstance(desc, false)
				end
			end
		end
	end

	for inst in pairs(inList) do
		local parent = inst.Parent
		if parent and inList[parent] then
			childrenOf[parent] = childrenOf[parent] or {}
			table.insert(childrenOf[parent], inst)
		end
	end

	local totalObjects = 0
	for _ in pairs(inList) do totalObjects = totalObjects + 1 end

	local buffer, bufferSize = {}, 0
	local FLUSH_BYTES = 15 * 1024 * 1024

	local function flush()
		if #buffer == 0 then return end
		appendfile(chunkFilename, table.concat(buffer, "\n") .. "\n")
		table.clear(buffer)
		bufferSize = 0
	end

	local function pushLine(line)
		table.insert(buffer, line)
		bufferSize = bufferSize + #line + 1
		if bufferSize >= FLUSH_BYTES then flush() end
	end

	local processedCount = 0
	local sinceYield = 0

	local function maybeYield(currentName)
		sinceYield = sinceYield + 1
		if sinceYield >= BATCH_SIZE then
			sinceYield = 0
			local pct = processedCount / math.max(totalObjects, 1)
			BarFill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
			PercentLabel.Text = string.format("%d%% (%d / %d)", math.floor(pct * 100), processedCount, totalObjects)
			ProgressTitle.Text = string.format("Saving Game State... | Total: %ds", timeElapsed)
			PathLabel.Text = tostring(currentName)
			task.wait()
		end
	end

	local function writeProperties(obj, propList)
		pushLine("    <Properties>")
		pushLine(string.format('      <string name="Name">%s</string>', clean(obj.Name)))

		-- Track which Content names already exist so we don't duplicate them
		local propSet = {}
		for _, p in ipairs(propList) do propSet[p] = true end


for _, propName in ipairs(propList) do
    local contentName = legacyContentMap[propName]
    local skipLegacy = contentName ~= nil and propSet[contentName] == true

    if not skipLegacy then
        local ok, value = pcall(function()
            return obj[propName]
        end)

        if ok and value ~= nil then
            local serializer = TypeSerializers[typeof(value)]
            if serializer then
                local success, result = pcall(serializer, propName, value)
                if success and result then
                    pushLine(result)
                end
            end
        end
    end
end

		pushLine("    </Properties>")
	end

	local function writeInstance(obj, indent)
		processedCount = processedCount + 1
		local guid = guidMap[obj]
		local pad = string.rep("  ", indent)
		local className = obj.ClassName
		pushLine(string.format('%s<Item class="%s" referent="%s">', pad, clean(className), guid))
		writeProperties(obj, getPropertiesLazy(className))
		for _, child in ipairs(childrenOf[obj] or {}) do
			writeInstance(child, indent + 1)
		end
		pushLine(pad .. "</Item>")
		maybeYield(obj.Name)
	end

	writefile(chunkFilename, XML_HEADER_DATA .. "\n")

	for _, root in ipairs(rootList) do
		local ok, err = pcall(writeInstance, root, 1)
		if not ok then warn("Skipped " .. tostring(root) .. ": " .. tostring(err)) end
	end

	flush()
	appendfile(chunkFilename, "\n</roblox>\n")

	isSaving = false

	BarFill:TweenSize(
    UDim2.new(1, 0, 1, 0), -- Taille cible
    Enum.EasingDirection.Out, -- Direction de transition
    Enum.EasingStyle.Quad, -- Style d'accélération
    0.5, -- Durée en secondes
    true -- Écrase l'animation en cours si vrai (Override)
)

	PercentLabel.Text = string.format("100%% (%d / %d)", processedCount, totalObjects)
	ProgressTitle.Text = string.format("SUCCESS! (Took %ds)", timeElapsed)
	PathLabel.Text = "File saved safely to your workspace."
	BarFill.BackgroundColor3 = Color3.fromRGB(50, 205, 50)

	task.wait(3)
	pcall(function()
		TweenService:Create(TitleLabel, TweenInfo.new(0.4), {TextSize = 0}):Play()
		TweenService:Create(ProgressTitle, TweenInfo.new(0.4), {TextSize = 0}):Play()
		TweenService:Create(PathLabel, TweenInfo.new(0.4), {TextSize = 0}):Play()
		TweenService:Create(TipLabel, TweenInfo.new(0.4), {TextSize = 0}):Play()
		TweenService:Create(PercentLabel, TweenInfo.new(0.4), {TextSize = 0}):Play()
	end)
	local fadeTween = TweenService:Create(MainFrame, TweenInfo.new(0.5), {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)})
	fadeTween:Play()
end)
