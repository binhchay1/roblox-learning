local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

local ApiConfig = require(ServerStorage:WaitForChild("Config"):WaitForChild("ApiConfig"))

type JsonMap = { [string]: any }

local ApiService = {}

local function joinUrl(baseUrl: string, path: string): string
	if string.sub(path, 1, 1) == "/" then
		return baseUrl .. path
	end
	return baseUrl .. "/" .. path
end

local function decodeJsonSafe(raw: string): JsonMap
	local ok, result = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if ok and type(result) == "table" then
		return result :: JsonMap
	end
	return {}
end

local function requestOnce(options: {
	method: string,
	path: string,
	query: JsonMap?,
	body: JsonMap?,
	timeoutSeconds: number?,
})
	local query = options.query
	local finalPath = options.path
	if query then
		local queryParts = {}
		for key, value in query do
			table.insert(queryParts, HttpService:UrlEncode(key) .. "=" .. HttpService:UrlEncode(tostring(value)))
		end
		if #queryParts > 0 then
			finalPath ..= "?" .. table.concat(queryParts, "&")
		end
	end

	local payload = options.body and HttpService:JSONEncode(options.body) or nil
	local requestOptions = {
		Url = joinUrl(ApiConfig.BaseUrl, finalPath),
		Method = options.method,
		Headers = {
			["Content-Type"] = "application/json",
			["x-game-secret"] = ApiConfig.GameSecret,
		},
		Body = payload,
	}

	local done = false
	local ok = false
	local response = nil
	local timeoutSeconds = options.timeoutSeconds or ApiConfig.TimeoutSeconds

	task.spawn(function()
		local success, result = pcall(function()
			return HttpService:RequestAsync(requestOptions)
		end)
		done = true
		ok = success
		response = result
	end)

	local startedAt = os.clock()
	while not done and (os.clock() - startedAt) < timeoutSeconds do
		task.wait(0.05)
	end

	if not done then
		return false, {
			statusCode = 0,
			body = {},
			error = "timeout",
		}
	end

	if not ok then
		return false, {
			statusCode = 0,
			body = {},
			error = "request_failed",
		}
	end

	local rawBody = response.Body or "{}"
	local body = decodeJsonSafe(rawBody)
	if response.Success == true then
		return true, {
			statusCode = response.StatusCode,
			body = body,
		}
	end

	return false, {
		statusCode = response.StatusCode,
		body = body,
		error = "http_error",
	}
end

function ApiService.Request(options: {
	method: string,
	path: string,
	query: JsonMap?,
	body: JsonMap?,
	timeoutSeconds: number?,
	maxRetries: number?,
})
	local maxRetries = options.maxRetries or ApiConfig.MaxRetries
	local lastResult = nil
	for attempt = 1, maxRetries do
		local success, result = requestOnce(options)
		lastResult = result
		if success then
			return true, result
		end

		if attempt < maxRetries then
			local backoff = ApiConfig.RetryBackoffSeconds * attempt
			task.wait(backoff)
		end
	end
	return false, lastResult
end

function ApiService.SubmitScore(payload: {
	robloxUserId: number,
	questCode: string,
	points: number,
	correctCount: number?,
	totalCount: number?,
	clientAttemptId: string?,
})
	return ApiService.Request({
		method = "POST",
		path = "/submit-score",
		body = payload,
	})
end

function ApiService.CheckAccess(robloxUserId: number, questCode: string)
	return ApiService.Request({
		method = "GET",
		path = "/check-access",
		query = {
			robloxUserId = robloxUserId,
			questCode = questCode,
		},
	})
end

return ApiService
