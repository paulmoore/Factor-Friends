local storyboard  = require "storyboard"
local widget      = require "widget"
local net         = require "net"
local primes      = require "game.primes"
local cat_view    = require "game.cat_view"
local factor_view = require "game.factor_view"

local scene = storyboard.newScene()

local uiQuitBtn
local uiFactorView

local catGroup

local factors, selected
local myId
local turnId, turnNum
local lowBound, highBound

local NUM_SELECTS        = 3
local NUM_FACTORS        = 6
local INITIAL_LOW_BOUND  = 3
local INITIAL_HIGH_BOUND = 5

local function startTurn ()
	factors  = primes.generate(lowBound, highBound, NUM_FACTORS)
	selected = {}
	uiFactorView:setLabels(factors)
	uiFactorView:show()
end

local function endTurn ()
	uiFactorView:hide()
	catGroup[1]:sendToFront()
	catGroup[2]:sendToBack()
	turnNum = turnNum + 1
	if turnId == 1 then
		turnId = 2
	else
		turnId = 1
	end
	local target = 1
	for i, p in ipairs(selected) do
		target = target * p
	end
	net.send({
		action  = "challenge",
		integer = target
	})
end

local function startChallenge (...)
	-- body
end

local function onNetEvent (event)
	if "receive" == event.type then
		local message = event.message
		if "dance" == message.action then
			catGroup[2]:dance(math.random(1, NUM_FACTORS))
		elseif "challenge" == message.action then
			
		end
	end
end

local function onFactorSelect (event)
	local factor = factors[event.id]
	selected[#selected + 1] = factor
	if #selected == NUM_SELECTS then		
		catGroup[2]:dance(event.id, endTurn)
	else
		catGroup[2]:dance(event.id)
	end
	net.send({
		action = "dance"
	})
end

-- Called when the scene's view does not exist:
local function onCreateScene (event)
	local bg = display.newImage(scene.view, "res/img/game_bg.png")
	display.center(bg)
	
	catGroup = display.newGroup()
	scene.view:insert(catGroup)
	
	cat_view.load()

	catGroup:insert(cat_view.new("prime"))	
	catGroup:insert(cat_view.new("pi"))
	
	uiFactorView = factor_view.new()
	uiFactorView:setReferencePoint(display.CenterReferencePoint)
	uiFactorView:addEventListener("select", onFactorSelect)
	display.center(uiFactorView)
end

-- Called BEFORE scene has moved onscreen:
local function onWillEnterScene (event)
	catGroup[1]:idle()
	catGroup[1]:sendToFront(true)
	catGroup[2]:idle()
	catGroup[2]:sendToBack(true)
	
	turnId    = 1
	turnNum   = 0
	lowBound  = INITIAL_LOW_BOUND
	highBound = INITIAL_HIGH_BOUND
end

-- Called immediately after scene has moved onscreen:
local function onEnterScene (event)
	myId = event.params.myId
	if myId == 1 then
		startTurn()
	end
	net.listen(onNetEvent)
end

-- Called when scene is about to move offscreen:
local function onExitScene (event)
	net.unlisten(onNetEvent)
end

-- Called AFTER scene has finished moving offscreen:
local function onDidExitScene (event)
	catGroup[1]:stop()
	catGroup[2]:stop()
end
-- Called if/when overlay scene is displayed via storyboard.showOverlay()
local function onOverlayBegan (event)
end

-- Called if/when overlay scene is hidden/removed via storyboard.hideOverlay()
local function onOverlayEnded (event)
end

-- Called prior to the removal of scene's "view" (display group)
local function onDestroyScene (event)
	cat_view.unload()
	uiFactorView:destroy()
	uiFactorView = nil
	catGroup     = nil
end

-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener("createScene", onCreateScene)

-- "willEnterScene" event is dispatched before scene transition begins
scene:addEventListener("willEnterScene", onWillEnterScene)

-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener("enterScene", onEnterScene)

-- "exitScene" event is dispatched before next scene's transition begins
scene:addEventListener("exitScene", onExitScene)

-- "didExitScene" event is dispatched after scene has finished transitioning out
scene:addEventListener("didExitScene", onDidExitScene)

-- "overlayBegan" event is dispatched when an overlay scene is shown
scene:addEventListener("overlayBegan", onOverlayBegan)
 
-- "overlayEnded" event is dispatched when an overlay scene is hidden/removed
scene:addEventListener("overlayEnded", onOverlayEnded)

-- "destroyScene" event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener("destroyScene", onDestroyScene)

return scene
