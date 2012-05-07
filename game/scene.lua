local storyboard  = require "storyboard"
local widget      = require "widget"
local net         = require "net"
local cat_view    = require "game.cat_view"
local factor_view = require "game.factor_view"
local answer_view = require "game.answer_view"
local splash_view = require "game.splash_view"

local scene = storyboard.newScene()

local uiQuitBtn
local uiFactorView
local uiAnswerView
local uiSplashView

local catGroup
local piSprite, primeSprite

local friend

local primes

local factors, selected
local target

local turnId, turnNum
local myScore, friendScore

local NUM_SELECTS   = 3
local NUM_FACTORS   = 6
local NUM_TURNS     = 5
local HIGHEST_PRIME = 113

local function generatePrimes ()
	local arr = {}
	for i = 2, HIGHEST_PRIME, 1 do
		arr[#arr + 1] = i
	end
	local l = #arr
	for i = 1, l do
		local prime = arr[i]
		if prime then
			for j = i + 1, l do
				local multiple = arr[j]
				if multiple and multiple % prime == 0 then
					arr[j] = nil
				end
			end
		end
	end
	primes = {}
	for i = 1, l do
		if arr[i] then
			primes[#primes + 1] = arr[i]
		end
	end
end

local function pickFactors ()
	for i = 1, NUM_FACTORS do
		factors[i] = primes[math.random(1, turnNum + 1)]
	end
end

local function checkScores ()
	if turnNum >= NUM_TURNS then
		if myScore > friendScore then
			uiSplashView:show("You Win!")
			return true
		elseif friendScore > myScore then
			uiSplashView:show(friend.name.." Wins!")
			return true
		end
	end
	return false
end

local function isMyTurn ()
	return turnId == net.user().id
end

local function startTurn ()
	turnNum = turnNum + 1
	turnId  = net.user().id
	pickFactors()
	selected = {}
	uiFactorView:setLabels(factors)
	uiFactorView:show()
	uiAnswerView:clear()
	uiSplashView:show("Your Turn!")
end

local function endTurn ()
	turnNum = turnNum + 1
	turnId  = friend.id
	target = 1
	for i, p in ipairs(selected) do
		target = target * p
	end
	net.send(friend.id, {
		action  = "challenge",
		target  = target,
		factors = factors
	})
	uiAnswerView:addFactor("?", 1)
	uiAnswerView:addFactor("?", 2)
	uiAnswerView:addFactor("?", 3)
	uiAnswerView:addAnswer(target)
	uiFactorView:hide()
	catGroup[1]:sendToFront()
	catGroup[2]:sendToBack()
	uiSplashView:show(friend.name.." must factor "..target.."!")
end

local function startChallenge ()
	selected = {}
	catGroup[1]:sendToFront()
	catGroup[2]:sendToBack()
	uiAnswerView:addFactor("?", 1)
	uiAnswerView:addFactor("?", 2)
	uiAnswerView:addFactor("?", 3)
	uiAnswerView:addAnswer(target)
	uiFactorView:setLabels(factors)
	uiFactorView:show()
	uiSplashView:show("Factor "..target.."!")
end

local function endChallenge ()
	local result = 1
	for i, p in ipairs(selected) do
		result = result * p
	end
	if result == target then
		myScore = myScore + 1
		uiSplashView:show("Correct!")
	else
		uiSplashView:show("Incorrect!")
	end
	net.send(friend.id, {
		action = "guess",
		result = result
	})
	target = nil
	uiFactorView:hide()
	if not checkScores() then
		startTurn()
	end
end

local function onQuitBtnRelease ()
	net.send(friend.id, {action = "quit"})
	storyboard.gotoScene("menu.scene", "slideLeft", 500)
end

local function onNetEvent (event)
	if "receive" == event.type then
		local msg = event.message
		if "dance" == msg.action then
			catGroup[2]:dance(math.random(1, NUM_FACTORS))
			uiAnswerView:addFactor(msg.factor, msg.num)
		elseif "challenge" == msg.action then
			target  = msg.target
			factors = msg.factors
			startChallenge()
		elseif "guess" == msg.action then
			if msg.result == target then
				friendScore = friendScore + 1
				uiSplashView:show(friend.name.." is Correct!")
			else
				uiSplashView:show(friend.name.." is Incorrect!")
			end
			uiAnswerView:addAnswer(msg.result)
			if not checkScores() then
				uiSplashView:show(friend.name.."'s Turn!")
				timer.performWithDelay(1000, function () uiAnswerView:clear() end, 1)
			end
		elseif "quit" == msg.action then
			native.showAlert("Quit", friend.name.." has left the game.", {"Ok"})
			storyboard.gotoScene("menu.scene", "slideLeft", 500)
		end
	end
end

local function onFactorSelect (event)
	local factor = factors[event.id]
	selected[#selected + 1] = factor
	uiAnswerView:addFactor(factor, #selected)
	if #selected == NUM_SELECTS then
		if isMyTurn() then
			catGroup[2]:dance(event.id)
			timer.performWithDelay(500, endTurn, 1)
		else
			catGroup[2]:dance(event.id)
			timer.performWithDelay(500, endChallenge, 1)
		end
	else
		catGroup[2]:dance(event.id)
	end
	if isMyTurn() then
		factor = "?"
	end
	net.send(friend.id, {
		action = "dance",
		factor = factor,
		num    = #selected
	})
end

-- Called when the scene's view does not exist:
local function onCreateScene (event)
	local bg = display.newImage(scene.view, "res/img/game_bg.png", 0, 0, true)
	display.center(bg)
	
	local logo = display.newImage(scene.view, "res/img/logo.png")
	logo:setReferencePoint(display.TopCenterReferencePoint)
	logo.x = display.contentCenterX
	logo.y = 10
	
	cat_view.load()
	catGroup = display.newGroup()
	scene.view:insert(catGroup)
	piSprite    = cat_view.new("pi")
	primeSprite = cat_view.new("prime")
	catGroup:insert(piSprite)	
	catGroup:insert(primeSprite)
	display.center(catGroup)
	
	uiFactorView = factor_view.new()
	scene.view:insert(uiFactorView)
	uiFactorView:addEventListener("select", onFactorSelect)
	uiFactorView.x = display.contentCenterX
	uiFactorView.y = display.contentCenterY + 20
	
	uiAnswerView = answer_view.new()
	scene.view:insert(uiAnswerView)
	uiAnswerView.x = display.contentCenterX
	uiAnswerView.y = display.contentHeight - uiAnswerView.height / 2
	
	uiSplashView = splash_view.new()
	display.center(uiSplashView)
	
	uiQuitBtn = widget.newButton({
		width     = 74,
		height    = 102,
		onRelease = onQuitBtnRelease,
		default   = "res/img/btn_quit_default.png",
		over      = "res/img/btn_quit_over.png"
	})
	scene.view:insert(uiQuitBtn)
	uiQuitBtn:setReferencePoint(display.TopLeftReferencePoint)
	uiQuitBtn.x = logo.x - logo.width / 2
	uiQuitBtn.y = logo.y + logo.height - 20
	
	generatePrimes()
end

-- Called BEFORE scene has moved onscreen:
local function onWillEnterScene (event)
	local params = event.params
	friend = params.friend
	if params.isFirst then
		if "female" == net.user().gender then
			primeSprite:sendToBack(0)
			primeSprite:setName(friend.name)
			piSprite:sendToFront(0)
			piSprite:setName(net.user().name)
		else
			primeSprite:sendToFront(0)
			primeSprite:setName(net.user().name)
			piSprite:sendToBack(0)
			piSprite:setName(friend.name)
		end
	else
		if "female" == friend.gender then
			primeSprite:sendToBack(0)
			primeSprite:setName(net.user().name)
			piSprite:sendToFront(0)
			piSprite:setName(friend.name)
		else
			primeSprite:sendToFront(0)
			primeSprite:setName(friend.name)
			piSprite:sendToBack(0)
			piSprite:setName(net.user().name)
		end
	end
	primeSprite:idle()
	piSprite:idle()
end

-- Called immediately after scene has moved onscreen:
local function onEnterScene (event)
	local params = event.params
	turnNum      = 0
	myScore      = 0
	friendScore  = 0
	factors      = {}
	if params.isFirst then
		startTurn()
	else
		uiSplashView:show(friend.name.."'s Turn!")
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
	uiFactorView:destroy()
	uiFactorView = nil
	uiSplashView:destroy()
	uiSplashView = nil
	uiAnswerView:destroy()
	uiAnswerView = nil
	uiQuitBtn    = nil
	piSprite:destroy()
	primeSprite:destroy()
	piSprite    = nil
	primeSprite = nil
	catGroup    = nil
	cat_view.unload()
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
