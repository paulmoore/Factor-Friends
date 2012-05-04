local widget = require "widget"

local view = {}

local NUM_BTNS = 6

function view.new ()
	local self = display.newGroup()
	
	local function onButtonEvent (event)
		local btn = event.target
		if "release" == event.phase then
			btn.alpha         = 0.5
			btn.isHitTestable = false
			self:dispatchEvent({
				name = "select",
				id   = event.target.id
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
		btn.alpha = 0.0
		btns[i]   = btn
		display.zero(btn)
		self:insert(btn)
	end
	
	function self:show ()
		local incr   = math.pi * 2 / NUM_BTNS
		local xscale = display.contentWidth / 2.5
		local yscale = display.contentHeight / 2.5
		for i, btn in ipairs(btns) do
			local deg = (i - 1) * incr
			local nx = math.cos(deg) * xscale
			local ny = math.sin(deg) * yscale
			transition.to(btn, {
				time       = 500,
				x          = nx,
				y          = ny,
				alpha      = 1.0,
				transition = easing.outQuad
			})
		end
	end
	
	function self:hide ()
		for i, btn in ipairs(btns) do
			transition.to(btn, {
				time       = 500,
				x          = 0,
				y          = 0,
				alpha      = 0.0,
				transition = easing.outQuad
			})
		end
	end
	
	function self:setLabels (labels)
		for i, label in ipairs(labels) do
			btns[i]:setLabel(tostring(label))
		end
	end
	
	function self:destroy ()
		btns = nil
		self:removeSelf()
		self = nil
	end
	
	return self
end

return view
