local storyboard  = require "storyboard"
local widget      = require "widget"
local net         = require "net"
local primes      = require "game.primes"
local cat_view    = require "game.cat_view"
local factor_view = require "game.factor_view"
local answer_view = require "game.answer_view"

local scene = storyboard.newScene()

local uiQuitBtn
local uiFactorView
local uiAnswerView

local catGroup

local factors, selected
local target
local myId
local turnId, turnNum
local lowBound, highBound
local myScore, oppScore

local NUM_SELECTS        = 3
local NUM_FACTORS        = 6
local INITIAL_LOW_BOUND  = 2
local INITIAL_HIGH_BOUND = 3
local NUM_TURNS          = 5

local function splashText (msg)
	local text = display.newText(scene.view, msg, 0, 0, "Bauhaus93", 90)
	text:setTextColor(0xf5, 0x91, 0x33)
	text:setReferencePoint(display.CenterReferencePoint)
	display.center(text)
	text.rotation = -30
	transition.from(text, {
		time   = 250,
		alpha  = 0.0,
		xScale = 0.01,
		yScale = 0.01,
		onComplete = function ()
			timer.performWithDelay(1000, function ()
				transition.to(text, {
					time       = 500,
					alpha      = 0.0,
					xScale     = 0.01,
					yScale     = 0.01,
					transition = easing.inExpo,
					onComplete = function ()
						text:removeSelf()
					end
				})
			end, 1)
		end
	})
end

local function checkScores ()
	if turnNum >= NUM_TURNS then
		if myScore > oppScore then
			splashText("You Win!")
		elseif oppScore > myScore then
			splashText("Opp Wins!")
		else
			return false
		end
		return true
	end
	return false
end

local function startTurn ()
	local done = checkScores()
	if done then
		return
	end
	factors  = primes.generate(lowBound, highBound, NUM_FACTORS)
	selected = {}
	uiFactorView:setLabels(factors)
	uiFactorView:show()
	uiAnswerView:clear()
	splashText("Your Turn!")
end

local function endTurn ()
	turnNum = turnNum + 1
	if turnId == 1 then
		turnId = 2
	else
		turnId = 1
	end
	target = 1
	for i, p in ipairs(selected) do
		target = target * p
	end
	net.send({
		action  = "challenge",
		integer = target
	})
	uiAnswerView:addFactor("?", 1)
	uiAnswerView:addFactor("?", 2)
	uiAnswerView:addFactor("?", 3)
	uiAnswerView:addAnswer(target)
	uiFactorView:hide()
	catGroup[1]:sendToFront()
	catGroup[2]:sendToBack()
	splashText("Opp Challenge!")
end

local function startChallenge ()
	factors  = primes.generate(lowBound, highBound, NUM_FACTORS)
	selected = {}
	catGroup[1]:sendToFront()
	catGroup[2]:sendToBack()
	uiAnswerView:clear()
	uiAnswerView:addFactor("?", 1)
	uiAnswerView:addFactor("?", 2)
	uiAnswerView:addFactor("?", 3)
	uiAnswerView:addAnswer(target)
	uiFactorView:setLabels(factors)
	uiFactorView:show()
	splashText("Factor "..target.."!")
end

local function endChallenge ()
	turnNum = turnNum + 1
	if turnId == 1 then
		turnId = 2
	else
		turnId = 1
	end
	local result = 1
	for i, p in ipairs(selected) do
		result = result * p
	end
	if result == target then
		splashText("Correct!")
		myScore = myScore + 1
	else
		splashText("Opps!")
	end
	net.send({
		action = "guess",
		guess  = result
	})
	target = nil
	lowBound  = lowBound + 2
	highBound = highBound + 5
	uiFactorView:hide()
	timer.performWithDelay(1500, startTurn, 1)
end

local function onNetEvent (event)
	if "receive" == event.type then
		local message = event.message
		if "dance" == message.action then
			catGroup[2]:dance(math.random(1, NUM_FACTORS))
			uiAnswerView:addFactor(message.factor, message.num)
		elseif "challenge" == message.action then
			target = message.integer
			startChallenge()
		elseif "guess" == message.action then
			if message.guess == target then
				splashText("Opp is Correct!")
				oppScore = oppScore + 1
			else
				splashText("Opp is Wrong!")
			end
			uiAnswerView:addAnswer(message.guess)
			local done = checkScores()
			if not done then
				timer.performWithDelay(1500, function ()
					uiAnswerView:clear()
					splashText("Opp's Turn!")
				end, 1)
				lowBound  = lowBound + 2
				highBound = highBound + 5
			end
		end
	end
end

local function onFactorSelect (event)
	local factor = factors[event.id]
	selected[#selected + 1] = factor
	if #selected == NUM_SELECTS then
		if turnId == myId then
			catGroup[2]:dance(event.id, endTurn)
		else
			catGroup[2]:dance(event.id, endChallenge)
		end
	else
		catGroup[2]:dance(event.id)
	end
	if myId ~= turnId then
		net.send({
			action = "dance",
			factor = factor,
			num    = #selected
		})
	else
		net.send({
			action = "dance",
			factor = "?",
			num    = #selected
		})
	end
	uiAnswerView:addFactor(factor, #selected)
end

-- Called when the scene's view does not exist:
local function onCreateScene (event)
	local bg = display.newImage(scene.view, "res/img/game_bg.png", 0, 0, true)
	display.center(bg)
	
	catGroup = display.newGroup()
	scene.view:insert(catGroup)
	
	cat_view.load()

	catGroup:insert(cat_view.new("prime"))	
	catGroup:insert(cat_view.new("pi"))
	
	uiFactorView = factor_view.new()
	scene.view:insert(uiFactorView)
	uiFactorView:addEventListener("select", onFactorSelect)
	display.center(uiFactorView)
	
	uiAnswerView = answer_view.new()
	scene.view:insert(uiAnswerView)
	uiAnswerView.x = display.contentCenterX
	uiAnswerView.y = display.contentHeight - uiAnswerView.height / 2 - 5
end

-- Called BEFORE scene has moved onscreen:
local function onWillEnterScene (event)
	catGroup[1]:idle()
	catGroup[1]:sendToFront(true)
	catGroup[2]:idle()
	catGroup[2]:sendToBack(true)
	
	turnId    = 1
	turnNum   = 0
	myScore   = 0
	oppScore  = 0
	lowBound  = INITIAL_LOW_BOUND
	highBound = INITIAL_HIGH_BOUND
end

-- Called immediately after scene has moved onscreen:
local function onEnterScene (event)
	myId = event.params.myId
	if myId == 1 then
		startTurn()
	else
		splashText("Opp's Turn!")
	end
	net.listen(onNetEvent)
end

-- Called when scene is about to move offscreen:
local function onExitScene (event)
	net.unlisten(onNetEvent)
end

-- Called AFTER scene has finished moving offscreen:
local function onDidExitScene (event)
	catGroup[1]:pause()
	catGroup[2]:pause()
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
