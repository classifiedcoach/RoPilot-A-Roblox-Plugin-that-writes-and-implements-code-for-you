----NOTE/REQUIREMENTS-----
--You will need your own API key with one of the providers to send prompts. I recommend OpenAI/Anthropic over Google. 

-------------------------Summary-----------------------------------
--This plugin creates a GUI that allows players to send update the code of their experiences using natural language prompt requests to external LLM model providers.
--  These requests are sent with the context of the experience's code with a static prefix prompt, and the LLM model code suggestions are implemented.
--  The structure of this codebase is a few variables being set up for use throughout the program, then buckets of the GUI elements and their functionality, then the core functions that handle API calls/code implementation.
--  The plugin only uses the context of scripts and their contents currently. It does not use the context of models/sounds/meshes/etc..
--  It can implement multiple code change requests from a single prompt. 


-------------------------Quick-Start Test Prompts-------------------------------
-- Test Prompt 1: Create a new script for me that prints to the console "Hello" and the current timestamp once every 5 seconds. Also, create a separate new script that adds a Big Red GUI button to the screen that makes a different GUI frame open and close when clicked.
-- Test Prompt 2 (After test prompt 1): Change the script that prints "Hello" and the current timestamp once every 5 seconds to instead print once every second. Also, find the big red GUI button and make it pink. 


--Immediate Fixes/Changes/Improvements:
---- Google often returns invalid/unreal Service names (It hallucinates names of services where it wants to store scripts)
---- Re-Implement the dynamic resizing of the UserRequestInput text box so that we can have very clean and dynamically resized user inputs and API responses.
---- Ensure we have the "CurrentMode" functionality working such that questions get presented properly in UserRequestInput and Code Changes get implemented into scripts with proper structure.
---- Use the API provider's new JSON structure response flags/settings, which essentially force the models to response in a JSON structure.


--Backlog Fun Ideas:
---- Saving API provider and API keys across user sessions.
---- Proactive suggestions button, where the plugin just submits their experience's contents and receive back a set of "cards" which have plain english suggestions on them, that a user can click on to have them implemented.
---- Accessing more elements of the experience, not just the script's contents, such as in-world models and their attributes.
---- Allowing the plugin to make changes to the actual world including moving/editing properties of/adding models/sounds/etc...
---- Implenting an alterantive approach to saving changes such that users can "Ctrl+Z"/"Ctrl+SHFT+Z" to undo/redo changes implemented by the plugin. (In addition to my changes screen already implemented)
---- Enabling users to more granularly select which scripts/assets of the experience to include in AI responses
---- Indicate to users the expected # of tokens/associated cost of API prompts before they're sent and give feedback on cost consumed after responses are replied. Dashboard to track across responses?
---- Make the error responses from the API even more clear, so users can more quickly understand when they've reached issues such as max input/output token limits or have consumed their full budgets.
---- Allow users to connect to their own locally ran AI LLM models, such as a LLama 7B model running on the same laptop as their Roblox Studio instance.
---- Embed a model directly within the plugin/access a locally embedded model in Roblox studio from Roblox.
---- Add support for the latest models released by major providers, and add support for even more popular models recently released.
---- Add an Icon for the plugin so it has a pretty image in the Roblox Studio Plugin selection frame in the top of the screen. 

-- Required services
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local ScriptEditorService = game:GetService("ScriptEditorService")
local UserInputService = game:GetService("UserInputService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")


-- Variables for API selection and key
local selectedAPIProvider = nil
local apiKey = nil
local existingScripts = {} 
local scriptBackups = {}
local changeHistoryStack = {}
local currentChangeIndex = 0
local undoButton


local currentMode = "Code" --Start off the plugin into coding mode.
local ToggleButton
local CodeLabel
local QuestionLabel

-- List of services to check 
local servicesToCheck = {
	game.ServerScriptService,
	game.Workspace,
	game.ReplicatedStorage,
	game.StarterGui,
	game.StarterPlayer.StarterPlayerScripts,
	game.StarterPlayer.StarterCharacterScripts,
	game.ServerStorage

}

-- Table to keep track of selected services
local selectedServices = {}
for _, service in ipairs(servicesToCheck) do
	selectedServices[service] = true  -- Initially, all services are selected
end

-- Create DockWidgetPluginGui (This is the "Frame" within Roblox studio that we can drag around in Roblox studio, and fill with the plugin's elements.)
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	400,
	300,
	300,
	200
)

------------------------Main Bare-Bones Frame For All GUI Elements------------------------
-- Create the main plugin GUI
local pluginGui = plugin:CreateDockWidgetPluginGui("CodeUpdaterGUI", widgetInfo)
pluginGui.Title = "Code Updater"

-- Create main Frame
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(1, 0, 1, 0)
Frame.BackgroundColor3 = Color3.fromRGB(227, 230, 232)
Frame.BorderSizePixel = 0
Frame.Parent = pluginGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 8)
FrameCorner.Parent = Frame
----------------------End Main Bare-Bones Frame For All GUI Elements----------------------



-----------------------User Request Input Text-----------------------------------
-- Create ScrollingFrame for user input
local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(0.9, 0, 0.5, 0)
ScrollingFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.ScrollBarThickness = 6
ScrollingFrame.ScrollingEnabled = true
ScrollingFrame.Parent = Frame
ScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
ScrollingFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
ScrollingFrame.Visible = false
--ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y


-- Create TextBox for user input
local UserRequestInput = Instance.new("TextBox")
UserRequestInput.Size = UDim2.new(1, 0, 1, 0)
UserRequestInput.Position = UDim2.new(0, 0, 0, 0)
UserRequestInput.Text = "Enter your code update request here..."
UserRequestInput.TextColor3 = Color3.fromRGB(66, 84, 102)
UserRequestInput.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
UserRequestInput.Font = Enum.Font.SourceSansSemibold
UserRequestInput.MultiLine = true
UserRequestInput.TextWrapped = true
UserRequestInput.TextSize = 14
UserRequestInput.ClearTextOnFocus = false
UserRequestInput.AutomaticSize = Enum.AutomaticSize.Y 
UserRequestInput.Parent = ScrollingFrame
UserRequestInput.TextYAlignment = Enum.TextYAlignment.Top

local TextBoxCorner = Instance.new("UICorner")
TextBoxCorner.CornerRadius = UDim.new(0, 4)
TextBoxCorner.Parent = UserRequestInput

local TextBoxPadding = Instance.new("UIPadding")
TextBoxPadding.PaddingLeft = UDim.new(0, 8)
TextBoxPadding.PaddingRight = UDim.new(0, 8)
TextBoxPadding.PaddingTop = UDim.new(0, 8)
TextBoxPadding.PaddingBottom = UDim.new(0, 8)
TextBoxPadding.Parent = UserRequestInput

local TextSizeConstraint = Instance.new("UITextSizeConstraint")
TextSizeConstraint.MaxTextSize = 14
TextSizeConstraint.MinTextSize = 10
TextSizeConstraint.Parent = UserRequestInput

