local M = {}

local width = application:getLogicalWidth()
local height = application:getLogicalHeight()

local Collectible = {}
Collectible.__index = Collectible

setmetatable(Collectible, {
  __call = function (cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end,
})
--[[
	This class defines collectibles in the game. Extend this class to add collectibles.
	- image is the image object for the collectible
	- func is the function that is run when the collectible is in the same cell as the player. This function
	must return a boolean that determines whether the collectible was collected or not.
]]
function Collectible:_init(image, func)
	self.image = image
	self.func = func
end

function Collectible:doFunc(player)
	if self.func == nil then
		print("Not implemented!")
		return false
	end
	return self.func(player)
end

function Collectible:destroy()
	stage:removeChild(self.image)
end

function GoldCoin()
	local collectGold = function(player)
		player.incrementScore(1) 
	end
	local self = Collectible(Bitmap.new(Texture.new("images/gold.png")), collectGold)
	local doFunc = function(player)
		return self:doFunc(player)
	end
	return {
		image = self.image,
		doFunc = doFunc
	}
end

function Gem()
	local collectGem = function(player)
		player.incrementScore(4)
		return true
	end
	local self = Collectible(Bitmap.new(Texture.new("images/gem.png")), collectGem)
	local doFunc = function(player)
		return self:doFunc(player)
	end
	return {
		image = self.image,
		doFunc = doFunc
	}
end

function BuriedTreasure()
	local collectGem = function(player)
		return false
	end
	local self = Collectible(nil, collectGem)
	local doFunc = function(player)
		return self:doFunc(player)
	end
	local isBuriedTreasure = true
	return {
		image = self.image,
		doFunc = doFunc,
		isBuriedTreasure = true
	}
end

function ShovelRepairPowerUp()
	local shovelRepair = function(player) 
		player.addDigs(2)
		return true
	end
	local self = Collectible(Bitmap.new(Texture.new("images/shovelrepair.png")), shovelRepair)
	local doFunc = function(player)
		return self:doFunc(player)
	end
	return {
		image = self.image,
		doFunc = doFunc
	}
end

-- Need to rewrite this functionality
function MetalDetectorPowerUp()
	local metalDetect = function(player) 
		player.setMetalDetection() 
		return true
	end
	local self = Collectible(Bitmap.new(Texture.new("images/metaldetector.png")), metalDetect)
	local doFunc = function(player)
		return self:doFunc(player)
	end
	return {
		image = self.image,
		doFunc = doFunc
	}
end

function SmallMoveBoostPowerUp()
	local boostMove = nil
	local self = Collectible(Bitmap.new(Texture.new("images/shoes.png")), boostMove)
	local doFunc = function(player)
		return self:doFunc(player)
	end
	return {
		image = self.image,
		doFunc = doFunc
	}
end

M.GoldCoin = GoldCoin
M.Gem = Gem
M.BuriedTreasure = BuriedTreasure
M.ShovelRepairPowerUp = ShovelRepairPowerUp
M.MetalDetectorPowerUp = MetalDetectorPowerUp
M.SmallMoveBoostPowerUp = SmallMoveBoostPowerUp
return M

