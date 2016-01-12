-- program is being exported under the TSU exception

WINDOW_HEIGHT = application:getLogicalWidth()
WINDOW_WIDTH = application:getLogicalHeight()

local multiplayerMode = true

JSON = (loadfile "JSON.lua")()

NET_ADAPTER = NetworkAdapter(true)
--netAdapter:login()

KEYBOARD = Keyboard.new()
sceneManager = SceneManager.new({ 
	["splash"] = splash,
	["login"] = login,
	["mainMenu"] = mainMenu,
	["create"] = createAccount,
	["textBox"] = textBoxScene,
	["gameWait"] = gameWait,
	["gameScreen"] = gameScreen,
})

BlankScene = Core.class(Sprite)

popupManager = SceneManager.new({
	["settings"] = settings,
	["blank"] = BlankScene
})

stage:addChild(sceneManager)
stage:addChild(popupManager)

sceneManager:changeScene("splash", 1, SceneManager.crossfade, easing.outBack)
popupManager:changeScene("blank", 1, SceneManager.crossfade, easing.outBack)

