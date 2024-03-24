
local dice = {}

function dice.roll_dice(dice_max)
	return math.random(1,dice_max)
end

function dice.roll_multiple_dice(num_dice, dice_max)
	local ary = {}
	for i=1,num_dice do
		table.insert(ary, dice.roll_dice(dice_max))
	end
	return ary
end

return dice
