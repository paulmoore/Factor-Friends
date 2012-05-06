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
		label.y = label.y + 25
	end
	
	function self:addFactor (factor, pos)
		pos = pos or #factors + 1
		factors[pos] = factor
		updateLabel()
	end
	
	function self:addAnswer (newAnswer)
		answer = newAnswer
		updateLabel()
	end
	
	function self:clear ()
		label.text = ""
		factors    = {}
		answer     = nil
	end
	
	return self
end

return view
