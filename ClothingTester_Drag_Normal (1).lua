--========================================================
-- CLOTHING TESTER
-- SEARCH PAR ID
-- SAVED OUTFITS
-- HEADLESS
-- RESET / RESPAWN : VÊTEMENTS CONSERVÉS
-- LOCAL SCRIPT UNIQUEMENT
--========================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--========================================================
-- ACCÈS PRIVÉ
--========================================================

local ALLOWED_USER_ID = 8531489247

if player.UserId ~= ALLOWED_USER_ID then
	return
end

--========================================================
-- CONFIG
--========================================================

local NPC_NAME = "ClothingNPC"

--========================================================
-- DONNÉES
--========================================================

local savedOutfits = {}

local originalShirt = nil
local originalPants = nil

-- Vêtements actuellement équipés
-- Ils servent à les remettre après un RESET.
local equippedShirtID = nil
local equippedPantsID = nil

local selectedSearchType = "Shirt"

local currentItemID = nil
local currentItemType = "Shirt"

local headlessEnabled = false

local refreshOutfits

--========================================================
-- OUTILS
--========================================================

local function addCorner(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = object
end

local function createButton(parent, text, position, size, color)
	local button = Instance.new("TextButton")

	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0

	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 14
	button.Font = Enum.Font.GothamBold

	button.AutoButtonColor = true
	button.Parent = parent

	addCorner(button, 8)

	return button
end

local function createTextBox(parent, name, placeholder, position, size)
	local box = Instance.new("TextBox")

	box.Name = name
	box.Size = size
	box.Position = position

	box.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	box.BorderSizePixel = 0

	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)

	box.Text = ""
	box.TextColor3 = Color3.new(1, 1, 1)
	box.TextSize = 15
	box.Font = Enum.Font.Gotham

	box.ClearTextOnFocus = false

	box.Parent = parent

	addCorner(box, 8)

	return box
end

local function cleanID(id)
	id = tostring(id or "")

	id = id:gsub("rbxassetid://", "")
	id = id:gsub("%s+", "")

	if id == "" then
		return nil
	end

	if not tonumber(id) then
		return nil
	end

	return tonumber(id)
end

local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

--========================================================
-- GUI
--========================================================

local gui = Instance.new("ScreenGui")

gui.Name = "ClothingTesterGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

gui.Parent = playerGui

--========================================================
-- TOP BAR
--========================================================

local topBar = Instance.new("Frame")

topBar.Name = "TopBar"
topBar.Size = UDim2.fromOffset(635, 50)
topBar.Position = UDim2.new(0.5, -317, 0, 10)

topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
topBar.BorderSizePixel = 0

topBar.Parent = gui

addCorner(topBar, 12)

--========================================================
-- TOP BUTTONS
--========================================================

local clothingToggle = createButton(
	topBar,
	"CLOTHING",
	UDim2.fromOffset(5, 5),
	UDim2.fromOffset(155, 40),
	Color3.fromRGB(55, 110, 180)
)

local searchToggle = createButton(
	topBar,
	"SEARCH",
	UDim2.fromOffset(170, 5),
	UDim2.fromOffset(155, 40),
	Color3.fromRGB(60, 130, 90)
)

local savedToggle = createButton(
	topBar,
	"SAVED OUTFITS",
	UDim2.fromOffset(335, 5),
	UDim2.fromOffset(160, 40),
	Color3.fromRGB(90, 70, 150)
)

local headlessToggle = createButton(
	topBar,
	"HEADLESS",
	UDim2.fromOffset(500, 5),
	UDim2.fromOffset(130, 40),
	Color3.fromRGB(110, 70, 70)
)

--========================================================
-- CLOTHING WINDOW
--========================================================

local clothing = Instance.new("Frame")

clothing.Name = "Clothing"
clothing.Size = UDim2.fromOffset(400, 430)
clothing.Position = UDim2.new(0.5, -430, 0.5, -215)

clothing.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
clothing.BorderSizePixel = 0

clothing.Parent = gui

addCorner(clothing, 15)

--========================================================
-- CLOTHING TITLE
--========================================================

local clothingTitle = Instance.new("TextLabel")

clothingTitle.Size = UDim2.new(1, -70, 0, 75)
clothingTitle.Position = UDim2.fromOffset(20, 5)

clothingTitle.BackgroundTransparency = 1
clothingTitle.Text = "CLOTHING"

clothingTitle.TextColor3 = Color3.new(1, 1, 1)
clothingTitle.TextSize = 24
clothingTitle.Font = Enum.Font.GothamBold

clothingTitle.TextXAlignment = Enum.TextXAlignment.Left

clothingTitle.Parent = clothing

--========================================================
-- CLOSE CLOTHING
--========================================================

local closeClothing = createButton(
	clothing,
	"X",
	UDim2.new(1, -50, 0, 10),
	UDim2.fromOffset(40, 40),
	Color3.fromRGB(160, 55, 55)
)

--========================================================
-- SHIRT
--========================================================

local shirtLabel = Instance.new("TextLabel")

shirtLabel.Size = UDim2.fromOffset(250, 25)
shirtLabel.Position = UDim2.fromOffset(20, 60)

