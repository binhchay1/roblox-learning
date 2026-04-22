local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local RequestQuestRemote = Remotes:WaitForChild("RequestQuest") :: RemoteEvent
local SubmitAnswerRemote = Remotes:WaitForChild("SubmitAnswer") :: RemoteEvent
local SyncStateRemote = Remotes:WaitForChild("SyncState") :: RemoteEvent

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EduHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local info = Instance.new("TextLabel")
info.Name = "TopInfo"
info.Size = UDim2.fromOffset(560, 40)
info.Position = UDim2.fromOffset(16, 16)
info.BackgroundTransparency = 0.25
info.TextScaled = true
info.Text = "HP: 100 | EXP: 0 | Lv: 1 | Tien: 0"
info.Parent = screenGui

local questInfo = Instance.new("TextLabel")
questInfo.Name = "QuestInfo"
questInfo.Size = UDim2.fromOffset(560, 36)
questInfo.Position = UDim2.fromOffset(16, 62)
questInfo.BackgroundTransparency = 0.35
questInfo.TextScaled = true
questInfo.Text = "Quest: Dang cho du lieu..."
questInfo.Parent = screenGui

local questionBox = Instance.new("TextLabel")
questionBox.Name = "Question"
questionBox.Size = UDim2.fromOffset(560, 88)
questionBox.Position = UDim2.fromOffset(16, 108)
questionBox.BackgroundTransparency = 0.2
questionBox.TextWrapped = true
questionBox.TextScaled = true
questionBox.Text = "Nhan quest de bat dau."
questionBox.Parent = screenGui

local requestButton = Instance.new("TextButton")
requestButton.Name = "RequestQuest"
requestButton.Size = UDim2.fromOffset(180, 36)
requestButton.Position = UDim2.fromOffset(16, 204)
requestButton.TextScaled = true
requestButton.Text = "Nhan Quest"
requestButton.Parent = screenGui

local feedback = Instance.new("TextLabel")
feedback.Name = "Feedback"
feedback.Size = UDim2.fromOffset(560, 30)
feedback.Position = UDim2.fromOffset(16, 246)
feedback.BackgroundTransparency = 1
feedback.TextScaled = true
feedback.Text = ""
feedback.Parent = screenGui

local answerButtons = {}
for i = 1, 3 do
	local btn = Instance.new("TextButton")
	btn.Name = "Answer" .. i
	btn.Size = UDim2.fromOffset(560, 36)
	btn.Position = UDim2.fromOffset(16, 288 + (i - 1) * 44)
	btn.Text = "-"
	btn.TextScaled = true
	btn.Parent = screenGui
	answerButtons[i] = btn
end

local currentQuestionId: string? = nil

local function setAnswerButtonsEnabled(enabled: boolean)
	for _, button in ipairs(answerButtons) do
		button.Active = enabled
		button.AutoButtonColor = enabled
	end
end

local function renderStats(state: any)
	info.Text = string.format(
		"HP: %d | EXP: %d/100 | Lv: %d | Tien: %d | Power: %d | StatPoint: %d",
		state.health or 0,
		state.exp or 0,
		state.level or 1,
		state.money or 0,
		state.power or 0,
		state.statPoints or 0
	)

	local questId = (state.currentQuest and state.currentQuest.id) or "unknown"
	questInfo.Text = string.format(
		"Quest: %s | Tien do: %d/%d | Dot pha: %s",
		questId,
		state.questKills or 0,
		state.questTarget or 0,
		tostring(state.canBreakthrough == true)
	)
end

local function renderQuestion(question: any)
	if not question then
		questionBox.Text = "Nhan quest de lay cau hoi."
		currentQuestionId = nil
		setAnswerButtonsEnabled(false)
		return
	end

	currentQuestionId = question.id
	questionBox.Text = question.prompt or "Cau hoi khong hop le."
	setAnswerButtonsEnabled(true)
	for i = 1, 3 do
		local optionText = question.options and question.options[i] or "-"
		answerButtons[i].Text = string.format("%d) %s", i, optionText)
	end
end

requestButton.MouseButton1Click:Connect(function()
	feedback.Text = "Dang lay quest..."
	RequestQuestRemote:FireServer()
end)

for i, button in ipairs(answerButtons) do
	button.MouseButton1Click:Connect(function()
		if not currentQuestionId then
			return
		end
		setAnswerButtonsEnabled(false)
		SubmitAnswerRemote:FireServer({
			questionId = currentQuestionId,
			choiceIndex = i,
		})
	end)
end

SyncStateRemote.OnClientEvent:Connect(function(state, question, result)
	if state then
		renderStats(state)
	end
	if question ~= nil then
		renderQuestion(question)
	end

	if result then
		if result.isCorrect then
			feedback.Text = "Tra loi dung! +Diem +EXP"
		else
			feedback.Text = "Sai roi, thu lai cau tiep theo."
		end
		if result.questDone then
			feedback.Text ..= " | Hoan thanh quest!"
		end
	end
end)
