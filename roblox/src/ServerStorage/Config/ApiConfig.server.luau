-- Keep secret config in ServerStorage so clients cannot read it.
-- Replace values in production.
local ApiConfig = {
	BaseUrl = "http://localhost:3000/api/v1/game",
	GameSecret = "change_me_for_dev_only",
	TimeoutSeconds = 8,
	MaxRetries = 3,
	RetryBackoffSeconds = 1.25,
}

return ApiConfig