shirtLabel.BackgroundTransparency = 1
shirtLabel.Text = "👕 SHIRT"

shirtLabel.TextColor3 = Color3.new(1, 1, 1)
shirtLabel.TextSize = 17
shirtLabel.Font = Enum.Font.GothamBold

shirtLabel.TextXAlignment = Enum.TextXAlignment.Left

shirtLabel.Parent = clothing

local shirtBox = createTextBox(
	clothing,
	"ShirtID",
	"Shirt ID",
	UDim2.fromOffset(20, 88),
	UDim2.fromOffset(250, 40)
)

local shirtTemplateBox = createTextBox(
	clothing,
	"ShirtTemplateID",
	"Decal Shirt ID",
	UDim2.fromOffset(20, 133),
	UDim2.fromOffset(250, 40)
)

--========================================================
-- PANTS
--========================================================

local pantsLabel = Instance.new("TextLabel")

pantsLabel.Size = UDim2.fromOffset(250, 25)
pantsLabel.Position = UDim2.fromOffset(20, 178)

pantsLabel.BackgroundTransparency = 1
pantsLabel.Text = "👖 PANTS"

pantsLabel.TextColor3 = Color3.new(1, 1, 1)
pantsLabel.TextSize = 17
pantsLabel.Font = Enum.Font.GothamBold

pantsLabel.TextXAlignment = Enum.TextXAlignment.Left

pantsLabel.Parent = clothing

local pantsBox = createTextBox(
	clothing,
	"PantsID",
	"Pants ID",
	UDim2.fromOffset(20, 206),
	UDim2.fromOffset(250, 40)
)

local pantsTemplateBox = createTextBox(
	clothing,
	"PantsTemplateID",
	"Decal Pants ID",
	UDim2.fromOffset(20, 251),
	UDim2.fromOffset(250, 40)
)

--========================================================
-- EQUIP / UNEQUIP
--========================================================

local equipButton = createButton(
	clothing,
	"EQUIP",
	UDim2.fromOffset(20, 305),
	UDim2.fromOffset(250, 42),
	Color3.fromRGB(45, 140, 70)
)

local unequipButton = createButton(
	clothing,
	"UNEQUIP",
	UDim2.fromOffset(20, 355),
	UDim2.fromOffset(250, 42),
	Color3.fromRGB(150, 55, 55)
)

--========================================================
-- SEARCH WINDOW
--========================================================

local search = Instance.new("Frame")

search.Name = "Search"
search.Size = UDim2.fromOffset(430, 520)
search.Position = UDim2.new(0.5, -215, 0.5, -260)

search.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
search.BorderSizePixel = 0

search.Parent = gui

addCorner(search, 15)

--========================================================
-- SEARCH TITLE
--========================================================

local searchTitle = Instance.new("TextLabel")

searchTitle.Size = UDim2.new(1, -70, 0, 75)
searchTitle.Position = UDim2.fromOffset(20, 5)

searchTitle.BackgroundTransparency = 1
searchTitle.Text = "🔎 SEARCH ITEM"

searchTitle.TextColor3 = Color3.new(1, 1, 1)
searchTitle.TextSize = 23
searchTitle.Font = Enum.Font.GothamBold

searchTitle.TextXAlignment = Enum.TextXAlignment.Left

searchTitle.Parent = search

--========================================================
-- CLOSE SEARCH
--========================================================

local closeSearch = createButton(
	search,
	"X",
	UDim2.new(1, -50, 0, 10),
	UDim2.fromOffset(40, 40),
	Color3.fromRGB(160, 55, 55)
)

--========================================================
-- SEARCH TYPE
--========================================================

local typeLabel = Instance.new("TextLabel")

typeLabel.Size = UDim2.fromOffset(300, 25)
typeLabel.Position = UDim2.fromOffset(20, 65)

typeLabel.BackgroundTransparency = 1
typeLabel.Text = "TYPE D'ITEM"

typeLabel.TextColor3 = Color3.new(1, 1, 1)
typeLabel.TextSize = 15
typeLabel.Font = Enum.Font.GothamBold

typeLabel.TextXAlignment = Enum.TextXAlignment.Left

typeLabel.Parent = search

local shirtTypeButton = createButton(
	search,
	"👕 SHIRT",
	UDim2.fromOffset(20, 95),
	UDim2.fromOffset(185, 40),
	Color3.fromRGB(55, 110, 180)
)

local pantsTypeButton = createButton(
	search,
	"👖 PANTS",
	UDim2.fromOffset(215, 95),
	UDim2.fromOffset(185, 40),
	Color3.fromRGB(65, 65, 65)
)

--========================================================
-- SEARCH ID
--========================================================

local idBox = createTextBox(
	search,
	"SearchID",
	"Entre l'Asset / Texture ID...",
	UDim2.fromOffset(20, 150),
	UDim2.fromOffset(380, 45)
)

local searchButton = createButton(
	search,
	"🔎 RECHERCHER",
	UDim2.fromOffset(20, 205),
	UDim2.fromOffset(380, 42),
	Color3.fromRGB(55, 130, 85)
)

--========================================================
-- SEARCH PREVIEW
--========================================================

local preview = Instance.new("ImageLabel")

