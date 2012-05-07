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
	
	function self:show (text)
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
