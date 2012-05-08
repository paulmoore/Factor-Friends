--- factor_view.lua
--
-- The factor view is the interactive part of the UI where the user selects prime numbers.
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

local widget = require "widget"

local view = {}

local NUM_BTNS = 6

function view.new ()
	local self = display.newGroup()
	
	local selectText = display.newText(self, "", 0, 0, "Bauhaus93", 80)
	selectText:setTextColor(0xf5, 0x91, 0x33)
	
	local function onButtonEvent (event)
		local btn = event.target
		if "release" == event.phase and btn.isHitTestable then
			self:flash(btn:getLabel())
			btn.alpha         = 1
			btn.isHitTestable = false
			-- Propogate the event back up through this object.
			self:dispatchEvent({
				name = "select",
				id   = btn.id
			})
		end
	end
	
	local btns = {}
	for i = 1, NUM_BTNS do
		local btn = widget.newButton({
			width      = 128,
			height     = 128,
			id         = i,
			font       = "Bauhaus93",
			fontSize   = 82,
			labelColor = {default = {0xf5, 0x91, 0x33}, over = {0xf5, 0x91, 0x33}},
			onEvent    = onButtonEvent,
			default    = "res/img/game_btn_factor_default.png"
		})
		btn.alpha         = 0.0
		btns[i]           = btn
		btn.isHitTestable = false
		display.zero(btn)
		self:insert(btn)
	end
	
	--- Displays the interactive buttons.
	--
	-- @see setLabels
	function self:show ()
		-- Position the buttons around a circle.
		local incr   = math.pi * 2 / NUM_BTNS
		local xscale = display.contentWidth / 3.0
		local yscale = display.contentHeight / 2.8
		for i, btn in ipairs(btns) do
			local deg = (i - 1) * incr
			local nx = math.cos(deg) * xscale
			local ny = math.sin(deg) * yscale
			transition.to(btn, {
				time       = 500,
				x          = nx,
				y          = ny,
				alpha      = 1.0,
				transition = easing.outQuad,
				onComplete = function ()
					btn.isHitTestable = true
				end
			})
		end
	end
	
	--- Hides the interactive buttons.
	function self:hide ()
		for i, btn in ipairs(btns) do
			btn.isHitTestable = false
			transition.to(btn, {
				time       = 500,
				x          = 0,
				y          = 0,
				alpha      = 0.0,
				transition = easing.outQuad,
			})
		end
	end
	
	--- Sets the labels (text on the buttons).
	--
	-- @param labels An indexed table of labels.
	function self:setLabels (labels)
		for i, label in ipairs(labels) do
			btns[i]:setLabel(tostring(label))
		end
	end
	
	--- Normally, when a button is pressed, that buttons label is 'flashed' on the screen.
	-- This is a convienience method for one to be able do that manually.
	--
	-- @param text The text to flash in the center of this view.
	function self:flash (text)
		selectText.xScale = 3
		selectText.yScale = 3
		selectText.alpha  = 1
		selectText.text   = tostring(text)
		selectText:setReferencePoint(display.CenterReferencePoint)
		display.zero(selectText)
		transition.to(selectText, {
			time   = 500,
			alpha  = 0,
			xScale = 0.5,
			yScale = 0.5
		})
	end
	
	function self:destroy ()
		self:removeSelf()
		self       = nil
		btns       = nil
		selectText = nil
	end
	
	return self
end

return view