preview.Size = UDim2.fromOffset(180, 180)
preview.Position = UDim2.new(0.5, -90, 0, 265)

preview.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
preview.BorderSizePixel = 0

preview.Image = ""
preview.ScaleType = Enum.ScaleType.Fit

preview.Parent = search

addCorner(preview, 12)

--========================================================
-- SEARCH RESULT
--========================================================

local resultLabel = Instance.new("TextLabel")

resultLabel.Size = UDim2.fromOffset(380, 35)
resultLabel.Position = UDim2.fromOffset(20, 250)

resultLabel.BackgroundTransparency = 1
resultLabel.Text = "Aucun item sélectionné"

resultLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
resultLabel.TextSize = 15
resultLabel.Font = Enum.Font.GothamBold

resultLabel.TextXAlignment = Enum.TextXAlignment.Center

resultLabel.Parent = search

--========================================================
-- SEARCH BUTTONS
--========================================================

local tryItemButton = createButton(
	search,
	"⚡ ESSAYER",
	UDim2.fromOffset(20, 465),
	UDim2.fromOffset(185, 40),
	Color3.fromRGB(45, 140, 70)
)

local loadItemButton = createButton(
	search,
	"CHARGER",
	UDim2.fromOffset(215, 465),
	UDim2.fromOffset(185, 40),
	Color3.fromRGB(70, 80, 150)
)

--========================================================
-- SAVED OUTFITS
--========================================================

local saved = Instance.new("Frame")

saved.Name = "SavedOutfits"
saved.Size = UDim2.fromOffset(500, 600)
saved.Position = UDim2.new(1, -520, 0.5, -300)

saved.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
saved.BorderSizePixel = 0

saved.Active = true
saved.Parent = gui

addCorner(saved, 15)

--========================================================
-- SAVED TITLE
--========================================================

local savedTitle = Instance.new("TextLabel")

savedTitle.Size = UDim2.new(1, -70, 0, 75)
savedTitle.Position = UDim2.fromOffset(20, 5)

savedTitle.BackgroundTransparency = 1
savedTitle.Text = "💾 SAVED OUTFITS"

savedTitle.TextColor3 = Color3.new(1, 1, 1)
savedTitle.TextSize = 23
savedTitle.Font = Enum.Font.GothamBold

savedTitle.TextXAlignment = Enum.TextXAlignment.Left

savedTitle.Parent = saved

--========================================================
-- CLOSE SAVED
--========================================================

local closeSaved = createButton(
	saved,
	"X",
	UDim2.new(1, -50, 0, 10),
	UDim2.fromOffset(40, 40),
	Color3.fromRGB(160, 55, 55)
)

--========================================================
-- SAVE BUTTON
--========================================================

local saveButton = createButton(
	saved,
	"+ SAUVEGARDER LA TENUE",
	UDim2.fromOffset(20, 65),
	UDim2.new(1, -40, 0, 42),
	Color3.fromRGB(55, 110, 180)
)

--========================================================
-- OUTFIT LIST
--========================================================

local list = Instance.new("ScrollingFrame")

list.Name = "OutfitList"
list.Size = UDim2.new(1, -30, 1, -125)
list.Position = UDim2.fromOffset(15, 120)

list.BackgroundTransparency = 1
list.BorderSizePixel = 0

list.ScrollBarThickness = 6
list.ScrollingDirection = Enum.ScrollingDirection.Y
list.ScrollingEnabled = true

list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.AutomaticCanvasSize = Enum.AutomaticSize.Y

list.Parent = saved

local layout = Instance.new("UIListLayout")

layout.Padding = UDim.new(0, 10)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

layout.Parent = list

local empty = Instance.new("TextLabel")

empty.Size = UDim2.new(1, -20, 0, 60)

empty.BackgroundTransparency = 1
empty.Text = "Aucune tenue sauvegardée"

empty.TextColor3 = Color3.fromRGB(150, 150, 150)
empty.TextSize = 16
empty.Font = Enum.Font.Gotham

empty.Parent = list

--========================================================
-- HEADLESS
--========================================================

local function setHeadless(enabled)
	headlessEnabled = enabled

	local character = player.Character

	if not character then
		return
	end

	local head = character:FindFirstChild("Head")

	if head then
		head.Transparency = enabled and 1 or 0

		for _, child in ipairs(head:GetDescendants()) do
			if child:IsA("Decal") then
				child.Transparency = enabled and 1 or 0
			end
		end
	end

	if enabled then
		headlessToggle.BackgroundColor3 = Color3.fromRGB(170, 70, 70)
	else
		headlessToggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	end
end

headlessToggle.MouseButton1Click:Connect(function()
	setHeadless(not headlessEnabled)
end)

--========================================================
-- ÉQUIPER LES VÊTEMENTS
--========================================================

