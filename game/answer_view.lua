--- answer_view.lua
--
-- The answer_view is the red speech bubble at the bottom of the screen.
-- It displays the equation that you are creating, or trying to solve.
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

local NUM_FACTORS = 3

function view.new ()
	local self = display.newGroup()
	
	local bar = display.newImage(self, "res/img/game_answer_bar.png")
	display.zero(bar)
	
	local label = display.newText(self, "", 0, 0, "Bauhaus93", 82)
	label:setTextColor(0xff, 0xff, 0xff)
	
	local factors = {}
	local answer
	
	local function updateLabel ()
		label.text = table.concat(factors, " * ")
		if answer then
			label.text = label.text.." = "..answer
		end
		label.size = 82
		while label.width > bar.width - 30 do
			label.size = label.size - 1
		end
		label:setReferencePoint(display.CenterReferencePoint)
		display.zero(label)
		label.y = label.y + 35
	end
	
	--- Adds a factor to this equation, or updates an existing one.
	--
	-- @param factor The factor to add.
	-- @param pos The position to add the factor to.  Defaults to the next highest position.
	function self:addFactor (factor, pos)
		pos = pos or #factors + 1
		factors[pos] = factor
		updateLabel()
	end
	
	--- Adds the 'answer' (right hand side) to the equation.
	--
	-- @param newAnswer The answer to the right hand side.
	function self:addAnswer (newAnswer)
		answer = newAnswer
		updateLabel()
	end
	
	--- Clears the equation.
	function self:clear ()
		label.text = ""
		factors    = {}
		answer     = nil
	end
	
	function self:destroy ()
		self:removeSelf()
		self    = nil
		bar     = nil
		label   = nil
		factors = nil
	end
	
	return self
end

return view
