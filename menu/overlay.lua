
local storyboard = require "storyboard"
local widget     = require "widget"

local scene = storyboard.newScene()

local table

local friends

local function onRowEvent (event)
	
end

local function onRowRender (event)
	local friend = friends[event.index]
	local profileImage
	local function showImage (imageEvent)
		profileImage = imageEvent.target
		event.view:insert(profileImage)
		profileImage.width  = 100
		profileImage.height = 100
		profileImage:setReferencePoint(display.CenterLeftReferencePoint)
		profileImage.x = 10
		profileImage.y = 0
	end
	display.loadRemoteImage(
		"http://graph.facebook.com/".. friend.id .."/picture",
		"GET",
		showImage,
		"friend"..event.index..".png", 
		system.TemporaryDirectory
	)
	local nameLabel = display.newText(event.view, friend.name, 0, 0, "Bauhaus93", 40)
	nameLabel:setTextColor(0x00, 0x00, 0x00)
	nameLabel.x = 130
	nameLabey.y = 0
end

-- Called when the scene's view does not exist:
local function onCreateScene (event)
	table = widget.newTableView({
		width           = display.contentWidth,
		height          = display.contentHeight,
		left            = 0,
		top             = 200,
		bgColor         = {0x00, 0x00, 0x00, 0x00},
		renderThresh    = 200
	})
	friends = event.params
	for i, friend in ipairs(friends) do
		table:insertRow({
			onEvent   = onRowEvent,
			onRender  = onRowRender,
			rowColor  = {0x00, 0x00, 0x00, 0x00},
			lineColor = {0x00, 0x00, 0x00},
			height    = 120
		})
	end
end

-- Called BEFORE scene has moved onscreen:
local function onWillEnterScene (event)
end

-- Called immediately after scene has moved onscreen:
local function onEnterScene (event)
end

-- Called when scene is about to move offscreen:
local function onExitScene (event)
end

-- Called AFTER scene has finished moving offscreen:
local function onDidExitScene (event)
end
-- Called if/when overlay scene is displayed via storyboard.showOverlay()
local function onOverlayBegan (event)
end

-- Called if/when overlay scene is hidden/removed via storyboard.hideOverlay()
local function onOverlayEnded (event)
end

-- Called prior to the removal of scene's "view" (display group)
local function onDestroyScene (event)
	table:removeSelf()
	table = nil
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