local function equipClothes()
	local character = getCharacter()

	if not character then
		return
	end

	local shirtID =
		cleanID(shirtTemplateBox.Text)
		or cleanID(shirtBox.Text)

	local pantsID =
		cleanID(pantsTemplateBox.Text)
		or cleanID(pantsBox.Text)

	if not shirtID and not pantsID then
		equipButton.Text = "ENTRE UN ID"

		task.delay(1, function()
			if equipButton and equipButton.Parent then
				equipButton.Text = "EQUIP"
			end
		end)

		return
	end

	--====================================================
	-- SAUVEGARDE DES VÊTEMENTS ORIGINAUX
	--====================================================

	if shirtID and originalShirt == nil then
		local oldShirt = character:FindFirstChildOfClass("Shirt")

		if oldShirt then
			originalShirt = oldShirt.ShirtTemplate
		else
			originalShirt = false
		end
	end

	if pantsID and originalPants == nil then
		local oldPants = character:FindFirstChildOfClass("Pants")

		if oldPants then
			originalPants = oldPants.PantsTemplate
		else
			originalPants = false
		end
	end

	--====================================================
	-- SHIRT
	--====================================================

	if shirtID then
		local shirt = character:FindFirstChildOfClass("Shirt")

		if not shirt then
			shirt = Instance.new("Shirt")
			shirt.Parent = character
		end

		shirt.ShirtTemplate =
			"rbxassetid://" .. tostring(shirtID)

		-- IMPORTANT :
		-- on mémorise le vêtement pour le RESET
		equippedShirtID = shirtID
	end

	--====================================================
	-- PANTS
	--====================================================

	if pantsID then
		local pants = character:FindFirstChildOfClass("Pants")

		if not pants then
			pants = Instance.new("Pants")
			pants.Parent = character
		end

		pants.PantsTemplate =
			"rbxassetid://" .. tostring(pantsID)

		-- IMPORTANT :
		-- on mémorise le vêtement pour le RESET
		equippedPantsID = pantsID
	end

	equipButton.Text = "EQUIPÉ ✓"

	task.delay(1, function()
		if equipButton and equipButton.Parent then
			equipButton.Text = "EQUIP"
		end
	end)
end

equipButton.MouseButton1Click:Connect(equipClothes)

--========================================================
-- UNEQUIP
--========================================================

unequipButton.MouseButton1Click:Connect(function()
	local character = getCharacter()

	if not character then
		return
	end

	local shirt = character:FindFirstChildOfClass("Shirt")
	local pants = character:FindFirstChildOfClass("Pants")

	-- SHIRT ORIGINAL
	if originalShirt ~= nil then
		if originalShirt ~= false then
			if not shirt then
				shirt = Instance.new("Shirt")
				shirt.Parent = character
			end

			shirt.ShirtTemplate = originalShirt
		else
			if shirt then
				shirt:Destroy()
			end
		end
	end

	-- PANTS ORIGINAL
	if originalPants ~= nil then
		if originalPants ~= false then
			if not pants then
				pants = Instance.new("Pants")
				pants.Parent = character
			end

			pants.PantsTemplate = originalPants
		else
			if pants then
				pants:Destroy()
			end
		end
	end

	-- IMPORTANT :
	-- on supprime la mémoire du vêtement équipé.
	-- Donc après RESET, il ne sera PAS remis.
	equippedShirtID = nil
	equippedPantsID = nil

	originalShirt = nil
	originalPants = nil

	unequipButton.Text = "RESTAURÉ ✓"

	task.delay(1, function()
		if unequipButton and unequipButton.Parent then
			unequipButton.Text = "UNEQUIP"
		end
	end)
end)

--========================================================
-- SEARCH TYPE SHIRT
--========================================================

shirtTypeButton.MouseButton1Click:Connect(function()
	selectedSearchType = "Shirt"

	shirtTypeButton.BackgroundColor3 =
		Color3.fromRGB(55, 110, 180)

	pantsTypeButton.BackgroundColor3 =
		Color3.fromRGB(65, 65, 65)
end)

--========================================================
-- SEARCH TYPE PANTS
--========================================================

pantsTypeButton.MouseButton1Click:Connect(function()
	selectedSearchType = "Pants"

	pantsTypeButton.BackgroundColor3 =
		Color3.fromRGB(55, 110, 180)

	shirtTypeButton.BackgroundColor3 =
		Color3.fromRGB(65, 65, 65)
end)

--========================================================
-- SEARCH PREVIEW
--========================================================

local function showItemPreview(id)
	preview.Image =
		"rbxthumb://type=Asset&id="
		.. tostring(id)
		.. "&w=420&h=420"
end

--========================================================
-- SEARCH ITEM
--========================================================

local function searchItem()
	local id = cleanID(idBox.Text)

	if not id then
		currentItemID = nil
		preview.Image = ""

		resultLabel.Text = "❌ ID invalide"
		resultLabel.TextColor3 =
			Color3.fromRGB(220, 80, 80)

		return
	end

	currentItemID = id
	currentItemType = selectedSearchType

	showItemPreview(id)

	resultLabel.Text =
		"ID : "
		.. tostring(id)
		.. " | "
		.. selectedSearchType

	resultLabel.TextColor3 =
		Color3.fromRGB(100, 220, 130)
end

searchButton.MouseButton1Click:Connect(searchItem)

idBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		searchItem()
	end
end)

--========================================================
-- ESSAYER SEARCH ITEM
--========================================================

