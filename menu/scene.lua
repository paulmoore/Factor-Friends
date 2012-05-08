--- scene.lua
--
-- This Scene controls the main menu.
-- It will also call upon menu.overlay.lua to display a list of your friends to play with.
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

local storyboard = require "storyboard"
local net        = require "net"
local sprite     = require "sprite"
local widget     = require "widget"
local json       = require "json"

local scene = storyboard.newScene()

local spriteSheet, spriteSet

local loginSprite
local githubBtn, logoutBtn

local alertId
local friend

local showAnim = false

local btnSound

local function gotoGameScene ()
	local options = {
		effect = "slideLeft",
		time   = 500,
		params = {
			friend  = friend,
			isFirst = false
		}
	}
	storyboard.gotoScene("game.scene", options)
end

--- Called when the user clicks 'yes'/'no' to respond to an incoming game request.
local function onAlertEvent (event)
	if "clicked" == event.action then
		if 2 == event.index then
			net.send(friend.id, {action = "accept"})
			gotoGameScene()
		else
			net.send(friend.id, {action = "reject"})
		end
		friend  = nil
		alertId = nil
	elseif "cancelled" == event.action then
		friend  = nil
		alertId = nil
	end
end

local function onNetEvent (event)
	if "login" == event.type then
		showAnim = true
        storyboard.showOverlay("menu.overlay", "fromBottom", 1000)
    elseif "logout" == event.type then
		storyboard.hideOverlay(true, "fromBottom", 1000)
	elseif "error" == event.type then
		native.showAlert("Uh-Oh!", event.details, {"Ok"})
		net.logout()
    elseif "receive" == event.type then
		local msg = event.message
		if "connect" == msg.action and not friend then
			friend = net.friendForId(msg.senderId)
			-- Don't take games from strangers!
			if friend then
				friend.gender = msg.gender
				alertId = native.showAlert("Challenge", friend.name.." challenges you to a game.  Do you accept?", {"No", "Yes"}, onAlertEvent)
			end
		elseif "cancel" == msg.action and friend and friend.id == msg.senderId then
			-- The friend may cancel their game request, in which case we will close the dialog automatically.
			native.cancelAlert(alertId)
		end
	end
end

local function onLoginSpriteTap (event)
	if loginSprite.isHitTestable then
		loginSprite.isHitTestable = false
		audio.play(btnSound)
		net.login()
	end
end

--- This will make the login animation invisible when it finishes 'closing'.
local function onLoginSpriteEvent (event)
	if "end" == event.phase then
		if "close" == loginSprite.sequence then
			loginSprite.isVisible = false
		end
	end
end

local function onLogoutBtnRelease (event)
	audio.play(btnSound)
	net.logout()
end

local function onGithubBtnRelease (event)
	audio.play(btnSound)
	system.openURL("https://github.com/paulmoore/Factor-Friends")
end

local function showLoginSprite ()
	loginSprite.isVisible     = true
	loginSprite.isHitTestable = true
	loginSprite:prepare("open")
	loginSprite:play()
end

local function hideLoginSprite ()
	loginSprite.isVisible     = true
	loginSprite.isHitTestable = false
	loginSprite:prepare("close")
	loginSprite:play()
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
	loginSprite.isVisible = false
	scene.view:insert(loginSprite)
	display.center(loginSprite)
	loginSprite:addEventListener("sprite", onLoginSpriteEvent)
	loginSprite:addEventListener("tap", onLoginSpriteTap)
	
	btnSound = audio.loadSound("res/audio/quit_btn.wav")
end

-- Called BEFORE scene has moved onscreen:
local function onWillEnterScene (event)
	if net.isLoggedIn() then
		showAnim = false
		storyboard.showOverlay("menu.overlay", "fromBottom", 1000)
	end
end

-- Called immediately after scene has moved onscreen:
local function onEnterScene (event)
	if not net.isLoggedIn() then
		showLoginSprite()
	end	
	net.listen(onNetEvent)
end

-- Called when scene is about to move offscreen:
local function onExitScene (event)
	net.unlisten(onNetEvent)
end

-- Called AFTER scene has finished moving offscreen:
local function onDidExitScene (event)
end

-- Called if/when overlay scene is displayed via storyboard.showOverlay()
local function onOverlayBegan (event)
	if showAnim then
		hideLoginSprite()
	end
	logoutBtn.isVisible = true
end

-- Called if/when overlay scene is hidden/removed via storyboard.hideOverlay()
local function onOverlayEnded (event)
	if not net.isLoggedIn() then
		showLoginSprite()
	end
	logoutBtn.isVisible = false
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
	audio.dispose(btnSound)
	btnSound    = nil
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
