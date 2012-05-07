
local storyboard = require "storyboard"
local net        = require "net"
local sprite     = require "sprite"
local widget     = require "widget"
local json       = require "json"

local scene = storyboard.newScene()

local spriteSheet, spriteSet

local loginSprite
local githubBtn, logoutBtn

local function onNetEvent (event)
	if "login" == event.type then
        storyboard.showOverlay("menu.overlay")
    elseif "logout" == event.type then
		storyboard.hideOverlay(true)
	elseif "error" == event.type then
		native.showAlert("Uh-Oh!", event.details, {"Ok"})
    end
end

local function onLoginSpriteTap (event)
	net.login()
end

local function onLoginSpriteEvent (event)
	if "end" == event.phase then
		if "close" == loginSprite.sequence then
			loginSprite.isVisible = false
		end
	end
end

local function onLogoutBtnRelease (event)
	net.logout()
	storyboard.hideOverlay(true)
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
	
	githubBtn = widget.newButton({
		width     = 297,
		height    = 146,
		onRelease = onGithubBtnRelease,
		default   = "res/img/menu_btn_github_default.png",
		over      = "res/img/menu_btn_github_over.png"
	})
	scene.view:insert(githubBtn)
	githubBtn:setReferencePoint(display.BottomRightReferencePoint)
	githubBtn.x = display.contentWidth - 5
	githubBtn.y = display.contentHeight - 5
	
	logoutBtn = widget.newButton({
		width     = 74,
		height    = 102,
		onRelease = onLogoutBtnRelease,
		default   = "res/img/btn_quit_default.png",
		over      = "res/img/btn_quit_over.png"
	})
	scene.view:insert(logoutBtn)
	logoutBtn:setReferencePoint(display.TopLeftReferencePoint)
	logoutBtn.x = logo.x - logo.width / 2
	logoutBtn.y = logo.y + logo.height - 20
	logoutBtn.isVisible = false
	
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
	
	net.listen(onNetEvent)
end

-- Called BEFORE scene has moved onscreen:
local function onWillEnterScene (event)
	if net.isLoggedIn() then
		storyboard.showOverlay("menu.overlay")
	end
end

-- Called immediately after scene has moved onscreen:
local function onEnterScene (event)
	if not net.isLoggedIn() then
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
	logoutBtn.isVisible = true
	githubBtn.isVisible = false
end

-- Called if/when overlay scene is hidden/removed via storyboard.hideOverlay()
local function onOverlayEnded (event)
	loginSprite.isVisible = true
	loginSprite:prepare("open")
	loginSprite:play()
	logoutBtn.isVisible = false
	githubBtn.isVisible = true
end

-- Called prior to the removal of scene's "view" (display group)
local function onDestroyScene (event)
	net.unlisten(onNetEvent)
	spriteSheet:removeSelf()
	spriteSheet = nil
	spriteSet   = nil
	loginSprite = nil
	githubBtn   = nil
	logoutBtn   = nil
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
