--- splash_view.lua
--
-- This view is meant for displaying info text for a short period of time to the user.
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

local view = {}

function view.new ()
	local self = display.newGroup()
	
	local ruler = display.newImage(self, "res/img/game_ruler.png")
	display.zero(ruler)
	
	local label = display.newText(self, "", 0, 0, "Bauhaus93", 38)
	label:setTextColor(0x00, 0x00, 0x00)
	
	local queue = {}
	
	self.rotation  = -20
	self.alpha     = 0
	self.xScale    = 0.01
	self.yScale    = 0.01
	
	local inUse    = false
	
	local function shrink ()
		transition.to(self, {
			time       = 300,
			transition = easing.inExpo,
			alpha      = 0,
			xScale     = 0.01,
			yScale     = 0.01,
			onComplete = function ()
				inUse = false
				if #queue > 0 then
					self:show(table.remove(queue, 1))
				end
			end
		})
	end
	
	local function expand ()
		transition.to(self, {
			time       = 300,
			transition = easing.inExpo,
			alpha      = 1,
			xScale     = 1,
			yScale     = 1,
			onComplete = function ()
				timer.performWithDelay(1500, shrink, 1)
			end
		})
	end
	
	--- Displays info text, after the previous text has disappeared.
	--
	-- @param text The text to display.
	function self:show (text)
		-- The purpose of the queue is so the user of this view can call it multiple times in a row.
		-- If text is currently being shown, it will be placed in a queue until this view is ready again.
		if inUse then
			queue[#queue + 1] = text
			return
		end
		inUse      = true
		label.text = text
		label:setReferencePoint(display.CenterReferencePoint)
		display.zero(label)
		expand()
	end
	
	function self:destroy ()
		self:removeSelf()
		self  = nil
		ruler = nil
		label = nil
		queue = nil
	end
	
	return self
end

return view
