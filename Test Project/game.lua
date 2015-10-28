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
		stage:addChild(self.background)
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
	local packet = {type="events"}
	if self.engine == nil then
		print("Engine hasn't been set!")
		return
	end
	packet.events = self.engine:getEvents()
	if # packet.events > self.maxPlayerMoves then
		print("That's too many moves! Check your loops to see how many instructions are being run.")
		return
	end
	self.netAdapter:sendMoves(self, packet)
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

function CollectGame(netAdapter)
	local self = Game(netAdapter, "images/grassbackground.png", false)
	self.gameType = "Collect"
	local gameState = self.netAdapter:getGameState(self.gameType)
	local setupGrid = function(imagePath, gameState, testing)
		if testing then
			print("testing")
			return
		end
		self.grid = gridMod.Grid(imagePath, self.gameType, gameState, testing)
		self.grid:setCollectibleAt(1, 4,  collectibleMod.ShovelRepairPowerUp())
		self.grid:setCollectibleAt(4, 1,  collectibleMod.MetalDetectorPowerUp())
	end
	
	local setupPlayers = function(gameState, testing)
		self.maxPlayerMoves = 8
		self.player1 = playerMod.Player(self.grid, true, self.maxPlayerMoves, testing)
		self.player2 = playerMod.Player(self.grid, false, self.maxPlayerMoves, testing)
		self.leprechaun = playerMod.Leprechaun(self.grid, self.maxPlayerMoves + 1, gameState.lepStart, testing)
	end
	
	local setSound = function(testing)
		if testing then
			return
		end
		local music = musicMod.Music.new("audio/music.mp3")
		music:on()
	end
	
	local setupPanel = function(numButtons)
		rightButton = buttonMod.InputButton(self.engine, "images/arrow-right.png",
		"RightMove", 1, numButtons)
		downButton = buttonMod.InputButton(self.engine, "images/arrow-down.png", 
		"DownMove", 2, numButtons)
		leftButton = buttonMod.InputButton(self.engine, "images/arrow-left.png", 
		"LeftMove", 3, numButtons)
		upButton = buttonMod.InputButton(self.engine, "images/arrow-up.png", 
		"UpMove", 4, numButtons)
		digButton = buttonMod.InputButton(self.engine, "images/shovel.png", 
		"Dig", 5, numButtons)
		loopStart = buttonMod.InputButton(self.engine, "images/loop-start.png", 
		"LoopStart", 6, numButtons)
		loopEnd = buttonMod.InputButton(self.engine, "images/loop-end.png", 
		"LoopEnd", 7, numButtons)
		
		local buttonImage = Bitmap.new(Texture.new("images/go.png"))
		scaleX = WINDOW_WIDTH / buttonImage:getWidth() / 10.5
		scaleY = WINDOW_HEIGHT / buttonImage:getHeight() / 15
		
		local button = Button.new(buttonImage, buttonImage, function()
			--self:reset() 
			self:sendMoves()
			self.engine:clearBuffer()
			end)
		button:setScale(scaleX, scaleY)
		xPos = numButtons * (WINDOW_WIDTH / (numButtons + 1))
		yPos = WINDOW_HEIGHT / 20
		button:setPosition(xPos, yPos)
		stage:addChild(button)
	end
	self.setupPanel = setupPanel
	setupGrid("images/dirtcell.png", gameState, false)
	setupPlayers(gameState, false)
	self:setupEngine(8, false)
	setSound(false)
	
	local runEvents = function(events)
		print_r(events)
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
		self.player1.action = true
		self.player2.action = true
		self.leprechaun.action = true
		self.player1:endTurn()
		self.player2:endTurn()
	end
	
	local update = function()
		self.player1:update()
		self.player2:update()
		self.leprechaun:update()
	end
	
	local exit = function()
		stage:removeChild(self.background)
		self.grid:destroy()
		self.player1:destroy()
		self.player2:destroy()
		self.leprechaun:destroy()
	end
	self.runEvents = runEvents
	self.resetTurn = resetTurn
	return {
		runEvents = runEvents,
		update = update,
		exit = exit
	}
	
end

M.CollectGame = CollectGame
return M
