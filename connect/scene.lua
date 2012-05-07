
local storyboard = require "storyboard"
local widget     = require "widget"
local net        = require "net"

local scene = storyboard.newScene()

local spriteSheet, spriteSet

local friend

local myAnim, friendAnim

local cancelBtn

local timerId

local function gotoGameScene ()
	local options = {
		effect = "slideLeft",
		time   = 300,
		params = {
			friend  = friend,
			isFirst = true
		}
	}
	timer.performWithDelay(500, function () storyboard.gotoScene("game.scene", options) end, 1)
end

local function onNetEvent (event)
	if "receive" == event.type then
		local msg = event.message
		if friend.id == msg.senderId then
			if "accept" == msg.action then
				if "female" == net.user().gender then
					friendAnim:prepare("prime")
				else
					friendAnim:prepare("pi")
				end
				friendAnim:play()
				gotoGameScene()
			elseif "reject" == msg.action then
				native.showAlert(":(", friend.name.." Doesn't want to play right now.", {"Ok"})
				storyboard.gotoScene("menu.scene", "slideRight", 300)
			end
		end
	end
end

local function sendRequest ()
	net.send(friend.id, {
		action = "connect",
		gender = net.user().gender
	})
end

local function onCancelBtnRelease ()
	net.send(friend.id, {action = "cancel"})
	storyboard.gotoScene("menu.scene", "slideRight", 300)
end

-- Called when the scene's view does not exist:
local function onCreateScene (event)
	friend = net.friends()[event.params]
	
	local bg = display.newImage(scene.view, "res/img/menu_bg.png", 0, 0, true)
	display.center(bg)
	
	local logo = display.newImage(scene.view, "res/img/logo.png")
	logo:setReferencePoint(display.TopCenterReferencePoint)
	logo.x = display.contentCenterX
	logo.y = 10
	
	cancelBtn = widget.newButton({
		width     = 74,
		height    = 102,
		onRelease = onCancelBtnRelease,
		default   = "res/img/btn_quit_default.png",
		over      = "res/img/btn_quit_over.png"
	})
	scene.view:insert(cancelBtn)
	cancelBtn:setReferencePoint(display.TopLeftReferencePoint)
	cancelBtn.x = logo.x - logo.width / 2
	cancelBtn.y = logo.y + logo.height - 20
	
	local data  = require "res.anim.connect_anim"
	spriteSheet = sprite.newSpriteSheetFromData("res/anim/connect_anim.png", data.getSpriteSheetData())
	package.loaded["res.anim.connect_anim"] = nil
	spriteSet = sprite.newSpriteSet(spriteSheet, 1, 27)
	sprite.add(spriteSet, "pi", 1, 9, 297, 1)
	sprite.add(spriteSet, "prime", 10, 9, 297, 1)
	sprite.add(spriteSet, "wait", 19, 9, 594, 0)
	
	friendAnim = sprite.newSprite(spriteSet)
	scene.view:insert(friendAnim)
	friendAnim:setReferencePoint(display.CenterRightReferencePoint)
	friendAnim.x = display.contentWidth - 100
	friendAnim.y = display.contentCenterY
	
	local friendName = display.newText(scene.view, friend.name, 0, 0, "Bauhaus93", 34)
	friendName:setTextColor(0x00, 0x00, 0x00)
	friendName:setReferencePoint(display.TopCenterReferencePoint)
	friendName.x = friendAnim.x - friendAnim.width / 2
	friendName.y = friendAnim.y + friendAnim.height / 2 + 10
	
	myAnim = sprite.newSprite(spriteSet)
	scene.view:insert(myAnim)
	myAnim:setReferencePoint(display.CenterLeftReferencePoint)
	myAnim.x = 100
	myAnim.y = display.contentCenterY
	
	local myName = display.newText(scene.view, net.user().name, 0, 0, "Bauhaus93", 34)
	myName:setTextColor(0x00, 0x00, 0x00)
	myName:setReferencePoint(display.TopCenterReferencePoint)
	myName.x = myAnim.x + myAnim.width / 2
	myName.y = myAnim.y + myAnim.height / 2 + 10
	
	local arrow = display.newImage(scene.view, "res/img/connect_arrow.png")
	display.center(arrow)
end

-- Called BEFORE scene has moved onscreen:
local function onWillEnterScene (event)
	friendAnim:prepare("wait")
	friendAnim:play()
end

-- Called immediately after scene has moved onscreen:
local function onEnterScene (event)
	net.listen(onNetEvent)
	sendRequest()
	timerId = timer.performWithDelay(5000, sendRequest, 0)
	if "female" == net.user().gender then
		myAnim:prepare("pi")
	else
		myAnim:prepare("prime")
	end
	myAnim:play()
end

-- Called when scene is about to move offscreen:
local function onExitScene (event)
	timer.cancel(timerId)
	net.unlisten(onNetEvent)
end

-- Called AFTER scene has finished moving offscreen:
local function onDidExitScene (event)
	myAnim:pause()
	friendAnim:pause()
end
-- Called if/when overlay scene is displayed via storyboard.showOverlay()
local function onOverlayBegan (event)
end

-- Called if/when overlay scene is hidden/removed via storyboard.hideOverlay()
local function onOverlayEnded (event)
end

-- Called prior to the removal of scene's "view" (display group)
local function onDestroyScene (event)
	spriteSheet:removeSelf()
	spriteSheet = nil
	spriteSet   = nil
	myAnim      = nil
	friendAnim  = nil
	cancelBtn   = nil
	friend      = nil
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