-- Create Send Button
local SendButton = Instance.new("TextButton")
SendButton.Size = UDim2.new(0.3, 0, 0.15, 0)
SendButton.Position = UDim2.new(0.35, 0, 0.7, 0)
SendButton.Text = "Send Prompt"
SendButton.Font = Enum.Font.SourceSansBold
SendButton.TextSize = 16
SendButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SendButton.BackgroundColor3 = Color3.fromRGB(10, 37, 64)
SendButton.Parent = Frame
SendButton.Visible = false

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = SendButton

-- Create Response Text area
local ResponseText = Instance.new("TextLabel")
ResponseText.Size = UDim2.new(0.9, 0, 0.1, 0)
ResponseText.Position = UDim2.new(0.05, 0, 0.89, 0)
ResponseText.BackgroundTransparency = 1
ResponseText.Text = ""
ResponseText.TextColor3 = Color3.fromRGB(66, 84, 102)
ResponseText.Font = Enum.Font.SourceSansSemibold
ResponseText.TextSize = 14
ResponseText.TextWrapped = true
ResponseText.TextXAlignment = Enum.TextXAlignment.Center
ResponseText.Parent = Frame

-- Double-click to clear text from the user request input box.
local lastClickTime = 0
UserRequestInput.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local currentTime = tick()
		if currentTime - lastClickTime < 1 then
			UserRequestInput.Text = ""
		end
		lastClickTime = currentTime
	end
end)

-----------------------End User Request Input Text-----------------------------------



----------------------------Settings GUI & Functionality----------------------------------
-- Create Settings Button
local SettingsButton = Instance.new("TextButton")
SettingsButton.Size = UDim2.new(0.3, 0, 0.1, 0)
SettingsButton.Position = UDim2.new(0.02, 0, 0.02, 0)
SettingsButton.Text = "Settings"
SettingsButton.Font = Enum.Font.SourceSansBold
SettingsButton.TextSize = 14
SettingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SettingsButton.BackgroundColor3 = Color3.fromRGB(99, 91, 255)
SettingsButton.Parent = Frame

local SettingsButtonCorner = Instance.new("UICorner")
SettingsButtonCorner.CornerRadius = UDim.new(0, 8)
SettingsButtonCorner.Parent = SettingsButton

-- Create Settings Menu
local SettingsMenu = Instance.new("Frame")
SettingsMenu.Size = UDim2.new(0.9, 0, 0.65, 0)
SettingsMenu.Position = UDim2.new(0.05, 0, 0.15, 0)
SettingsMenu.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SettingsMenu.Visible = false
SettingsMenu.Parent = Frame

local SettingsMenuCorner = Instance.new("UICorner")
SettingsMenuCorner.CornerRadius = UDim.new(0, 4)
SettingsMenuCorner.Parent = SettingsMenu

-- Create ScrollingFrame for settings
local SettingsScrollingFrame = Instance.new("ScrollingFrame")
SettingsScrollingFrame.Size = UDim2.new(1, -20, 1, -20)
SettingsScrollingFrame.Position = UDim2.new(0, 10, 0, 10)
SettingsScrollingFrame.BackgroundTransparency = 1
SettingsScrollingFrame.ScrollBarThickness = 6
SettingsScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
SettingsScrollingFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
SettingsScrollingFrame.Parent = SettingsMenu

-- Create checkboxes for each service within the settings scrollingframe
local checkboxes = {}
for i, service in ipairs(servicesToCheck) do
	local checkbox = Instance.new("TextButton")
	checkbox.Size = UDim2.new(1, -20, 0, 30)
	checkbox.Position = UDim2.new(0, 10, 0, (i) * 40) --(i-1) 
	checkbox.Text = service.Name
	checkbox.Font = Enum.Font.SourceSans
	checkbox.TextSize = 14
	checkbox.TextColor3 = Color3.fromRGB(0, 0, 0)
	checkbox.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
	checkbox.Parent = SettingsScrollingFrame

	local checkboxCorner = Instance.new("UICorner")
	checkboxCorner.CornerRadius = UDim.new(0, 4)
	checkboxCorner.Parent = checkbox

	local function updateCheckboxAppearance()
		if selectedServices[service] then
			checkbox.BackgroundColor3 = Color3.fromRGB(80, 80, 80) -- Darker gray
			checkbox.TextColor3 = Color3.fromRGB(255, 255, 255) -- White
			checkbox.Text = service.Name .. " (In use)"
		else
			checkbox.BackgroundColor3 = Color3.fromRGB(220, 220, 220) -- Light gray
			checkbox.TextColor3 = Color3.fromRGB(0, 0, 0) -- Black
			checkbox.Text = service.Name
		end
	end

	checkbox.MouseButton1Click:Connect(function()
		selectedServices[service] = not selectedServices[service]
		updateCheckboxAppearance()
	end)

	updateCheckboxAppearance() -- Set initial appearance

	table.insert(checkboxes, {button = checkbox, service = service})
end


local ToggleModeFrame = Instance.new("Frame")
ToggleModeFrame.Size = UDim2.new(1, -20, 0, 30)
ToggleModeFrame.Position = UDim2.new(0, 10, 0, 0)
ToggleModeFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ToggleModeFrame.Parent = SettingsScrollingFrame
ToggleModeFrame.BorderSizePixel = 0

-- Create Toggle Button
ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0.2, 0, 1, 0)
ToggleButton.Position = UDim2.new(0.4, 0, 0.05, 0)
ToggleButton.Text = ""
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
ToggleButton.Parent = ToggleModeFrame

local ToggleButtonCorner = Instance.new("UICorner")
ToggleButtonCorner.CornerRadius = UDim.new(0.5, 0)
ToggleButtonCorner.Parent = ToggleButton

local ToggleIndicator = Instance.new("Frame")
ToggleIndicator.Size = UDim2.new(0.45, 0, 0.9, 0)
ToggleIndicator.Position = UDim2.new(0.025, 0, 0.05, 0)
ToggleIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ToggleIndicator.Parent = ToggleButton

local ToggleIndicatorCorner = Instance.new("UICorner")
ToggleIndicatorCorner.CornerRadius = UDim.new(0.5, 0)
ToggleIndicatorCorner.Parent = ToggleIndicator

CodeLabel = Instance.new("TextLabel")
CodeLabel.Size = UDim2.new(0.1, 0, 0.05, 0)
CodeLabel.Position = UDim2.new(0.25, 0, 0.5, 0)
CodeLabel.Text = "Code"
CodeLabel.Font = Enum.Font.SourceSansBold
CodeLabel.TextSize = 14
CodeLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
CodeLabel.BackgroundTransparency = 1
CodeLabel.Parent = ToggleModeFrame

QuestionLabel = Instance.new("TextLabel")
QuestionLabel.Size = UDim2.new(0.1, 0, 0.05, 0)
QuestionLabel.Position = UDim2.new(0.65, 0, 0.5, 0)
QuestionLabel.Text = "Question"
QuestionLabel.Font = Enum.Font.SourceSansBold
QuestionLabel.TextSize = 14
QuestionLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
QuestionLabel.BackgroundTransparency = 1
QuestionLabel.Parent = ToggleModeFrame

