local PlayerProgressService = {}

export type SubjectPoints = {
	toan: number,
	tieng_viet: number,
	tieng_anh: number,
	ngu_van: number,
	khoa_hoc_tu_nhien: number,
	lich_su_dia_ly: number,
	tin_hoc: number,
	cong_nghe: number,
	tnxh: number,
	khoa_hoc: number,
	tin_hoc_cong_nghe: number,
}

function PlayerProgressService.NewProfile()
	return {
		health = 100,
		exp = 0,
		level = 1,
		money = 0,
		statPoints = 0,
		power = 0,
		streak = 0,
		questKills = 0,
		questTarget = 5,
		currentQuest = nil,
		currentQuestion = nil,
		subjectPoints = {
			toan = 0,
			tieng_viet = 0,
			tieng_anh = 0,
			ngu_van = 0,
			khoa_hoc_tu_nhien = 0,
			lich_su_dia_ly = 0,
			tin_hoc = 0,
			cong_nghe = 0,
			tnxh = 0,
			khoa_hoc = 0,
			tin_hoc_cong_nghe = 0,
		} :: SubjectPoints,
	}
end

function PlayerProgressService.ApplyCorrectAnswer(profile: any, subjectCode: string, points: number)
	profile.exp += points
	profile.money += math.floor(points / 2)
	profile.power += points
	profile.questKills += 1
	profile.streak += 1
	profile.subjectPoints[subjectCode] = (profile.subjectPoints[subjectCode] or 0) + points

	while profile.exp >= 100 do
		profile.exp -= 100
		profile.level += 1
		profile.statPoints += 3
	end
end

function PlayerProgressService.ApplyWrongAnswer(profile: any)
	profile.streak = 0
	profile.health = math.max(0, profile.health - 5)
end

function PlayerProgressService.CanBreakthrough(profile: any): boolean
	return profile.power >= 100 and profile.level >= 5
end

return PlayerProgressService
