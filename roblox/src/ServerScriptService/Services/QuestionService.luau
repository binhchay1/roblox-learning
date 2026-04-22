local HttpService = game:GetService("HttpService")

export type QuestionData = {
	id: string,
	prompt: string,
	options: { string },
	correctIndex: number,
	subject: string,
	questId: string,
	pointsAward: number,
}

local QuestionService = {}

local function buildMathQuestion(level: number, questId: string): QuestionData
	local a = math.random(1, 8 + level)
	local b = math.random(1, 8 + level)
	local correct = a + b
	local wrong1 = correct + math.random(1, 3)
	local wrong2 = math.max(0, correct - math.random(1, 3))
	local options = { tostring(correct), tostring(wrong1), tostring(wrong2) }
	local correctIndex = math.random(1, #options)
	options[1], options[correctIndex] = options[correctIndex], options[1]

	return {
		id = HttpService:GenerateGUID(false),
		prompt = string.format("Toan: %d + %d = ?", a, b),
		options = options,
		correctIndex = correctIndex,
		subject = "toan",
		questId = questId,
		pointsAward = 10,
	}
end

local function buildLanguageQuestion(subjectLabel: string, questId: string, subjectCode: string): QuestionData
	local prompts = {
		{
			prompt = string.format("%s: Chon tu viet dung chinh ta", subjectLabel),
			options = { "hoc tap", "hocc tap", "hocctap" },
			correctIndex = 1,
		},
		{
			prompt = string.format("%s: Chon cau dung ngu phap", subjectLabel),
			options = { "Em dang hoc bai.", "Em dang hoc bai", "Em đang hoc bai." },
			correctIndex = 1,
		},
	}
	local picked = prompts[math.random(1, #prompts)]
	return {
		id = HttpService:GenerateGUID(false),
		prompt = picked.prompt,
		options = picked.options,
		correctIndex = picked.correctIndex,
		subject = subjectCode,
		questId = questId,
		pointsAward = 10,
	}
end

function QuestionService.GenerateForQuest(quest: any, level: number): QuestionData
	if quest.subject == "toan" then
		return buildMathQuestion(level, quest.id)
	end
	if quest.subject == "tieng_viet" or quest.subject == "ngu_van" then
		return buildLanguageQuestion("Ngu van", quest.id, quest.subject)
	end
	if quest.subject == "tieng_anh" then
		return {
			id = HttpService:GenerateGUID(false),
			prompt = "Tieng Anh: Chon nghia dung cua tu 'apple'",
			options = { "Qua tao", "Qua cam", "Qua chuoi" },
			correctIndex = 1,
			subject = "tieng_anh",
			questId = quest.id,
			pointsAward = 10,
		}
	end

	return {
		id = HttpService:GenerateGUID(false),
		prompt = string.format("%s: Chon dap an hop ly nhat", quest.displayName),
		options = { "Dap an A", "Dap an B", "Dap an C" },
		correctIndex = 1,
		subject = quest.subject,
		questId = quest.id,
		pointsAward = 8,
	}
end

return QuestionService