local function equipSearchItem()
	if not currentItemID then
		resultLabel.Text =
			"❌ Recherche d'abord un ID"

		resultLabel.TextColor3 =
			Color3.fromRGB(220, 80, 80)

		return
	end

	local character = getCharacter()

	-- SHIRT
	if currentItemType == "Shirt" then

		if originalShirt == nil then
			local oldShirt =
				character:FindFirstChildOfClass("Shirt")

			if oldShirt then
				originalShirt =
					oldShirt.ShirtTemplate
			else
				originalShirt = false
			end
		end

		local shirt =
			character:FindFirstChildOfClass("Shirt")

		if not shirt then
			shirt = Instance.new("Shirt")
			shirt.Parent = character
		end

		shirt.ShirtTemplate =
			"rbxassetid://"
			.. tostring(currentItemID)

		-- MÉMOIRE RESET
		equippedShirtID = currentItemID

	-- PANTS
	elseif currentItemType == "Pants" then

		if originalPants == nil then
			local oldPants =
				character:FindFirstChildOfClass("Pants")

			if oldPants then
				originalPants =
					oldPants.PantsTemplate
			else
				originalPants = false
			end
		end

		local pants =
			character:FindFirstChildOfClass("Pants")

		if not pants then
			pants = Instance.new("Pants")
			pants.Parent = character
		end

		pants.PantsTemplate =
			"rbxassetid://"
			.. tostring(currentItemID)

		-- MÉMOIRE RESET
		equippedPantsID = currentItemID
	end

	resultLabel.Text = "ÉQUIPÉ ✓"
	resultLabel.TextColor3 =
		Color3.fromRGB(80, 220, 110)
end

tryItemButton.MouseButton1Click:Connect(equipSearchItem)

--========================================================
-- CHARGER DANS CLOTHING
--========================================================

loadItemButton.MouseButton1Click:Connect(function()

	if not currentItemID then
		resultLabel.Text = "❌ Aucun item"
		resultLabel.TextColor3 =
			Color3.fromRGB(220, 80, 80)

		return
	end

	if currentItemType == "Shirt" then

		shirtBox.Text =
			tostring(currentItemID)

		shirtTemplateBox.Text =
			tostring(currentItemID)

	elseif currentItemType == "Pants" then

		pantsBox.Text =
			tostring(currentItemID)

		pantsTemplateBox.Text =
			tostring(currentItemID)
	end

	resultLabel.Text =
		"CHARGÉ DANS CLOTHING ✓"

	resultLabel.TextColor3 =
		Color3.fromRGB(100, 220, 130)
end)

--========================================================
-- APERÇU 3D DES OUTFITS
--========================================================

local function createPreview(parent, outfit)

	local viewport = Instance.new("ViewportFrame")

	viewport.Size =
		UDim2.fromOffset(130, 150)

	viewport.Position =
		UDim2.fromOffset(10, 10)

	viewport.BackgroundColor3 =
		Color3.fromRGB(12, 12, 12)

	viewport.BorderSizePixel = 0

	viewport.Ambient =
		Color3.fromRGB(200, 200, 200)

	viewport.LightColor =
		Color3.fromRGB(255, 255, 255)

	viewport.LightDirection =
		Vector3.new(-1, -1, -1)

	viewport.Parent = parent

	addCorner(viewport, 8)

	local world = Instance.new("WorldModel")
	world.Parent = viewport

	local character = player.Character

	if not character then
		return
	end

	character.Archivable = true

	local clone = character:Clone()

	if not clone then
		return
	end

	-- Supprimer scripts/tools
	for _, object in ipairs(clone:GetDescendants()) do

		if object:IsA("Script")
			or object:IsA("LocalScript")
			or object:IsA("ModuleScript")
			or object:IsA("Tool") then

			object:Destroy()
		end
	end

	-- Supprimer anciens vêtements
	for _, object in ipairs(clone:GetChildren()) do

		if object:IsA("Shirt")
			or object:IsA("Pants")
			or object:IsA("ShirtGraphic") then

			object:Destroy()
		end
	end

	-- SHIRT
	if outfit.shirt and outfit.shirt ~= "" then

		local shirt = Instance.new("Shirt")

		shirt.ShirtTemplate =
			outfit.shirt

		shirt.Parent = clone
	end

	-- PANTS
	if outfit.pants and outfit.pants ~= "" then

		local pants = Instance.new("Pants")

		pants.PantsTemplate =
			outfit.pants

		pants.Parent = clone
	end

	clone.Parent = world

	clone:PivotTo(
		CFrame.new(0, 0, 0)
	)

	local camera = Instance.new("Camera")

	camera.CFrame =
		CFrame.new(
			Vector3.new(0, 2.5, 8),
			Vector3.new(0, 2.5, 0)
		)

	camera.Parent = viewport

	viewport.CurrentCamera = camera
end

--========================================================
-- REFRESH OUTFITS
--========================================================

