--- cat_view.lua
--
-- The cat_view is an animated cat sprite (Pi or Prime) that has a name plate under it.
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

local sprite = require "sprite"

local NUM_DANCES = 3

local spriteSheets, spriteSets

local view = {}

--- Important.  Must be called prior to view.new().
-- This function loads the sprite sheets into memory.
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
	
	-- Once loaded, the data modules can be removed from memory.
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

--- Unloads the sprite sheets from memory.
function view.unload ()
	for name, spriteSheet in pairs(spriteSheets) do
		spriteSheet:removeSelf()
	end
	spriteSheets = nil
	spriteSets   = nil
end

--- Creates a new cat view.
--
-- @param name The name of the cat to be displayed.  Currently supports 'pi' and 'prime'.
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
	
	--- Sets the name that is displayed beneath this cat.
	--
	-- @param name The name of the cat.
	function self:setName (name)
		nameLabel.text = name
		nameLabel:setReferencePoint(display.TopCenterReferencePoint)
		nameLabel.x = 0
		nameLabel.y = anim.y + anim.height / 2 - 15
	end
	
	--- The cat will begin to play his/her idle animation.
	-- This is played automatically after a dance.
	function self:idle ()
		anim:prepare("idle")
		anim:play()
	end
	
	function self:pause ()
		anim:pause()
	end
	
	--- Plays a dance animation.
	--
	-- @param id The numeric id of the dance.
	function self:dance (id)
		if id > NUM_DANCES then
			-- Half of the animations are simply flipped to reduce texture memory useage.
			id = id - NUM_DANCES
			anim.xScale = -1
		end
		anim:prepare("dance"..id)
		anim:play()
	end
	
	--- Makes this cat tween into the front position.
	--
	-- @param The time for the tween to take place (default 250ms).
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
	
	--- Makes this cat tween into the back position.
	--
	-- @param The time for the tween to take place (default 250ms).
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
