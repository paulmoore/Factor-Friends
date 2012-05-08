--- scene.lua
--
-- This is the main game scene, where all the math happens.
--
-- @author Paul Moore
--
-- Copyright (c) 2012 Strange Ideas Software
--
-- This file is part of Factor Friends.
--
-- Factor Friends is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- Factor Friends is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with Factor Friends.  If not, see <http://www.gnu.org/licenses/>.

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

local musicStream, musicChannel
local btnSound, piSound, primeSound, rightSound, wrongSound

local NUM_SELECTS   = 3
local NUM_FACTORS   = 6
local NUM_TURNS     = 5
local HIGHEST_PRIME = 113

--- Generates prime numbers between 2 and HIGHEST_PRIME.
local function generatePrimes ()
	local arr = {}
	-- Fill the array up with numbers.
	for i = 2, HIGHEST_PRIME, 1 do
		arr[#arr + 1] = i
	end
	-- Next, we go through each number, and remove all of its multiples.
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
	-- Any non-nil value must be a prime.
	primes = {}
	for i = 1, l do
		if arr[i] then
			primes[#primes + 1] = arr[i]
		end
	end
end

--- Generates the random factors for this round, based on the current turn number.
local function pickFactors ()
	local n = math.min(#primes, turnNum + 1)
	for i = 1, NUM_FACTORS do
		factors[i] = primes[math.random(1, n)]
	end
end

--- Set up the necessary data for the result screen and go to it.
local function gotoResultsScene ()
	local data = {}
	local victor
	if myScore > friendScore then
		data.isWinner = true
		victor = net.user()
	else
		data.isWinner = false
		victor = friend
	end
	if "female" == victor.gender then
		data.winner = "pi"
	else
		data.winner = "prime"
	end
	data.friend      = friend
	data.myScore     = myScore
	data.friendScore = friendScore
		
	storyboard.gotoScene("result.scene", {
		effect = "slideLeft",
		time   = 500,
		params = data
	})
end

--- Checks the scores.
-- If one of the players has won, this function returns true,
-- and will (after a time) transition to the results scene.
local function checkScores ()
	if turnNum >= NUM_TURNS then
		if myScore > friendScore then
			uiSplashView:show("You Win!")
		elseif friendScore > myScore then
			uiSplashView:show(friend.name.." Wins!")
		else
			return false
		end
		uiQuitBtn.onRelease = nil
		timer.performWithDelay(1500, gotoResultsScene, 1)
		return true
	end
	return false
end

local function isMyTurn ()
	return turnId == net.user().id
end

--- Starts the game phase for YOUR turn.
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

--- Ends the phase for YOUR turn.
local function endTurn ()
	turnId  = friend.id
	target = 1
	for i, p in ipairs(selected) do
		target = target * p
	end
	
	-- Tell your friend what they have to factor to get a point.
	net.send(friend.id, {
		action  = "challenge",
		target  = target,
		factors = factors
	})
	
	uiAnswerView:addFactor("?", 1)
	uiAnswerView:addFactor("?", 2)
	uiAnswerView:addFactor("?", 3)
	uiAnswerView:addAnswer(target)
	
	catGroup[1]:sendToFront()
	catGroup[2]:sendToBack()
	
	uiSplashView:show(friend.name.." must factor "..target.."!")
end

--- Starts the challenge phase for YOU (where you have to factor your friends integer).
local function startChallenge ()
	turnNum = turnNum + 1
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

--- Ends the challenge phase for YOU.
local function endChallenge ()
	local result = 1
	for i, p in ipairs(selected) do
		result = result * p
	end
	-- Did I factor the number correctly?
	if result == target then
		myScore = myScore + 1
		uiSplashView:show("Correct!")
		audio.play(rightSound)
	else
		uiSplashView:show("Incorrect!")
		audio.play(wrongSound)
	end
	
	-- Tell your friend what you ended up with.
	net.send(friend.id, {
		action = "guess",
		result = result
	})
	
	-- Are we done?  If not, it is now my turn.
	if not checkScores() then
		timer.performWithDelay(1000, startTurn, 1)
	end
end

--- Plays the cat sound for whatever cat is in front.
local function playCatSound ()
	if catGroup[2] == piSprite then
		audio.play(piSound)
	else
		audio.play(primeSound)
	end
end

local function onQuitBtnRelease ()
	net.send(friend.id, {action = "quit"})
	audio.play(btnSound)
	storyboard.gotoScene("menu.scene", "slideLeft", 500)
end

local function onNetEvent (event)
	if "receive" == event.type then
		local msg = event.message
		if "dance" == msg.action then
			-- Your friend made a move.  Dance-animate and update the UI.
			catGroup[2]:dance(math.random(1, NUM_FACTORS))
			playCatSound()
			
			uiAnswerView:addFactor(msg.factor, msg.num)
			uiFactorView:flash(msg.factor)
		elseif "challenge" == msg.action then
			-- Your friend has given you an integer to factor.
			target  = msg.target
			factors = msg.factors
			startChallenge()
		elseif "guess" == msg.action then
			-- Your friend has attempted to factor the integer you compounded.  Did he get it right?
			if msg.result == target then
				friendScore = friendScore + 1
				uiSplashView:show(friend.name.." is Correct!")
				audio.play(rightSound)
			else
				uiSplashView:show(friend.name.." is Incorrect!")
				audio.play(wrongSound)
			end
			uiAnswerView:addAnswer(msg.result)
			-- Do we continue?  Is it game over?
			if not checkScores() then
				uiSplashView:show(friend.name.."'s Turn!")
				timer.performWithDelay(1500, function () uiAnswerView:clear() end, 1)
			end
		elseif "quit" == msg.action then
			-- Your friend left.  Probably a rage-quit.
			native.showAlert("Quit", friend.name.." has left the game.", {"Ok"})
			storyboard.gotoScene("menu.scene", "slideLeft", 500)
		end
	end
end

local function onFactorSelect (event)
	local factor = factors[event.id]
	selected[#selected + 1] = factor
	uiAnswerView:addFactor(factor, #selected)
	playCatSound()
	-- You get 3 selections, then your turn is over.
	if #selected == NUM_SELECTS then
		-- Decide where to go from here, end your turn, or end the factoring phase.
		if isMyTurn() then
			catGroup[2]:dance(event.id)
			timer.performWithDelay(500, endTurn, 1)
		else
			catGroup[2]:dance(event.id)
			timer.performWithDelay(500, endChallenge, 1)
		end
		uiFactorView:hide()
	else
		catGroup[2]:dance(event.id)
	end
	-- Obfuscate the prime you choose from your opponent.
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
	
	musicStream = audio.loadStream("res/audio/game_music.wav")
	btnSound    = audio.loadSound("res/audio/quit_btn.wav")
	piSound     = audio.loadSound("res/audio/pi_sfx.wav")
	primeSound  = audio.loadSound("res/audio/prime_sfx.wav")
	rightSound  = audio.loadSound("res/audio/right_sound.wav")
	wrongSound  = audio.loadSound("res/audio/wrong_sound.wav")
	
	generatePrimes()
end

-- Called BEFORE scene has moved onscreen:
local function onWillEnterScene (event)
	local params = event.params
	friend = params.friend
	
	-- The cat positions and names get shuffled around depending if you
	-- go first/last and if you are female/male.
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
	
	musicChannel = audio.play(musicStream, {loops = -1, fadein = 3000})
end

-- Called immediately after scene has moved onscreen:
local function onEnterScene (event)
	turnNum      = 0
	myScore      = 0
	friendScore  = 0
	factors      = {}
	
	local params = event.params
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
	audio.fadeOut({channel = musicChannel, time = 3000})
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
	piSprite     = nil
	primeSprite  = nil
	catGroup     = nil
	cat_view.unload()
	audio.dispose(musicStream)
	musicStream  = nil
	audio.dispose(btnSound)
	btnSound     = nil
	audio.dispose(piSound)
	piSound      = nil
	audio.dispose(primeSound)
	primeSound   = nil
	audio.dispose(rightSound)
	rightSound   = nil
	audio.dispose(wrongSound)
	wrongSound   = nil
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