refreshOutfits = function()

	for _, child in ipairs(list:GetChildren()) do

		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	empty.Visible =
		#savedOutfits == 0

	for displayIndex = #savedOutfits, 1, -1 do

		local outfit =
			savedOutfits[displayIndex]

		local index =
			displayIndex

		local card = Instance.new("Frame")

		card.Size =
			UDim2.new(1, -10, 0, 170)

		card.BackgroundColor3 =
			Color3.fromRGB(35, 35, 35)

		card.BorderSizePixel = 0
		card.Parent = list

		addCorner(card, 10)

		-- PREVIEW
		createPreview(
			card,
			outfit
		)

		-- NOM
		local nameLabel = Instance.new("TextLabel")

		nameLabel.Size =
			UDim2.new(1, -155, 0, 35)

		nameLabel.Position =
			UDim2.fromOffset(150, 10)

		nameLabel.BackgroundTransparency = 1

		nameLabel.Text =
			outfit.name

		nameLabel.TextColor3 =
			Color3.new(1, 1, 1)

		nameLabel.TextSize = 17

		nameLabel.Font =
			Enum.Font.GothamBold

		nameLabel.TextXAlignment =
			Enum.TextXAlignment.Left

		nameLabel.Parent = card

		-- EQUIPER
		local equipSaved = createButton(
			card,
			"EQUIPER",
			UDim2.fromOffset(150, 55),
			UDim2.fromOffset(100, 35),
			Color3.fromRGB(45, 140, 70)
		)

		-- RENOMMER
		local rename = createButton(
			card,
			"RENOMMER",
			UDim2.fromOffset(260, 55),
			UDim2.fromOffset(100, 35),
			Color3.fromRGB(70, 70, 150)
		)

		-- SUPPRIMER
		local delete = createButton(
			card,
			"SUPPRIMER",
			UDim2.fromOffset(150, 100),
			UDim2.fromOffset(210, 35),
			Color3.fromRGB(150, 55, 55)
		)

		--================================================
		-- EQUIP SAVED
		--================================================

		equipSaved.MouseButton1Click:Connect(function()

			shirtBox.Text =
				tostring(outfit.shirtID or "")

			shirtTemplateBox.Text =
				tostring(outfit.shirt or "")

			pantsBox.Text =
				tostring(outfit.pantsID or "")

			pantsTemplateBox.Text =
				tostring(outfit.pants or "")

			equipClothes()
		end)

		--================================================
		-- DELETE
		--================================================

		delete.MouseButton1Click:Connect(function()

			table.remove(
				savedOutfits,
				index
			)

			refreshOutfits()
		end)

		--================================================
		-- RENAME
		--================================================

		rename.MouseButton1Click:Connect(function()

			local renameBox =
				Instance.new("TextBox")

			renameBox.Size =
				UDim2.fromOffset(320, 45)

			renameBox.Position =
				UDim2.new(
					0.5,
					-160,
					0.5,
					-22
				)

			renameBox.BackgroundColor3 =
				Color3.fromRGB(35, 35, 35)

			renameBox.BorderSizePixel = 0

			renameBox.Text =
				outfit.name

			renameBox.TextColor3 =
				Color3.new(1, 1, 1)

			renameBox.TextSize = 16
			renameBox.Font = Enum.Font.Gotham

			renameBox.ZIndex = 50

			renameBox.Parent = gui

			addCorner(renameBox, 8)

			renameBox.FocusLost:Connect(function()

				local newName =
					tostring(renameBox.Text or "")
					:sub(1, 40)

				if newName ~= "" then
					outfit.name = newName
				end

				renameBox:Destroy()

				refreshOutfits()
			end)

			renameBox:CaptureFocus()
		end)
	end

	task.wait()

	list.CanvasSize =
		UDim2.new(
			0,
			0,
			0,
			layout.AbsoluteContentSize.Y + 10
		)
end

--========================================================
-- SAUVEGARDER UNE TENUE
--========================================================

