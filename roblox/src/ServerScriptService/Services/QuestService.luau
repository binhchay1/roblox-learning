local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local QuestCatalog = require(Shared:WaitForChild("QuestCatalog"))

local QuestService = {}

function QuestService.GetQuestForLevel(level: number)
	for _, quest in ipairs(QuestCatalog) do
		if level >= quest.levelMin and level <= quest.levelMax then
			return quest
		end
	end
	return QuestCatalog[1]
end

function QuestService.DescribeProgress(points: number)
	local threshold = 100
	local canBreakthrough = points >= threshold
	return {
		points = points,
		threshold = threshold,
		canBreakthrough = canBreakthrough,
	}
end

return QuestService
