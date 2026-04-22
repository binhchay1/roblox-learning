local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = ServerScriptService:WaitForChild("Services")
local QuestService = require(Services:WaitForChild("QuestService"))
local ApiService = require(Services:WaitForChild("ApiService"))
local QuestionService = require(Services:WaitForChild("QuestionService"))
local PlayerProgressService = require(Services:WaitForChild("PlayerProgressService"))

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")

local function getOrCreateRemote(name: string): RemoteEvent
	local existing = RemotesFolder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = RemotesFolder
	return remote
end

local RequestQuestRemote = getOrCreateRemote("RequestQuest")
local SubmitAnswerRemote = getOrCreateRemote("SubmitAnswer")
local SyncStateRemote = getOrCreateRemote("SyncState")

local Profiles: { [Player]: any } = {}

local function sanitizeQuestionForClient(question: any)
	return {
		id = question.id,
		prompt = question.prompt,
		options = question.options,
		subject = question.subject,
		questId = question.questId,
		pointsAward = question.pointsAward,
	}
end

local function buildSyncPayload(profile: any)
	return {
		health = profile.health,
		exp = profile.exp,
		level = profile.level,
		money = profile.money,
		statPoints = profile.statPoints,
		power = profile.power,
		streak = profile.streak,
		questKills = profile.questKills,
		questTarget = profile.questTarget,
		currentQuest = profile.currentQuest,
		subjectPoints = profile.subjectPoints,
		canBreakthrough = PlayerProgressService.CanBreakthrough(profile),
	}
end

local function assignQuest(profile: any)
	local quest = QuestService.GetQuestForLevel(profile.level)
	profile.currentQuest = quest
	profile.questTarget = math.max(3, math.floor(profile.level / 2) + 3)
	profile.questKills = 0
end

local function generateQuestion(profile: any)
	local question = QuestionService.GenerateForQuest(profile.currentQuest, profile.level)
	profile.currentQuestion = question
	return question
end

local function syncPlayer(player: Player)
	local profile = Profiles[player]
	if not profile then
		return
	end
	SyncStateRemote:FireClient(player, buildSyncPayload(profile))
end

Players.PlayerAdded:Connect(function(player)
	local profile = PlayerProgressService.NewProfile()
	Profiles[player] = profile
	assignQuest(profile)

	local accessOk, accessResponse = ApiService.CheckAccess(player.UserId, profile.currentQuest.id)
	if not accessOk then
		warn(string.format("[Bootstrap] CheckAccess failed for %s: %s", player.Name, accessResponse.error or "unknown_error"))
	else
		local allowed = accessResponse.body and accessResponse.body.data and accessResponse.body.data.allowed
		if allowed == false then
			-- Downgrade to a non-premium fallback for now.
			profile.currentQuest = QuestService.GetQuestForLevel(1)
		end
	end

	syncPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	Profiles[player] = nil
end)

RequestQuestRemote.OnServerEvent:Connect(function(player)
	local profile = Profiles[player]
	if not profile then
		return
	end

	if profile.currentQuest == nil then
		assignQuest(profile)
	end

	local question = generateQuestion(profile)
	SyncStateRemote:FireClient(player, buildSyncPayload(profile), sanitizeQuestionForClient(question))
end)

SubmitAnswerRemote.OnServerEvent:Connect(function(player, payload)
	local profile = Profiles[player]
	if not profile or not profile.currentQuestion then
		return
	end

	if type(payload) ~= "table" then
		return
	end

	local picked = tonumber(payload.choiceIndex)
	if not picked then
		return
	end

	local question = profile.currentQuestion
	local isCorrect = picked == question.correctIndex
	if isCorrect then
		PlayerProgressService.ApplyCorrectAnswer(profile, question.subject, question.pointsAward)

		local scorePayload = {
			robloxUserId = player.UserId,
			questCode = question.questId,
			points = question.pointsAward,
			correctCount = 1,
			totalCount = 1,
			clientAttemptId = question.id,
		}
		local submitOk, submitResponse = ApiService.SubmitScore(scorePayload)
		if not submitOk then
			warn(string.format("[Bootstrap] SubmitScore failed for %s: %s", player.Name, submitResponse.error or "unknown_error"))
		end
	else
		PlayerProgressService.ApplyWrongAnswer(profile)
	end

	local questDone = profile.questKills >= profile.questTarget
	if questDone then
		profile.money += 20 + (profile.level * 2)
		assignQuest(profile)
	end

	local nextQuestion = generateQuestion(profile)
	SyncStateRemote:FireClient(player, buildSyncPayload(profile), sanitizeQuestionForClient(nextQuestion), {
		isCorrect = isCorrect,
		questDone = questDone,
	})
end)
