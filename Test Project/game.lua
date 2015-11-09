local M = {}

local gridMod = require('grid')
local playerMod = require('player')
local engineMod = require('inputengine')
local buttonMod = require('inputbutton')
local commandMod = require('command')
local collectibleMod = require('collectible')
local musicMod = require('music')

local Game = {}
Game.__index = Game

setmetatable(Game, {
  __call = function (cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})

function Game:_init(netAdapter, imagePath, testing)
	self.netAdapter = netAdapter
	self:setBackground(imagePath, testing)
end

function Game:setBackground(imagePath, testing)
	if not testing then
		self.background = Bitmap.new(Texture.new(imagePath))
	end
end

function Game:setupGrid(imagePath, gameState, testing)
	print("Grid setup not implemented!")
end

function Game:setupPlayers(gameState, testing)
	print("Player setup not implemented!")
end

function Game:setupEngine(numButtons, testing)
	self.engine = engineMod.InputEngine(self)
	if testing then
		return
	end
	self.setupPanel(numButtons)
end

function Game:setupPanel()
	print("Game panel not implemented!")
end

function Game:setSound()
	print("Sound not implemented!")
end

function Game:sendMoves()
	if self.engine == nil then
		print("Engine hasn't been set!")
		return
	end
	local events = self.engine:getEvents()
	if # events > self.maxPlayerMoves then
		print("That's too many moves! Check your loops to see how many instructions are being run.")
		return
	end
	self.netAdapter:sendMoves(self, events)
end

function Game:runEvents(events)
	print("runEvents not implemented!")
end

function Game:resetTurn()
	print ("resetTurn not implemented!")
end

function Game:reset()
	print("Reset not implemented!")
end

function Game:update()
	print("Update not implemented!")
end

function Game:exit()
	print("Exit not implemented")
end

function CollectGame(netAdapter, hostBool)
	local self = Game(netAdapter, "images/grassbackground.png", false)
	self.host = hostBool
	
	local setupGrid = function(imagePath, gameState, testing)
		if testing then
			print("testing")
			return
		end
		self.grid = gridMod.CollectGrid(imagePath, self.gameType, gameState)
	end
	
	local setupPlayers = function(gameState, testing)
		self.maxPlayerMoves = 8
		self.player1 = playerMod.CollectPlayer(self.grid, 1, self.maxPlayerMoves, testing)
		self.player2 = playerMod.CollectPlayer(self.grid, 2, self.maxPlayerMoves, testing)
		self.leprechaun = playerMod.Leprechaun(self.grid, self.maxPlayerMoves + 1, gameState.celldata.lepStart, testing)
	end
	
	local setSound = function(testing)
		if testing then
			return
		end
		local music = musicMod.Music.new("audio/music.mp3")
		--music:on()
	end
	
	local setupPanel = function(numButtons)
		--move this stuff into panel object
		
		self.rightButton = buttonMod.InputButton(self.engine, "images/arrow-right.png",
		"RightMove", 1, numButtons)
		self.downButton = buttonMod.InputButton(self.engine, "images/arrow-down.png", 
		"DownMove", 2, numButtons)
		self.leftButton = buttonMod.InputButton(self.engine, "images/arrow-left.png", 
		"LeftMove", 3, numButtons)
		self.upButton = buttonMod.InputButton(self.engine, "images/arrow-up.png", 
		"UpMove", 4, numButtons)
		self.digButton = buttonMod.InputButton(self.engine, "images/shovel.png", 
		"Dig", 5, numButtons)
		self.loopStart = buttonMod.InputButton(self.engine, "images/loop-start.png", 
		"LoopStart", 6, numButtons)
		self.loopEnd = buttonMod.InputButton(self.engine, "images/loop-end.png", 
		"LoopEnd", 7, numButtons)
		
		local buttonImage = Bitmap.new(Texture.new("images/go.png"))
		local scaleX = WINDOW_WIDTH / buttonImage:getWidth() / 10.5
		local scaleY = WINDOW_HEIGHT / buttonImage:getHeight() / 15
		
		self.goButton = Button.new(buttonImage, buttonImage, function()
			--self:reset() 
			self:sendMoves()
			self.engine:clearBuffer()
			end)
		self.goButton:setScale(scaleX, scaleY)
		local xPos = numButtons * (WINDOW_WIDTH / (numButtons + 1))
		local yPos = WINDOW_HEIGHT / 20
		self.goButton:setPosition(xPos, yPos)
		
		
		
	end
	
	
	local runEvents = function(events)
		--print_r(events)
		if events.p1 == nil or events.p2 == nil then
			print("unsupported event format")
			return
		end
		for index,value in ipairs(events.p1) do
			local eventObjConst = commandMod.getEvent(value)
			local eventObj = eventObjConst(self.player1, 1, index)
			table.insert(self.player1.loadedMoves, eventObj)
		end
		for index,value in ipairs(events.p2) do
			local eventObjConst = commandMod.getEvent(value)
			local eventObj = eventObjConst(self.player2, 1, index)
			table.insert(self.player2.loadedMoves, eventObj)
		end
		for index,value in ipairs(events.lep) do
			local eventObjConst = commandMod.getEvent(value)
			local eventObj = eventObjConst(self.leprechaun, 1, index)
			table.insert(self.leprechaun.loadedMoves, eventObj)
		end
		self.resetTurn()
	end
	
	local resetTurn = function()
		self.player1.setAction(true)
		self.player2.setAction(true)
		self.leprechaun.setAction(true)
		self.player1.endTurn()
		self.player2.endTurn()
	end
	
	local finished = {false, false, false}
	local update = function()
		
		local p1ActionBefore = self.player1.getAction()
		self.player1.update()
		local p1ActionAfter = self.player1.getAction()
		if p1ActionBefore and not p1ActionAfter then
			finished[1] = true
		end
		local p2ActionBefore = self.player2.getAction()
		self.player2.update()
		local p2ActionAfter = self.player2.getAction()
		if p2ActionBefore and not p2ActionAfter then
			finished[2] = true
		end
		local leprechaunActionBefore = self.leprechaun.getAction()
		self.leprechaun.update()
		local leprechaunActionAfter = self.leprechaun.getAction()
		if leprechaunActionBefore and not leprechaunActionAfter then
			finished[3] = true
		end
		if finished[1] and finished[2] and finished[3] then
			--if player one
			finished = {false, false, false}
			if self.host then
				self.uploadLocations()
			else
				self.netAdapter:startRecv()
			end
		end
	end
	
	local destroy = function()
		stage:removeChild(self.background)
		self.grid.destroy()
		self.player1.destroy()
		self.player2.destroy()
		self.leprechaun.destroy()
		
		
		self.rightButton:destroy()
		self.downButton:destroy()
		self.leftButton:destroy()
		self.upButton:destroy()
		self.digButton:destroy()
		self.loopStart:destroy()
		self.loopEnd:destroy()
		
		stage:removeChild(self.goButton)
		
		stage:removeEventListener(Event.ENTER_FRAME, self.update)
	end
	
	local show = function()
		stage:addChild(self.background)
		self.grid.show()
		self.player1.show()
		self.player2.show()
		self.leprechaun.show()
		
		self.rightButton:show()
		self.downButton:show()
		self.leftButton:show()
		self.upButton:show()
		self.digButton:show()
		self.loopStart:show()
		self.loopEnd:show()
		
		stage:addChild(self.goButton)
		
		stage:addEventListener(Event.ENTER_FRAME, self.update)
	end
	
	local gameSetup = function(gameState)
	--print_r(gameState)
		self.setupGrid("images/dirtcell.png", gameState, false)
		self.setupPlayers(gameState, false)
	end
	
	local uploadLocations = function()
		local locations = {
		p1={x=self.player1.x, y=self.player1.y},
		p2={x=self.player2.x, y=self.player2.y},
		lep={x=self.leprechaun.x, y=self.leprechaun.y}
		}
		self.netAdapter:uploadLocations(locations)
		
	end
	
	local updateLocations = function(locations)
	
	end
	
	self.gameType = "Collect"
	local gameState = self.netAdapter:getGameState(self.gameType)
	
	self.setupPanel = setupPanel
	--setupGrid("images/dirtcell.png", gameState, false)
	--setupPlayers(gameState, false)
	self:setupEngine(8, false)
	setSound(false)
	
	self.updateLocations = updateLocations
	self.uploadLocations = uploadLocations
	self.runEvents = runEvents
	self.resetTurn = resetTurn
	self.setupGrid = setupGrid
	self.setupPlayers = setupPlayers
	self.update = update
	
	return {
		runEvents = runEvents,
		update = update,
		exit = exit,
		show = show,
		destroy = destroy,
		gameSetup = gameSetup,
		updateLocations = updateLocations
	}

end

M.CollectGame = CollectGame
return M