saveButton.MouseButton1Click:Connect(function()

	local character = getCharacter()

	local shirt =
		character:FindFirstChildOfClass("Shirt")

	local pants =
		character:FindFirstChildOfClass("Pants")

	local shirtTemplate = ""
	local pantsTemplate = ""

	if shirt then
		shirtTemplate =
			shirt.ShirtTemplate or ""
	end

	if pants then
		pantsTemplate =
			pants.PantsTemplate or ""
	end

	if shirtTemplate == ""
		and pantsTemplate == "" then

		saveButton.Text =
			"AUCUNE TENUE"

		task.delay(1, function()

			if saveButton and saveButton.Parent then
				saveButton.Text =
					"+ SAUVEGARDER LA TENUE"
			end

		end)

		return
	end

	local shirtID =
		cleanID(shirtTemplate) or ""

	local pantsID =
		cleanID(pantsTemplate) or ""

	local outfit = {

		name =
			"Tenue "
			.. tostring(#savedOutfits + 1),

		shirt =
			shirtTemplate,

		pants =
			pantsTemplate,

		shirtID =
			shirtID,

		pantsID =
			pantsID
	}

	table.insert(
		savedOutfits,
		outfit
	)

	refreshOutfits()

	saveButton.Text =
		"SAUVEGARDÉ ✓"

	task.delay(1, function()

		if saveButton and saveButton.Parent then
			saveButton.Text =
				"+ SAUVEGARDER LA TENUE"
		end

	end)
end)

--========================================================
-- DRAG DES FENÊTRES
--========================================================

local function addDrag(handle, frame)
	-- Déplacement direct et instantané, spécialement pour le tactile.
	handle.Active = true
	frame.Active = true
	handle.ZIndex = math.max(handle.ZIndex, 2)

	local dragging = false
	local dragStart = nil
	local startPosition = nil
	local touchInput = nil
	local actionName = "ClothingTester_Drag_" .. frame.Name

	local function stopDrag()
		dragging = false
		dragStart = nil
		startPosition = nil
		touchInput = nil
		pcall(function()
			ContextActionService:UnbindAction(actionName)
		end)
	end

	local function blockCamera()
		return Enum.ContextActionResult.Sink
	end

	local function moveFrame(position)
		if not dragging or not dragStart or not startPosition then
			return
		end

		local delta = position - dragStart
		frame.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end

	handle.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		dragging = true
		dragStart = input.Position
		startPosition = frame.Position

		-- Bloque la caméra dès le premier contact tactile.
		if input.UserInputType == Enum.UserInputType.Touch then
			ContextActionService:BindActionAtPriority(
				actionName,
				blockCamera,
				false,
				Enum.ContextActionPriority.High.Value + 100,
				Enum.UserInputType.Touch
			)
			touchInput = input
		end

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End
				or input.UserInputState == Enum.UserInputState.Cancel then
				stopDrag()
			end
		end)
	end)

	-- Événement tactile direct : beaucoup plus réactif que InputChanged global.
	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			touchInput = input
		elseif input.UserInputType == Enum.UserInputType.MouseMovement then
			-- La souris continue de fonctionner normalement.
			if dragging then
				moveFrame(input.Position)
			end
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end

		if input.UserInputType == Enum.UserInputType.Touch then
			moveFrame(input.Position)
		elseif input.UserInputType == Enum.UserInputType.MouseMovement then
			moveFrame(input.Position)
		end
	end)

	handle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			stopDrag()
		end
	end)
end

addDrag(clothingTitle, clothing)
addDrag(searchTitle, search)
addDrag(savedTitle, saved)

--========================================================
-- TOGGLE CLOTHING
--========================================================

clothingToggle.MouseButton1Click:Connect(function()

	clothing.Visible =
		not clothing.Visible

	if clothing.Visible then
		clothingToggle.BackgroundColor3 =
			Color3.fromRGB(55, 110, 180)
	else
		clothingToggle.BackgroundColor3 =
			Color3.fromRGB(70, 70, 70)
	end
end)

--========================================================
-- TOGGLE SEARCH
--========================================================

searchToggle.MouseButton1Click:Connect(function()

	search.Visible =
		not search.Visible

	if search.Visible then
		searchToggle.BackgroundColor3 =
			Color3.fromRGB(60, 130, 90)
	else
		searchToggle.BackgroundColor3 =
			Color3.fromRGB(70, 70, 70)
	end
end)

--========================================================
-- TOGGLE SAVED
--========================================================

savedToggle.MouseButton1Click:Connect(function()

	saved.Visible =
		not saved.Visible

	if saved.Visible then
		savedToggle.BackgroundColor3 =
			Color3.fromRGB(90, 70, 150)
	else
		savedToggle.BackgroundColor3 =
			Color3.fromRGB(70, 70, 70)
	end
end)

--========================================================
-- CLOSE BUTTONS
--========================================================

closeClothing.MouseButton1Click:Connect(function()

	clothing.Visible = false

	clothingToggle.BackgroundColor3 =
		Color3.fromRGB(70, 70, 70)
end)

closeSearch.MouseButton1Click:Connect(function()

	search.Visible = false

	searchToggle.BackgroundColor3 =
		Color3.fromRGB(70, 70, 70)
end)

closeSaved.MouseButton1Click:Connect(function()

	saved.Visible = false

	savedToggle.BackgroundColor3 =
		Color3.fromRGB(70, 70, 70)
end)

--========================================================
-- IMPORTANT :
-- RESTAURER LES VÊTEMENTS APRÈS RESET
--========================================================

local function restoreClothesAfterReset(character)

	if not character then
		return
	end

	-- Attendre que le personnage soit chargé
	character:WaitForChild("Humanoid", 10)

	task.wait(0.5)

	--====================================================
	-- SHIRT
	--====================================================

	if equippedShirtID then

		local shirt =
			character:FindFirstChildOfClass("Shirt")

		if not shirt then
			shirt = Instance.new("Shirt")
			shirt.Parent = character
		end

		shirt.ShirtTemplate =
			"rbxassetid://"
			.. tostring(equippedShirtID)
	end

	--====================================================
	-- PANTS
	--====================================================

	if equippedPantsID then

		local pants =
			character:FindFirstChildOfClass("Pants")

		if not pants then
			pants = Instance.new("Pants")
			pants.Parent = character
		end

		pants.PantsTemplate =
			"rbxassetid://"
			.. tostring(equippedPantsID)
	end

	--====================================================
	-- HEADLESS
	--====================================================

	if headlessEnabled then

		task.wait(0.2)

		local head =
			character:FindFirstChild("Head")

		if head then

			head.Transparency = 1

			for _, child in ipairs(head:GetDescendants()) do

				if child:IsA("Decal") then
					child.Transparency = 1
				end
			end
		end
	end
