-- program is being exported under the TSU exception

gameSelect = Core.class(Sprite)

local spacing = 50
local buttonWidth = 35
local font = TTFont.new("fonts/arial-rounded.ttf", 20)

--[[
To add a new row of buttons for a game, just call self:addGame() and pass in the name of the game.
]]
function gameSelect:init(mainMenu)
	local game1Text = TextField.new(font, "Space Collectors")
	local easyDiffText = TextField.new(font, "Easy")
	local midDiffText = TextField.new(font, "Normal")
	local hardDiffText = TextField.new(font, "Hard")
	self.numRows = 1
	self.rowVals = {easyDiffText:getHeight() + (spacing / 2) + game1Text:getHeight()}
	self.firstCol = game1Text:getWidth() / 2
	self.secondCol = game1Text:getWidth() + spacing + (easyDiffText:getWidth() / 2)
	self.thirdCol = self.secondCol + (easyDiffText:getWidth() / 2) + spacing + (midDiffText:getWidth() / 2)
	self.fourthCol = self.thirdCol + (midDiffText:getWidth() / 2) + spacing + (hardDiffText:getWidth() / 2)
	game1Text:setPosition(self.firstCol - (game1Text:getWidth() / 2), self.rowVals[self.numRows] - (game1Text:getHeight() / 2))
	easyDiffText:setPosition(self.secondCol - (easyDiffText:getWidth() / 2), 0)
	midDiffText:setPosition(self.thirdCol - (midDiffText:getWidth() / 2), 0)
	hardDiffText:setPosition(self.fourthCol - (hardDiffText:getWidth() / 2), 0)
	self:addChild(game1Text)
	self:addChild(easyDiffText)
	self:addChild(midDiffText)
	self:addChild(hardDiffText)
	self.buttonList = {}
	self.checkedButtons = {}
	self:addButtons(self.rowVals[self.numRows])
	self:addGame("Zombie Survivors")
	self:addGame("Game 3")
	
end

function gameSelect:addGame(name)
	local gametext = TextField.new(font, name)
	local newRow = self.rowVals[self.numRows] + spacing + gametext:getHeight()
	table.insert(self.rowVals, newRow)
	self.numRows = self.numRows + 1
	gametext:setPosition(self.firstCol - (gametext:getWidth() / 2), self.rowVals[self.numRows] - (gametext:getHeight()/2))
	self:addChild(gametext)
	self:addButtons(self.rowVals[self.numRows], name)
end

