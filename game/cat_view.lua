local sprite = require "sprite"

local NUM_DANCES = 3

local spriteSheets, spriteSets

local view = {}

function view.load ()
	local tpDataPrime = require "res.anim.prime_anim"
	local tpDataPi    = require "res.anim.pi_anim"
	spriteSheets = {
		prime = sprite.newSpriteSheetFromData("res/anim/prime_anim.png", tpDataPrime.getSpriteSheetData()),
		pi    = sprite.newSpriteSheetFromData("res/anim/pi_anim.png", tpDataPi.getSpriteSheetData())
	}
	spriteSets = {
		prime = sprite.newSpriteSet(spriteSheets.prime, 1, 21),
		pi    = sprite.newSpriteSet(spriteSheets.pi, 1, 21)
	}
	package.loaded["res.anim.prime_anim"] = nil
	package.loaded["res.anim.pi_anim"]    = nil
	sprite.add(spriteSets.pi, "idle", 1, 8, 250, -2)
	sprite.add(spriteSets.pi, "dance1", 9, 4, 250, -1)
	sprite.add(spriteSets.pi, "dance2", 13, 4, 250, -1)
	sprite.add(spriteSets.pi, "dance3", 17, 5, 250, -1)
	sprite.add(spriteSets.prime, "idle", 1, 8, 250, -2)
	sprite.add(spriteSets.prime, "dance1", 9, 4, 250, -1)
	sprite.add(spriteSets.prime, "dance2", 13, 4, 250, -1)
	sprite.add(spriteSets.prime, "dance3", 17, 5, 250, -1)
end

function view.unload ()
	for name, spriteSheet in pairs(spriteSheets) do
		spriteSheet:removeSelf()
	end
	spriteSheets = nil
	spriteSets   = nil
end

function view.new (name)
	local self = display.newGroup()
	
	local anim = sprite.newSprite(spriteSets[name])
	self:insert(anim)
	display.zero(anim)
	
	self:setReferencePoint(display.BottomCenterReferencePoint)
	
	local nameLabel = display.newText(self, "", 0, 0, "Bauhaus93", 38)
	nameLabel:setTextColor(0x00, 0x00, 0x00)
	
	local function onAnimationEvent (event)
		if "end" == event.phase then
			anim.xScale = 1
			self:idle()
		end
	end
	anim:addEventListener("sprite", onAnimationEvent)
	
	function self:setName (name)
		nameLabel.text = name
		nameLabel:setReferencePoint(display.TopCenterReferencePoint)
		nameLabel.x = 0
		nameLabel.y = anim.y + anim.height / 2 - 15
	end
	
	function self:idle ()
		anim:prepare("idle")
		anim:play()
	end
	
	function self:pause ()
		anim:pause()
	end
	
	function self:dance (id)
		if id > NUM_DANCES then
			id = id - NUM_DANCES
			anim.xScale = -1
		end
		anim:prepare("dance"..id)
		anim:play()
	end
	
	function self:sendToFront (time)
		time = time or 250
		transition.to(self, {
			time = time,
			x    = 0,
			onComplete = function ()
				self:toFront()
				transition.to(self, {
					time = time,
					xScale = 1.0,
					yScale = 1.0
				})
			end
		})
	end
	
	function self:sendToBack (time)
		time = time or 250
		transition.to(self, {
			time = time,
			x    = display.contentCenterX - 100,
			onComplete = function ()
				self:toBack()
				transition.to(self, {
					time = time,
					xScale = 0.5,
					yScale = 0.5
				})
			end
		})
	end
	
	function destroy ()
		self:removeSelf()
		self      = nil
		anim      = nil
		nameLabel = nil
	end
		
	return self
end

return view