-- Add this function after the variable declarations
local function updateToggleAppearance()
	if currentMode == "Code" then
		ToggleIndicator:TweenPosition(UDim2.new(0.025, 0, 0.05, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
		CodeLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
		QuestionLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
	else
		ToggleIndicator:TweenPosition(UDim2.new(0.525, 0, 0.05, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
		CodeLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
		QuestionLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	end
end

-- Add this to the end of the init function
ToggleButton.MouseButton1Click:Connect(function()
	currentMode = currentMode == "Code" and "Question" or "Code"
	updateToggleAppearance()
end)

SettingsScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, (#servicesToCheck+1) * 40) --The +1 represents the Code Vs. Question Frame.
----------------------------End Settings GUI & Functionality----------------------------------


----------------------------Undo Changes GUI & Functionality-------------------------------------
-- Create Undo Button
undoButton = Instance.new("TextButton")
undoButton.Size = UDim2.new(0.3, 0, 0.1, 0)
undoButton.Position = UDim2.new(0.68, 0, 0.88, 0)
undoButton.Text = "Undo Most Recent Change"
undoButton.Font = Enum.Font.SourceSansBold
undoButton.TextSize = 14
undoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
undoButton.BackgroundColor3 = Color3.fromRGB(234, 76, 137)
undoButton.Parent = Frame
undoButton.Visible = false

local UndoButtonCorner = Instance.new("UICorner")
UndoButtonCorner.CornerRadius = UDim.new(0, 8)
UndoButtonCorner.Parent = undoButton

-- Create View Changes Button
local ViewChangesButton = Instance.new("TextButton")
ViewChangesButton.Size = UDim2.new(0.3, 0, 0.1, 0)
ViewChangesButton.Position = UDim2.new(0.02, 0, 0.88, 0)
ViewChangesButton.Text = "View Changes"
ViewChangesButton.Font = Enum.Font.SourceSansBold
ViewChangesButton.TextSize = 16
ViewChangesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ViewChangesButton.BackgroundColor3 = Color3.fromRGB(99, 91, 255)
ViewChangesButton.Parent = Frame
ViewChangesButton.Visible = false

local ViewChangesButtonCorner = Instance.new("UICorner")
ViewChangesButtonCorner.CornerRadius = UDim.new(0, 8)
ViewChangesButtonCorner.Parent = ViewChangesButton

-- Create Changes View
local ChangesView = Instance.new("ScrollingFrame")
ChangesView.Size = UDim2.new(0.9, 0, 0.7, 0)
ChangesView.Position = UDim2.new(0.05, 0, 0.15, 0)
ChangesView.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ChangesView.BorderSizePixel = 0
ChangesView.ScrollBarThickness = 6
ChangesView.Visible = false
ChangesView.Parent = Frame
ChangesView.ScrollBarImageColor3 = Color3.fromRGB(80, 75, 211) 

local ChangesViewCorner = Instance.new("UICorner")
ChangesViewCorner.CornerRadius = UDim.new(0, 8)
ChangesViewCorner.Parent = ChangesView

-- Forward declare functions to avoid inability to reference them.
local createChangeEntry
local updateChangesView
local undoSpecificChange

-- Function to create a change entry in the changes GUI
function createChangeEntry(change, index)
	local entryHeight = 140
	local entry = Instance.new("Frame")
	entry.Size = UDim2.new(1, -20, 0, entryHeight)
	entry.Position = UDim2.new(0, 10, 0, ((index - 1) * (entryHeight + 10)) + 10)
	entry.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	entry.BorderSizePixel = 0
	entry.Parent = ChangesView

	local entryCorner = Instance.new("UICorner")
	entryCorner.CornerRadius = UDim.new(0, 8)
	entryCorner.Parent = entry

	local changeNumber = Instance.new("TextLabel")
	changeNumber.Size = UDim2.new(0.05, 0, 0.125, 0)
	changeNumber.Position = UDim2.new(0.025, 0, 0.1, 0)
	changeNumber.Text = "[" .. index .. "]"
	changeNumber.Font = Enum.Font.SourceSansBold
	changeNumber.TextSize = 22
	changeNumber.TextColor3 = Color3.fromRGB(0, 0, 0)
	changeNumber.Parent = entry
	changeNumber.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	changeNumber.TextXAlignment = Enum.TextXAlignment.Center
	changeNumber.TextYAlignment = Enum.TextYAlignment.Center
	changeNumber.BorderSizePixel = 0

	local explanation = Instance.new("TextLabel")
	explanation.Size = UDim2.new(0.8, 0, 0.55, 0)
	explanation.Position = UDim2.new(0.1, 0, .1, 0)
	explanation.Text = change.explanation
	explanation.Font = Enum.Font.SourceSans
	explanation.TextSize = 18
	explanation.TextColor3 = Color3.fromRGB(0, 0, 0)
	explanation.TextWrapped = true
	explanation.TextXAlignment = Enum.TextXAlignment.Center
	explanation.TextYAlignment = Enum.TextYAlignment.Center
	explanation.Parent = entry
	explanation.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	explanation.BorderSizePixel = 0

	local gotoButton = Instance.new("TextButton")
	gotoButton.Size = UDim2.new(0.3, 0, .25, 0)
	gotoButton.Position = UDim2.new(0.1, 0, .70, 0)
	gotoButton.Text = "Goto Change"
	gotoButton.Font = Enum.Font.SourceSansBold
	gotoButton.TextSize = 14
	gotoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	gotoButton.BackgroundColor3 = Color3.fromRGB(10, 37, 64)
	gotoButton.Parent = entry

	local gotoButtonCorner = Instance.new("UICorner")
	gotoButtonCorner.CornerRadius = UDim.new(0, 8)
	gotoButtonCorner.Parent = gotoButton

	local undoButton = Instance.new("TextButton")
	undoButton.Size = UDim2.new(0.3, 0, .25, 0)
	undoButton.Position = UDim2.new(0.6, 0, .70, 0)
	undoButton.Text = "Undo Change"
	undoButton.Font = Enum.Font.SourceSansBold
	undoButton.TextSize = 14
	undoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	undoButton.BackgroundColor3 = Color3.fromRGB(234, 76, 137)
	undoButton.Parent = entry

	local undoButtonCorner = Instance.new("UICorner")
	undoButtonCorner.CornerRadius = UDim.new(0, 8)
	undoButtonCorner.Parent = undoButton

	gotoButton.MouseButton1Click:Connect(function()
		local service
		if change.serviceName == "StarterPlayerScripts" or change.serviceName == "StarterCharacterScripts" then
			service = game:GetService("StarterPlayer")[change.serviceName]
		else
			service = game:GetService(change.serviceName)
		end

		if service then
			local script = service:FindFirstChild(change.scriptName, true)
			if script then
				local currentSource = script.Source
				local startIndex

				if change.actionType == "ModifyExisting" or change.actionType == "AddOnly" then
					local commentedPreviousCode = change.previousCode and 
   						string.gsub(change.previousCode, "([^\r\n]+)", "-- %1") or ""
					startIndex = string.find(currentSource, commentedPreviousCode .. "\n" .. change.newCode, 1, true)
				elseif change.actionType == "NewScript" then
					startIndex = 1
				end
				
				local scriptDocument = ScriptEditorService:FindScriptDocument(script)
				if scriptDocument then
					local success, err = scriptDocument:CloseAsync()
					if not success then
						warn("Failed to close script document: ", err)
					end
				end
				
				if startIndex then
					local lineNumber = 1
					for i = 1, startIndex do
						if currentSource:sub(i, i) == '\n' then
							lineNumber = lineNumber + 1
						end
					end
					--plugin:Close
					-- Open the script at the calculated line number
					plugin:OpenScript(script, lineNumber)
				else
					warn("Could not find the exact location of the change in the script")
					plugin:OpenScript(script, 1)  -- Open at the beginning if exact location not found
				end
			else
				warn("Script not found:", change.serviceName, change.scriptName)
			end
		else
			warn("Service not found:", change.serviceName)
		end
	end)


	undoButton.MouseButton1Click:Connect(function()
		undoSpecificChange(index)
	end)

	return entryHeight + 10
end

--This function updates the "View Changes" GUI area where changes can be undone. 
function updateChangesView()
	for i, child in ipairs(ChangesView:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local totalHeight = 10
	for i, change in ipairs(changeHistoryStack) do
		totalHeight = totalHeight + createChangeEntry(change, i)
	end

	ChangesView.CanvasSize = UDim2.new(0, 0, 0, totalHeight)

	-- Update visibility of UI elements based on whether there are changes
	local hasChanges = #changeHistoryStack > 0
	undoButton.Visible = hasChanges
	ViewChangesButton.Visible = hasChanges
	ChangesView.Visible = hasChanges and ChangesView.Visible -- Keep current visibility if there are changes

	-- If there are no changes, reset the UI to its initial state
	if not hasChanges then
		ChangesView.Visible = false
		ScrollingFrame.Visible = true
		SendButton.Visible = true
	end
end

-- This function allows us to to undo a specific change
function undoSpecificChange(index)
	if index > 0 and index <= #changeHistoryStack then
		local change = changeHistoryStack[index]

		-- Handle nested services within StarterPlayer
		local service
		if change.serviceName == "StarterPlayerScripts" or change.serviceName == "StarterCharacterScripts" then
			service = game:GetService("StarterPlayer")[change.serviceName]
		else
			service = game:GetService(change.serviceName)
		end

		if service then
			local script = service:FindFirstChild(change.scriptName, true)

			if change.actionType == "ModifyExisting" or change.actionType == "AddOnly" then
				if script then
					if change.fullPreviousSource then
						-- Restore the entire previous source
						script.Source = change.fullPreviousSource

						-- Close the script document if it's open
						local scriptDocument = ScriptEditorService:FindScriptDocument(script)
						if scriptDocument then
							local success, err = scriptDocument:CloseAsync()
							if not success then
								warn("Failed to close script document: ", err)
							end
						end

						-- Open the script at the modified line
						plugin:OpenScript(script, tonumber(change.lineNumber) or 1)
					else
						warn("No previous source stored for script: " .. change.scriptName)
					end
				else
					warn("Script not found: " .. change.serviceName .. "." .. change.scriptName)
				end
			elseif change.actionType == "NewScript" then
				if script then
					-- Destroy the newly created script
					script:Destroy()
				else
					warn("Script not found: " .. change.serviceName .. "." .. change.scriptName)
				end
			end
		else
			warn("Service not found: " .. change.serviceName)
		end

		-- Remove the change from the history stack
		table.remove(changeHistoryStack, index)
		currentChangeIndex = #changeHistoryStack

		ResponseText.Text = "Change " .. index .. " undone."
		ResponseText.TextColor3 = Color3.fromRGB(36, 180, 126)

		-- Update Changes View
		updateChangesView()

		-- Update undo button visibility
		if #changeHistoryStack == 0 then
			undoButton.Visible = false
			ViewChangesButton.Visible = false
		end
	else
		ResponseText.Text = "Invalid change index"
		ResponseText.TextColor3 = Color3.fromRGB(234, 76, 137)
	end
end


----------------------------End Undo Changes GUI & Functionality-------------------------------------



----------------------------Dynamic Scrolling Frame Size for the Main User Request Input Text Box--------------------------------------------
-- This was inteded to update the ScrollingFrame size of the main text box based on text content within it. Could be implemented in future -- 


--This is essentially a dead function currently as with a massive amount of fiddling/testing I couldn't get it to behave how I wanted, so we just have a massive canvas size for now. 
local function updateScrollingFrame()
	--local textBounds = UserRequestInput.TextBounds
	--local frameHeight = ScrollingFrame.AbsoluteSize.Y
	--local newTextBoxHeight = math.max(textBounds.Y, frameHeight)
	--UserRequestInput.Size = UDim2.new(1, -12, 0, newTextBoxHeight)
	--ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, UserRequestInput.Size)

	ScrollingFrame.CanvasSize = UDim2.new(0, 0, 5, 0)

	--local TextS = game:GetService("TextService")
	--local textSizeInPixels = TextS:GetTextSize(UserRequestInput.Text, UserRequestInput.TextSize, Enum.Font.SourceSansSemibold , UserRequestInput.AbsoluteSize) -- Returns a Vector2, not a UDim2, important to note. UserRequestInput.FontFace
	--ScrollingFrame.CanvasSize = UDim2.new(0, textSizeInPixels.X, 0, textSizeInPixels.Y)
end

-- Detect when the user's text within the userRequestInput text box changes, to dynamically resize the scrolling frame, to fit all the contents of the user request/responses from the API
UserRequestInput:GetPropertyChangedSignal("Text"):Connect(updateScrollingFrame)
UserRequestInput:GetPropertyChangedSignal("TextBounds"):Connect(updateScrollingFrame)

--------------------------End Dynamic Scrolling Frame Size for the Main User Request Input Text Box--------------------------------------------




----------------------------------API Key Text Input Box Behavior----------------------------------
--This is the input window and button where users input their API key for the selected provider--

-- Create API Key Input
local APIKeyInput = Instance.new("TextBox")
APIKeyInput.Size = UDim2.new(0.8, 0, 0.1, 0)
APIKeyInput.Position = UDim2.new(0.1, 0, 0.2, 0)
APIKeyInput.ClearTextOnFocus = false
APIKeyInput.Font = Enum.Font.SourceSans
APIKeyInput.TextSize = 12
APIKeyInput.TextColor3 = Color3.fromRGB(0, 0, 0)
APIKeyInput.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
APIKeyInput.Visible = false
APIKeyInput.Parent = Frame
APIKeyInput.Text = "Enter API Key..."

local APIKeyCorner = Instance.new("UICorner")
APIKeyCorner.CornerRadius = UDim.new(0, 4)
APIKeyCorner.Parent = APIKeyInput

-- Create Use API Key Button
local UseAPIKeyButton = Instance.new("TextButton")
UseAPIKeyButton.Size = UDim2.new(0.3, 0, 0.1, 0)
UseAPIKeyButton.Position = UDim2.new(0.35, 0, 0.32, 0)
UseAPIKeyButton.Text = "Use This API Key"
UseAPIKeyButton.Font = Enum.Font.SourceSansBold
UseAPIKeyButton.TextSize = 14
UseAPIKeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
UseAPIKeyButton.BackgroundColor3 = Color3.fromRGB(10, 37, 64)
UseAPIKeyButton.Visible = false
UseAPIKeyButton.Parent = Frame

local UseKeyCorner = Instance.new("UICorner")
UseKeyCorner.CornerRadius = UDim.new(0, 8)
UseKeyCorner.Parent = UseAPIKeyButton

-- This function clears the text input box when a user double-clicks inside the text input box.
local lastClickTimeAPIKeyInput = 0 --Theoretically we could combine this clear text input field functionality with the functionality that clears the request input box, since they're so similar, but it's easier for readability to isolate them.
APIKeyInput.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local currentTime = tick()
		if currentTime - lastClickTimeAPIKeyInput < 1 then
			APIKeyInput.Text = ""
		end
		lastClickTimeAPIKeyInput = currentTime
	end
end)

-- This button essentially "saves" the user's input for their API key when they hit the "UseAPIKey" button.
-- It could be nice to be able to save API provider selections, and API keys across user sessions. 
UseAPIKeyButton.MouseButton1Click:Connect(function()
	apiKey = APIKeyInput.Text
	APIKeyInput.Visible = false
	UseAPIKeyButton.Visible = false
	ScrollingFrame.Visible = true
	SendButton.Visible = true
	SettingsMenu.Visible = false
end)
----------------------------------End API Key Text Input Box Behavior----------------------------------



------------------------------API Provider Dropdown menu (Top Right Button)----------------------------------------
--This is the top right button that's a dropdown where users can select which API provider to use--

-- Create API Provider Dropdown
local APIProviderDropdown = Instance.new("TextButton")
APIProviderDropdown.Size = UDim2.new(0.3, 0, 0.1, 0)
APIProviderDropdown.Position = UDim2.new(0.68, 0, 0.02, 0)
APIProviderDropdown.Text = "API Provider"
APIProviderDropdown.Font = Enum.Font.SourceSansBold
APIProviderDropdown.TextSize = 14
APIProviderDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
APIProviderDropdown.BackgroundColor3 = Color3.fromRGB(99, 91, 255)
APIProviderDropdown.Parent = Frame

local DropdownCorner = Instance.new("UICorner")
DropdownCorner.CornerRadius = UDim.new(0, 8)
DropdownCorner.Parent = APIProviderDropdown

-- Create Dropdown Menu
local DropdownMenu = Instance.new("Frame")
DropdownMenu.Size = UDim2.new(0.3, 0, 0.3, 0)
DropdownMenu.Position = UDim2.new(0.68, 0, 0.12, 0)
DropdownMenu.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DropdownMenu.Visible = false
DropdownMenu.ZIndex = 10
DropdownMenu.Parent = Frame

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(0, 4)
MenuCorner.Parent = DropdownMenu

-- Create Dropdown Options
local options = {"OpenAI GPT 4o", "Anthropic 3.5 Sonnet", "Google 1.5 Pro"}
--Create a dropdown button in the container frame  for each service we add. For loop and table is used here to make it easier to add new providers quickly.
for i, option in ipairs(options) do
	local OptionButton = Instance.new("TextButton")
	OptionButton.Size = UDim2.new(1, 0, 0.33, 0) --This .33 could/should probably become a variable as the position one is, otherwise our sizing doesn't scale past 3 providers.
	OptionButton.Position = UDim2.new(0, 0, (i-1) * 0.33, 0)
	OptionButton.Text = option
	OptionButton.Font = Enum.Font.SourceSans
	OptionButton.TextSize = 14
	OptionButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	OptionButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	OptionButton.Parent = DropdownMenu
	OptionButton.ZIndex = 11

	OptionButton.MouseButton1Click:Connect(function()
		selectedAPIProvider = option
		APIProviderDropdown.Text = "API Provider: " .. option
		DropdownMenu.Visible = false
		if apiKey then 
			APIKeyInput.Text = apiKey
		end
		APIKeyInput.Visible = true
		UseAPIKeyButton.Visible = true
		ScrollingFrame.Visible = false
		SendButton.Visible = false
		SettingsMenu.Visible = false
	end)
end

-- Toggle Dropdown Menu
APIProviderDropdown.MouseButton1Click:Connect(function()
	DropdownMenu.Visible = not DropdownMenu.Visible
	if DropdownMenu.Visible then
		DropdownMenu.ZIndex = 10
		ScrollingFrame.Visible = false
		SendButton.Visible = false
		SettingsMenu.Visible = false
		ChangesView.Visible = false
		if APIKeyInput.Text ~= "Enter API Key..." then
			UseAPIKeyButton.Visible = true
			APIKeyInput.Visible = true
		end
	end
end)
------------------------------End API Provider Dropdown menu (Top Right Button)----------------------------------------




-------------------------Loading Indicator--------------------------------
--This is the spinning gear icon that shows while we wait for a response--

-- Create Loading Indicator
local LoadingIndicator = Instance.new("ImageLabel")
LoadingIndicator.Size = UDim2.new(0, 40, 0, 40)
LoadingIndicator.Position = UDim2.new(0.48, 0, 0.48, 0)
LoadingIndicator.Image = "rbxassetid://11413080534"  
LoadingIndicator.BackgroundTransparency = 1
LoadingIndicator.Visible = false
LoadingIndicator.Parent = Frame

-- Create rotation animation for the loading indicator
local rotationAnimation = Instance.new("NumberValue")
rotationAnimation.Parent = LoadingIndicator

local animationConnection
local function startRotationAnimation()
	if animationConnection then
		animationConnection:Disconnect()
	end
	animationConnection = game:GetService("RunService").RenderStepped:Connect(function(dt)
		LoadingIndicator.Rotation = (LoadingIndicator.Rotation + 100 * dt) % 360
	end)
end

local function stopRotationAnimation()
	if animationConnection then
		animationConnection:Disconnect()
		animationConnection = nil
	end
end
------------------------End Loading Indicator-----------------------------



------------------------Core functionality starts here------------------------
-- This function's purpose is to find the "Line number" that code changes have occurred. It is used for jumping to the location of code changes within scripts, so user's don't have to scroll/search for them. 
local function findLineNumber(scriptSource, newCode, previousCode)

	local lines = scriptSource:split("\n")

	-- First, try to find the new code
	for i, line in ipairs(lines) do
		if line:find(newCode:gsub("[-%(%)%.%+%[%]%$%^%%%?%*]", "%%%0"), 1, true) then
			return i
		end
	end

	-- If new code not found, look for the previous code (it might be commented out)
	for i, line in ipairs(lines) do
		if line:find(previousCode:gsub("[-%(%)%.%+%[%]%$%^%%%?%*]", "%%%0"), 1, true) then
			return i
		end
	end

	return 1  -- Default to line 1 if not found
end

--This function was implemented to create undo points in a more standardized way so that we could revert back to old versions. It's not being used. Instead we have similar functionality not exported to a sub-function.
--We could actually just delete this function since it's never being called. It was here because I was previously trying to simplify the process using a different Roblox API changehistory service, but we're actually achieving this functionality within our other functions in a more readable way. 
--    We could go back to this kind of approach, and we also could implement functionality that would enable users to do "Ctrl+Z"/"Ctrl+SHFT+Z" functionality with the changehistory service (or similar), as "Ctrl+Z" functionality doesn't work with how we're changing script contents currently.
-- local function createUndoPoint()
-- 	-- Store changes for the current index
-- 	changeHistoryStack[currentChangeIndex] = scriptBackups
-- 	currentChangeIndex += 1

-- end


-- This function concatenates our standard API prefix/postfix, our user's codebase, and the user request.
local function createAPIPrompt(codebase, userRequest, mode)
	if mode == "Code" then
		return [[
            Please analyze the following codebase and make the requested changes. You need to determine the number of actions required to implement the change, the type of each action, and each action should be it's own table with the appropriate values in the table of changes. 
            
            There are 3 types of action: 
            1) Modify Existing Code: Identify the service, script, and code chunk relevant to the action required by the user's prompt, respond with the original code snippet as the "previousCode" value, the "newCode" value which is the updated version of the code snippet, and the "explanation" which is a text explanation of the changes made and the part of the user's request that prompted those changes. 
            2) AddOnly: Add new code without modifying existing code snippets. Identify the service and script relevant most relevant to the action required by the user's prompt, only if there is an appropriate service and script already existing do we proceed with this type of action, otherwise we do a "NewScript" action. If we have identified a service and script properly relevant, we respond with this "AddOnly" action and it's "newCode" value which is the new code snippet, and the "explanation" which is a text explanation of the changes made and the part of the user's request that prompted those changes. 
            3) NewScript: Create a new script and populate it with the code required to complete the requirements. This is the action type that occurs when we cannot identify an appropriately relevant pre-existing service and script, or service, script, and code chunk to warrant a "ModifyExisting" or a "AddOnly" action. In this scenario we create a new script and populate it with the code required to complete the requirement. 
            
            Respond with a JSON structure containing the appropriate actions to complete the requirements that were requested.
            
            User Request: ]] .. '"' .. userRequest .. '"' .. [[  
            
            Codebase: ]] .. '"' .. codebase .. '"'.. [[ 
            
            Remember that you need to consider the dependencies your newCode will need, and if the previousCode doesn't have them, they need to be in your newCode at the appropriate place in the script: 
                - If it's a ModifyExisting action type or AddOnly action type and your newCode response has dependencies it relies on, if the if your previouscode doesn't have the required dependencies you need to add in the necessary dependencies to the appropriate location of the newcode. An example is if your newCode had "ReplicatedStorage.RoundStartBindableEvent.Event:Connect(onBindableEvent)" and the previousCode didn't already have "local ReplicatedStorage = game:getservice("ReplicatedStorage")" you would need to add that dependency declaration to the top of the script in your newcode, etc...
                - If it's a NewScript action type, then obviously the required dependencies won't be there yet so you need to include them.
            
            Keep in mind that Roblox development requires that dependencies are chronologically defined in the order that they are used, you can't use a dependency if it wasn't defined on a previous line.
            
            Regarding your response in json structure please note: 
                1) We are using camelCase for our capitalization structure of the responses keys
                2) Please provide your response as a raw JSON object without any markdown formatting or code block indicators. Do not use triple backticks (```) or any other formatting around the JSON. The response should start with an opening curly brace ({) and end with a closing curly brace (}).
                3) Create a new script and populate it with the code required to complete the requirements. This is the action type that occurs when we cannot identify an appropriately relevant pre-existing service and script, or service, script, and code chunk to warrant a "ModifyExisting" or a "AddOnly" action. In this scenario we create a new script and populate it with the code required to complete the requirement. Specify whether it should be a regular Script or a LocalScript using the "scriptType" field.
            {
                "changes": [
                    {
                        "actionType": "ModifyExisting",
                        "previousCode": "Exact snippet of code to be replaced",
                        "newCode": "Updated version of the code snippet",
                        "scriptName": "Name of the script where the action is being implemented",
                        "serviceName": "Name of the service where the action is being implemented",
                        "lineNumber": "Line number on which the first line of the previouscode started",
                        "explanation": "Brief explanation of the changes made",
                        "scriptType": null
                    },
                    {
                        "actionType": "AddOnly",
                        "previousCode": null,
                        "newCode": "The new code snippet",
                        "scriptName": "Name of the script where the action is being implemented",
                        "serviceName": "Name of the service where the action is being implemented",
                        "lineNumber": "Line number on which the first line of the newcode starts",
                        "explanation": "Brief explanation of the changes made",
                        "scriptType": null
                    },
                    {
                        "actionType": "NewScript"
                        "previousCode": null,
                        "newCode": "The new code snippet",
                        "scriptName": "Name of the script where the action is being implemented",
                        "serviceName": "Name of the service where the action is being implemented",
                        "lineNumber": "Always return 1 for the result of lineNumber for NewScript events",
                        "explanation": "Brief explanation of the changes made",
                        "scriptType": "Script or LocalScript"
                    }
                ]
            }
            Only include the JSON in your response, without any additional text or formatting.
        ]]
		--If mode (set in the settings menu) is not "Code" then we're in question mode, and we just rip the codebase and the user's question off to the model with minimal prefix.
	else
		return "Answer the following question about this roblox game's codebase: " .. userRequest .. "\n\nCodebase: " .. codebase
	end
end

--This function is a helper for the SendToAPI function. Responses from the API providers have a ton of formatting text in them and structure that we don't need unless for debugging.
-- We may have actually removed the usage of the "Mode" parameter though, as ripping all this contextual structure out loses information that's valuable for when we copy/paste code suggestions.
--      Therefor this may actually just be a dead/redundant piece of functionality since we're not hitting mode == "Code" as true.
local function cleanAPIResponse(response, mode)
	if mode == "Code" then
		-- Remove any leading or trailing whitespace
		response = response:match("^%s*(.-)%s*$")

		-- Remove triple backticks and the word "json" if present
		response = response:gsub("^```json%s*", ""):gsub("^```%s*", ""):gsub("%s*```$", "")

		-- Ensure the response starts with { and ends with }
		if not response:match("^%s*{") or not response:match("}%s*$") then
			error("Invalid JSON response")
		end
	end

	return response
end

-- Function to structure our request to the AI API model, send request to the selected API, and return to the calling source our cleaned up response from the AI model. 
local function sendToAPI(scriptData, userRequest)
	local prompt = createAPIPrompt(HttpService:JSONEncode(scriptData), userRequest, currentMode)
	local url, headers, body


	if selectedAPIProvider == "OpenAI GPT 4o" then
		url = "https://api.openai.com/v1/chat/completions"
		headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = "Bearer " .. apiKey
		}
		body = HttpService:JSONEncode({
			model = "gpt-4",
			messages = {{role = "user", content = prompt}},
			max_tokens = 4096
		})
	elseif selectedAPIProvider == "Anthropic 3.5 Sonnet" then
		url = "https://api.anthropic.com/v1/messages"
		headers = {
			["Content-Type"] = "application/json",
			["x-api-key"] = apiKey,
			["anthropic-version"] = "2023-06-01",
			["anthropic-beta"] = "max-tokens-3-5-sonnet-2024-07-15"
		}
		body = HttpService:JSONEncode({
			model = "claude-3-5-sonnet-20240620",
			max_tokens = 8192,
			messages = {{role = "user", content = prompt}}
		})
	elseif selectedAPIProvider == "Google 1.5 Pro" then
		url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent"
		headers = {
			["Content-Type"] = "application/json",
		}
		body = HttpService:JSONEncode({
			contents = {{
				parts = {{text = prompt}}
			}},
			generationConfig = {
				temperature = 0.7,
				topK = 40,
				topP = 0.95,
				maxOutputTokens = 4096,
			},
		})
		url = url .. "?key=" .. apiKey
	else
		return "Error: Invalid API provider selected"
	end

	--We're doing the actual API 'sending' here, with our message contents mainly inside the "Body" variable. 
	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "POST",
			Headers = headers,
			Body = body
		})
	end)

	if success then
		if response.Success then
			--Roblox's HTTPService will structure the JSON response from the API for us so we can refer to it's individual elements.
			local responseData = HttpService:JSONDecode(response.Body)
			--Different API endpoints return different JSON structures so we need to clean them differently.
			if selectedAPIProvider == "OpenAI GPT 4o" then
				return cleanAPIResponse(responseData.choices[1].message.content)
			elseif selectedAPIProvider == "Anthropic 3.5 Sonnet" then
				return cleanAPIResponse(responseData.content[1].text)
			elseif selectedAPIProvider == "Google 1.5 Pro" then
				return cleanAPIResponse(responseData.candidates[1].content.parts[1].text)
			end
			--This is the case where we do get a response, but it's an error/failed response with an error message.
		else 
			local errorData = HttpService:JSONDecode(response.Body)
			local errorMessage = errorData.error and errorData.error.message or "Unknown API error"
			return "Error: " .. errorMessage
		end
		--This is the case where we don't get a response from the API at all (so no error message from the AI model provider), indicating something wrong with our Roblox side of things, not our structure of sent message to the API.
	else
		return "Error: " .. tostring(response)
	end
