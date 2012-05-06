
local storyboard = require "storyboard"
local facebook   = require "facebook"
local sprite     = require "sprite"
local widget     = require "widget"
local json       = require "json"

local scene = storyboard.newScene()

local fbAppId = "223466991100849"
local fbToken

local spriteSheet, spriteSet

local loginSprite
local githubBtn

-- {"id":"100003084745956","name":"Paul Moore","first_name":"Paul","last_name":"Moore","link":"http:\/\/www.facebook.com\/profile.php?id=100003084745956","gender":"male","timezone":-7,"locale":"en_GB","verified":true,"updated_time":"2011-10-26T01:14:34+0000"}
-- {"data":[{"name":"Cody Vigue","id":"517015515"}],"paging":{"next":"https:\/\/graph.facebook.com\/me\/friends?sdk=ios&sdk_version=2&access_token=BAADLPfafo7EBANSZAjbvdHt0NGpHQeX1n9ytLc4UazsZBwaOFIMkqcOhKVHhmpU0ZCzNQF595TEpIbcp1icvklQy2XKL79ZAgR5v02U8VDy4yDCDQRMwGvXl2mHLtPEZD&format=json&limit=5000&offset=5000&__after_id=517015515"}}

local function onFacebookEvent (event)
	if "session" == event.type then
        if "login" == event.phase then
			fbToken = event.token
            facebook.request("me", "GET")
			facebook.request("me/friends", "GET")
        end
    elseif "request" == event.type then
        local response = json.decode(event.response)
		if event.isError then
			native.showAlert("Uh-oh!", "Can't load Facebook data!", {"Opps"})
			facebook.logout()
		else
			if response.id then
				
			elseif response.data then
				storyboard.showOverlay("menu.overlay", {params = response.data})
			end
		end
	elseif "loginFailed" == event.phase then
		native.showAlert("Uh-oh!", "Can't login to Facebook!", {"Opps"})
	elseif "loginCancelled" == event.phase then
		native.showAlert("Uh-oh!", "Can't login to Facebook!", {"Opps"})
	elseif "logout" == event.phase then
		fbToken = nil
		storyboard.hideOverlay(true)
    end
end

local function onLoginSpriteTap (event)
	facebook.login(fbAppId, onFacebookEvent)
end

local function onLoginSpriteEvent (event)
	if "ended" == event.phase then
		if "close" == loginSprite.sequence then
			loginSprite.isVisible = false
		else
			loginSprite.isVisible = true
		end
	end
end

local function onGithubBtnRelease (event)
	system.openURL("https://github.com/paulmoore/Factor-Friends")
end

-- Called when the scene's view does not exist:
local function onCreateScene (event)
	local bg = display.newImage(scene.view, "res/img/menu_bg.png", 0, 0, true)
	display.center(bg)
	
	local logo = display.newImage(scene.view, "res/img/logo.png")
	logo:setReferencePoint(display.TopCenterReferencePoint)
	logo.x = display.contentCenterX
	logo.y = 10
	
	local githubBtn = widget.newButton({
		width     = 297,
		height    = 146,
		onRelease = onRelease,
		default   = "res/img/menu_btn_github_default.png",
		over      = "res/img/menu_btn_github_over.png"
	})
	scene.view:insert(githubBtn)
	githubBtn:setReferencePoint(display.BottomRightReferencePoint)
	githubBtn.x = display.contentWidth - 10
	githubBtn.y = display.contentHeight - 10
	
	local data  = require "res.anim.login_anim"
	spriteSheet = sprite.newSpriteSheetFromData("res/anim/login_anim.png", data.getSpriteSheetData())
	spriteSet   = sprite.newSpriteSet(spriteSheet, 1, 35)
	package.loaded["res.anim.login_anim"] = nil
	sprite.add(spriteSet, "open", 18, 18, 594, 1)
	sprite.add(spriteSet, "close", 1, 18, 594, 1)
	
	loginSprite = sprite.newSprite(spriteSet)
	scene.view:insert(loginSprite)
	display.center(loginSprite)
	loginSprite:addEventListener("sprite", onLoginSpriteEvent)
	loginSprite:addEventListener("tap", onLoginSpriteTap)
end

-- Called BEFORE scene has moved onscreen:
local function onWillEnterScene (event)
end

-- Called immediately after scene has moved onscreen:
local function onEnterScene (event)
	if fbToken then
		storyboard.showOverlay("menu.overlay")
	else
		loginSprite:prepare("open")
		loginSprite:play()
	end	
end

-- Called when scene is about to move offscreen:
local function onExitScene (event)
end

-- Called AFTER scene has finished moving offscreen:
local function onDidExitScene (event)
end

-- Called if/when overlay scene is displayed via storyboard.showOverlay()
local function onOverlayBegan (event)
	loginSprite:prepare("close")
	loginSprite:play()
end

-- Called if/when overlay scene is hidden/removed via storyboard.hideOverlay()
local function onOverlayEnded (event)
	loginSprite:prepare("open")
	loginSprite:play()
end

-- Called prior to the removal of scene's "view" (display group)
local function onDestroyScene (event)
	spriteSheet:removeSelf()
	spriteSheet = nil
	spriteSet   = nil
	loginSprite = nil
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
