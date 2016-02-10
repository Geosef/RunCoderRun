CommandFactory = Core.class()

function CommandFactory:init()
	self:initMasterLib()
	self:initSublibs()
end

function CommandFactory:initMasterLib()
	self.masterLibrary = {}
	self.masterGUILibrary["Move"] = function(scriptArea)
		return {DoubleScriptObject.new(scriptArea, "Move", {"N", "E", "S", "W"}, scriptArea.parent.resourceBox:getResources())}
	end
	self.masterLibrary["Loop"] = function(scriptArea)
		return {SingleScriptObject.new(scriptArea, "Loop", scriptArea.parent.resourceBox:getResources()), ZeroScriptObject.new(scriptArea, "Loop End")}
	end
	self.masterLibrary["Dig"] = function(scriptArea)
		return {ZeroScriptObject.new(scriptArea, "Dig")}
	end
	self.masterLibrary["Jump"] = function(scriptArea)
		return {ZeroScriptObject.new(scriptArea, "Jump")}
	end
end

function CommandFactory:initSublibs()
	self.sublibs = {}
	self.sublibs["Space Collectors"] = self:initSpaceCollectorsGameCommands()
end

function CommandFactory:initSpaceCollectorsGameCommands()
	local sublib = {}
	sublib["Move"] = self.masterLibrary["Move"]
	sublib["Loop"] = self.masterLibrary["Loop"]
	sublib["Dig"] = self.masterLibrary["Dig"]
	sublib["Jump"] = self.masterLibrary["Jump"]
	return sublib
end

function CommandFactory:getSubLibrary(game)
	return self.sublibs[game]
end