end

-- This function applies code changes suggested by the API response. 
local function applyCodeChanges(apiResponse)
	local cleanedResponse = cleanAPIResponse(apiResponse)
	local changes = HttpService:JSONDecode(cleanedResponse).changes

	for _, change in ipairs(changes) do
		-- Handle nested services within StarterPlayer
		local service
		if change.serviceName == "StarterPlayerScripts" or change.serviceName == "StarterCharacterScripts" then
			service = game:GetService("StarterPlayer")[change.serviceName]
		else
			service = game:GetService(change.serviceName)
		end

		if service then
			local script = service:FindFirstChild(change.scriptName, true)

			-- Store whether the script existed before
			change.scriptExisted = script ~= nil

			if change.actionType == "ModifyExisting" or change.actionType == "AddOnly" then
				if script then
					-- Store the entire previous source before modification
					change.fullPreviousSource = script.Source

					local currentSource = script.Source
					local lines = currentSource:split("\n")
					local prevCodeLines = change.previousCode and change.previousCode:split("\n") or {}
					local newCodeLines = change.newCode:split("\n")
					local lineNumber = tonumber(change.lineNumber) or 1

					-- Adjust lineNumber if necessary
					lineNumber = math.max(1, lineNumber)

					-- Comment out the previous code starting from lineNumber
					for i = 1, #prevCodeLines do
						local index = lineNumber + i - 1
						if index <= #lines then
							lines[index] = "-- " .. lines[index]
						end
					end

					-- Insert new code after the commented lines
					for i, newLine in ipairs(newCodeLines) do
						table.insert(lines, lineNumber + #prevCodeLines + i - 1, newLine)
					end

					local updatedSource = table.concat(lines, "\n")
					script.Source = updatedSource

					-- Close the script document if it's open
					local scriptDocument = ScriptEditorService:FindScriptDocument(script)
					if scriptDocument then
						local success, err = scriptDocument:CloseAsync()
						if not success then
							warn("Failed to close script document: ", err)
						end
					end

					-- Open the script at the modified line
					plugin:OpenScript(script, lineNumber)
				else
					warn("Script not found: " .. change.serviceName .. "." .. change.scriptName)
				end
			elseif change.actionType == "NewScript" then
				-- Create new script
				local newScript
				if change.scriptType == "LocalScript" then
					newScript = Instance.new("LocalScript")
				else
					newScript = Instance.new("Script")
				end
				newScript.Name = change.scriptName
				newScript.Source = change.newCode
				newScript.Parent = service

				-- Assign the new script to `script` variable for consistency
				script = newScript

				-- No previous source since it's a new script
				change.fullPreviousSource = nil

				-- Open the new script
				plugin:OpenScript(script, 1)
			end

			-- Add the change to the history stack
			table.insert(changeHistoryStack, change)
		else
			warn("Failed to find service: " .. change.serviceName)
		end
	end

	currentChangeIndex = #changeHistoryStack

	-- Update the GUI elements
	undoButton.Visible = true
	ViewChangesButton.Visible = true
	updateChangesView()
end




-- -- Function to serialize scripts from a specific service. (Meaning get all the scripts contents into a table), it's not currently being used at all.
-- local function serializeScriptsFromService(service)
-- 	local scriptsData = {}

-- 	for _, script in ipairs(service:GetDescendants()) do
-- 		if script:IsA("Script") or script:IsA("LocalScript") or script:IsA("ModuleScript") then
-- 			table.insert(scriptsData, {
-- 				Name = script.Name,
-- 				ClassName = script.ClassName,
-- 				ParentName = script.Parent and script.Parent.Name or "None",
-- 				Source = script.Source
-- 			})
-- 		end
-- 	end


-- 	return scriptsData
-- end


-- This functions goes through our selected services from the settings menu and together to send to API service. 
local function serializeAllScripts()
	local allScriptsData = {}
	scriptBackups = {} --This should probably be renamed/moved as we have the same variable declared globally for the script. We're basically wiping it here.
	existingScripts = {}  -- Reset the existing scripts list

	for _, checkbox in ipairs(checkboxes) do
		if selectedServices[checkbox.service] then
			local serviceBeingChecked = checkbox.service
			local servicesToCheck = {serviceBeingChecked}

			-- Handle nested services within StarterPlayer
			if serviceBeingChecked == game:GetService("StarterPlayer") then
				table.insert(servicesToCheck, serviceBeingChecked.StarterPlayerScripts)
				table.insert(servicesToCheck, serviceBeingChecked.StarterCharacterScripts)
			end

			for _, service in ipairs(servicesToCheck) do
				for _, script in ipairs(service:GetDescendants()) do
					if script:IsA("Script") or script:IsA("LocalScript") or script:IsA("ModuleScript") then
						local scriptData = {
							Name = script.Name,
							ClassName = script.ClassName,
							ParentName = script.Parent and script.Parent.Name or "None", --Could be nice to get the full hierarchy of ancestors if it's a nested script with multiple parents until the service.
							Source = script.Source
						}

						table.insert(allScriptsData, scriptData)
						scriptBackups[script] = script.Source --Could be nice to add some kind of versioning signal/flag here if we make multiple iterated adjustments to a script, otherwise we're over-writing to the most recent changes each time. Will require more changes than just here.
						table.insert(existingScripts, script)
					end
				end
			end
		end
	end


	return allScriptsData
end


local function revertChanges()
	if currentChangeIndex > 0 then
		-- Get the last change
		local lastChange = changeHistoryStack[currentChangeIndex]

		-- Handle nested services within StarterPlayer
		local service
		if lastChange.serviceName == "StarterPlayerScripts" or lastChange.serviceName == "StarterCharacterScripts" then
			service = game:GetService("StarterPlayer")[lastChange.serviceName]
		else
			service = game:GetService(lastChange.serviceName)
		end

		if service then
			local script = service:FindFirstChild(lastChange.scriptName, true)

			if lastChange.actionType == "ModifyExisting" or lastChange.actionType == "AddOnly" then
				if script then
					if lastChange.fullPreviousSource then
						-- Restore the entire previous source
						script.Source = lastChange.fullPreviousSource

						-- Close the script document if it's open
						local scriptDocument = ScriptEditorService:FindScriptDocument(script)
						if scriptDocument then
							local success, err = scriptDocument:CloseAsync()
							if not success then
								warn("Failed to close script document: ", err)
							end
						end

						-- Open the script at the modified line
						plugin:OpenScript(script, tonumber(lastChange.lineNumber) or 1)
					else
						warn("No previous source stored for script: " .. lastChange.scriptName)
					end
				else
					warn("Script not found: " .. lastChange.serviceName .. "." .. lastChange.scriptName)
				end
			elseif lastChange.actionType == "NewScript" then
				if script then
					-- Destroy the newly created script
					script:Destroy()
				else
					warn("Script not found: " .. lastChange.serviceName .. "." .. lastChange.scriptName)
				end
			end
		else
			warn("Service not found: " .. lastChange.serviceName)
		end

		-- Remove the last change from the history stack
		table.remove(changeHistoryStack, currentChangeIndex)
		currentChangeIndex = #changeHistoryStack

		ResponseText.Text = "Last change undone."
		ResponseText.TextColor3 = Color3.fromRGB(36, 180, 126)

		-- Update Changes View
		updateChangesView()

		-- Update undo button visibility
		if currentChangeIndex == 0 then
			undoButton.Visible = false
			ViewChangesButton.Visible = false
		end
	else
		ResponseText.Text = "No changes to undo"
		ResponseText.TextColor3 = Color3.fromRGB(234, 76, 137)
	end
end


-- Connect the revertChanges function to the undo button's click event
undoButton.MouseButton1Click:Connect(revertChanges)



-- This function handles implementing code changes suggested by the API response.
local function updateCode()
	local userRequest = UserRequestInput.Text
	local serializedScripts = serializeAllScripts()

	ResponseText.Text = ""
	ResponseText.TextColor3 = Color3.fromRGB(66, 84, 102)  -- Reset to default color

	-- Hide input elements and show loading indicator
	ScrollingFrame.Visible = false
	SendButton.Visible = false
	LoadingIndicator.Visible = true
	startRotationAnimation()

	-- Use a coroutine to prevent freezing the UI
	coroutine.wrap(function()
		local apiResponse = sendToAPI(serializedScripts, userRequest)

		-- Hide loading indicator and show input elements
		LoadingIndicator.Visible = false
		stopRotationAnimation()
		ScrollingFrame.Visible = true
		SendButton.Visible = true

		if apiResponse:sub(1, 5) == "Error" then
			ResponseText.Text = apiResponse
			ResponseText.TextColor3 = Color3.fromRGB(234, 76, 137)
		else
			if currentMode == "Code" then
				applyCodeChanges(apiResponse)
				ResponseText.Text = "Success"
				ResponseText.TextColor3 = Color3.fromRGB(36, 180, 126)
				undoButton.Visible = true
			else
				-- Display the response in the UserRequestInput for Question mode
				UserRequestInput.Text = apiResponse
				updateScrollingFrame()
				ResponseText.Text = "Response received"
				ResponseText.TextColor3 = Color3.fromRGB(36, 180, 126)
			end
		end
	end)()

end

-- Connect the updateCode function to the send button's click event
SendButton.MouseButton1Click:Connect(updateCode)


-- Create a toolbar button to toggle the widget (This is what the user sees in the top of the plugin's bar to open the plugin GUI)
local toolbar = plugin:CreateToolbar("Code Updater")
local toggleButton = toolbar:CreateButton("RoPilot Coding Agent", "RoPilot Coding Agent", "")

-- Toggle button handler
toggleButton.Click:Connect(function()
	pluginGui.Enabled = not pluginGui.Enabled
end)


------GUI Button Click Handlers To Hide Relevant GUI Elements---------
-- Settings button click handler
SettingsButton.MouseButton1Click:Connect(function()
	local isSettingsVisible = SettingsMenu.Visible
	SettingsMenu.Visible = not isSettingsVisible
	ScrollingFrame.Visible = isSettingsVisible
	SendButton.Visible = isSettingsVisible
	APIKeyInput.Visible = false
	UseAPIKeyButton.Visible = false
	ChangesView.Visible = false
end)


-- View Changes button click handler
ViewChangesButton.MouseButton1Click:Connect(function()
	local isChangesViewVisible = ChangesView.Visible
	ChangesView.Visible = not isChangesViewVisible
	ScrollingFrame.Visible = isChangesViewVisible
	SendButton.Visible = isChangesViewVisible
	APIKeyInput.Visible = false
	UseAPIKeyButton.Visible = false
	SettingsMenu.Visible = false

	updateChangesView()
end)
------End GUI Button Click Handlers To Hide Relevant GUI Elements---------


-- Modify the init function
local function init()
	ScrollingFrame.Visible = false
	SendButton.Visible = false
	APIKeyInput.Visible = false
	UseAPIKeyButton.Visible = false
	SettingsMenu.Visible = false
	LoadingIndicator.Visible = false
	ChangesView.Visible = false
	ViewChangesButton.Visible = false
	updateToggleAppearance()
end

-- Call the initialization function
init()