end

--========================================================
-- CHARACTER APPEARANCE LOADED
--========================================================

player.CharacterAppearanceLoaded:Connect(function(character)

	restoreClothesAfterReset(character)

end)

--========================================================
-- FALLBACK CHARACTER ADDED
--========================================================

player.CharacterAdded:Connect(function(character)

	-- Petite sécurité si CharacterAppearanceLoaded
	-- n'a pas encore remis les vêtements.

	task.delay(2, function()

		if character ~= player.Character then
			return
		end

		restoreClothesAfterReset(character)

	end)
end)

--========================================================
-- LISTE OUTFITS
--========================================================

layout:GetPropertyChangedSignal(
	"AbsoluteContentSize"
):Connect(function()

	list.CanvasSize =
		UDim2.new(
			0,
			0,
			0,
			layout.AbsoluteContentSize.Y + 10
		)
end)

--========================================================
-- VISIBILITÉ DE DÉPART
--========================================================

-- Le menu CLOTHING est visible immédiatement.
-- SEARCH et SAVED restent fermés au démarrage.
clothing.Visible = true
search.Visible = false
saved.Visible = false

--========================================================
-- MOBILE / RESPONSIVE
--========================================================

-- Conteneur unique : l'UIScale est appliqué ici pour garantir
-- que toutes les tailles/positions des éléments enfants sont réduites.
local mobileRoot = Instance.new("Frame")
mobileRoot.Name = "MobileScaleRoot"
mobileRoot.Size = UDim2.fromScale(2, 2)
mobileRoot.Position = UDim2.fromScale(0, 0)
mobileRoot.BackgroundTransparency = 1
mobileRoot.BorderSizePixel = 0
mobileRoot.ClipsDescendants = false
mobileRoot.Parent = gui

-- Reparentage des éléments principaux dans le conteneur.
topBar.Parent = mobileRoot
clothing.Parent = mobileRoot
search.Parent = mobileRoot
saved.Parent = mobileRoot

local mobileScale = Instance.new("UIScale")
mobileScale.Name = "MobileScale"
mobileScale.Scale = 1
mobileScale.Parent = mobileRoot

local camera = workspace.CurrentCamera

local function setMobileScale(value)
	mobileScale.Scale = value
end

local function updateMobileLayout()
	camera = workspace.CurrentCamera or camera
	if not camera then
		return
	end

	local viewport = camera.ViewportSize
	local width = viewport.X
	local isMobile = UserInputService.TouchEnabled

	if isMobile or width <= 900 then
		-- 0.5 = exactement la moitié de la taille PC.
		setMobileScale(0.5)

		-- Comme tout est dans MobileScaleRoot, on centre les fenêtres
		-- avec leurs positions d'origine et l'UIScale réduit réellement
		-- leurs dimensions et leurs éléments internes.
		topBar.AnchorPoint = Vector2.new(0.5, 0)
		topBar.Position = UDim2.new(0.5, 0, 0, 8)

		clothing.AnchorPoint = Vector2.new(0.5, 0.5)
		clothing.Position = UDim2.new(0.5, 0, 0.53, 0)

		search.AnchorPoint = Vector2.new(0.5, 0.5)
		search.Position = UDim2.new(0.5, 0, 0.53, 0)

		saved.AnchorPoint = Vector2.new(0.5, 0.5)
		saved.Position = UDim2.new(0.5, 0, 0.53, 0)

		pcall(function()
			shirtBox.KeyboardType = Enum.KeyboardType.NumberPad
			shirtTemplateBox.KeyboardType = Enum.KeyboardType.NumberPad
			pantsBox.KeyboardType = Enum.KeyboardType.NumberPad
			pantsTemplateBox.KeyboardType = Enum.KeyboardType.NumberPad
			idBox.KeyboardType = Enum.KeyboardType.NumberPad
		end)
	else
		setMobileScale(1)

		topBar.AnchorPoint = Vector2.new(0, 0)
		topBar.Position = UDim2.new(0.5, -317, 0, 10)

		clothing.AnchorPoint = Vector2.new(0, 0)
		clothing.Position = UDim2.new(0.5, -430, 0.5, -215)

		search.AnchorPoint = Vector2.new(0, 0)
		search.Position = UDim2.new(0.5, -215, 0.5, -260)

		saved.AnchorPoint = Vector2.new(0, 0)
		saved.Position = UDim2.new(1, -520, 0.5, -300)
	end
end

if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateMobileLayout)
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateMobileLayout)
	end
	updateMobileLayout()
end)

updateMobileLayout()

-- Sécurité : maintient l'échelle mobile à 0.5.
task.spawn(function()
	while gui.Parent do
		task.wait(0.15)
		if UserInputService.TouchEnabled then
			mobileScale.Scale = 0.5
		else
			mobileScale.Scale = 1
		end
	end
end)

--========================================================
-- START
--========================================================

refreshOutfits()

print("========================================")
print(" CLOTHING TESTER")
print(" SEARCH PAR ID")
print(" SAVED OUTFITS")
print(" HEADLESS")
print(" RESET / RESPAWN : ACTIVE")
print(" NPC : " .. NPC_NAME)
print("========================================")