function inTable(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then return key end
    end
    return false
end

function gameSelect:addButtons(rowVal, name)
	local uncheckedBox1 = Bitmap.new(Texture.new("images/unchecked.png"))
	local uncheckedBox2 = Bitmap.new(Texture.new("images/unchecked.png"))
	local uncheckedBox3 = Bitmap.new(Texture.new("images/unchecked.png"))
	local checkedBox1 = Bitmap.new(Texture.new("images/checked.png"))
	local checkedBox2 = Bitmap.new(Texture.new("images/checked.png"))
	local checkedBox3 = Bitmap.new(Texture.new("images/checked.png"))
	buttonFunc = function()
		for i,v in ipairs(self.buttonList) do
			--print("Button " .. i .. ": ")
			--print(v.game)
			--print(v.diff)
			if v.isChecked then
				if inTable(self.checkedButtons, v) then
				elseif table.getn(self.checkedButtons) >= 3 then
					--[[local alertDialog = AlertDialog.new("Too Many Choices!", "You can only pick three game categories!\nUnselect one to pick another.", "Close")
					local function onComplete(event)
						v:toggle()
					end
					alertDialog:addEventListener(Event.COMPLETE, onComplete)
					alertDialog:show()]]
					v:disable()
				else
					table.insert(self.checkedButtons, v)
					if table.getn(self.checkedButtons) == 3 then
						print("disabled")
						self:disableUnchecked()
					end
				end
			else
				buttonIndex = inTable(self.checkedButtons, v)
				if buttonIndex then
					table.remove(self.checkedButtons, buttonIndex)
				else
					
				end
				self:enableButtons()
			end
		end
	end
	
	local easyButton = GameSelectRadioButton.new(uncheckedBox1, checkedBox1, buttonFunc)
	local midButton = RadioButton.new(uncheckedBox2, checkedBox2, buttonFunc)
	local hardButton = RadioButton.new(uncheckedBox3, checkedBox3, buttonFunc)
	local adjRowVal = rowVal - buttonWidth
	easyButton.diff = "easy"
	midButton.diff = "medium"
	hardButton.diff = "hard"
	easyButton.game = name
	midButton.game = name
	hardButton.game = name
	easyButton:setPosition(self.secondCol - (easyButton:getWidth() / 2), adjRowVal)
	midButton:setPosition(self.thirdCol - (midButton:getWidth() / 2), adjRowVal)
	hardButton:setPosition(self.fourthCol - (hardButton:getWidth() / 2), adjRowVal)
	self:addChild(easyButton)
	self:addChild(midButton)
	self:addChild(hardButton)
	table.insert(self.buttonList, easyButton)
	table.insert(self.buttonList, midButton)
	table.insert(self.buttonList, hardButton)
end

function gameSelect:disableUnchecked()
	for i,v in ipairs(self.buttonList) do
		if not inTable(self.checkedButtons, v) then
			v:disable()
		end
	end
end

function gameSelect:enableButtons()
	for i,v in ipairs(self.buttonList) do
		v:enable()
	end
end

mainMenu = Core.class(BaseScreen)

function mainMenu:init(params)	
	local font = TTFont.new("fonts/arial-rounded.ttf", 20)
	self.sceneName = "Main Menu - Select Game"
	
	local gameSelectBox = gameSelect.new()
	gameSelectBox:setPosition((WINDOW_WIDTH / 2) - (gameSelectBox:getWidth() / 2), (WINDOW_HEIGHT / 2) - (gameSelectBox:getHeight() / 2))
	self:addChild(gameSelectBox)
	local submitButtonUp = Bitmap.new(Texture.new("images/submitButtonUp.png"))
	local submitButtonDown = Bitmap.new(Texture.new("images/submitButtonDown.png"))
	submitFunc = function() 
		mainMenu:sendSelected(gameSelectBox.checkedButtons)
		sceneManager:changeScene("gameWait", 1, SceneManager.crossfade, easing.outBack) 
	end
	local submitButton = CustomButton.new(submitButtonUp, submitButtonDown, submitFunc)
	submitButton:setPosition((WINDOW_WIDTH / 2) - (submitButton:getWidth() / 2) , WINDOW_HEIGHT - submitButton:getHeight() - 70)
	self:addChild(submitButton)
end

function mainMenu:sendSelected(checkedButtons)
	local choices = {}
	for i,v in ipairs(checkedButtons) do
		local choice = {}
		choice.game = v.game
		choice.diff = v.diff
		table.insert(choices, choice)
	end
	--netAdapter:browseGames(choices)
	
end

function mainMenu:getPreviousRow(rowVal, currentObj, newObj)
	return rowVal - (currentObj:getHeight()/2) - (spacing / 2) - (newObj:getHeight()/2) 
end

function mainMenu:getNextRow(rowVal, currentObj, newObj)
	return rowVal + (currentObj:getHeight()/2) + (spacing / 2) + (newObj:getHeight()/2)
end

function mainMenu:getNextCol(colVal, currentObj, newObj)
	return colVal + (currentObj:getWidth() / 2) + spacing + (newObj:getWidth() / 2)
end

function mainMenu:getPrevCol(colVal, currentObj, newObj)
	return colVal - (currentObj:getWidth() / 2) - spacing - (newObj:getWidth()/2)
end




