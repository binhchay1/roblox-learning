local PortalService = {}

PortalService.HistoryDungeons = {
	{ slug = "van-lang", displayName = "Van Lang - Au Lac" },
	{ slug = "bach-dang", displayName = "Bach Dang Giang" },
	{ slug = "dong-do", displayName = "Dong Do - Thang Long" },
	{ slug = "tay-son", displayName = "Phong trao Tay Son" },
	{ slug = "doc-lap", displayName = "Hanh trinh Doc lap hien dai" },
}

function PortalService.GetDungeonBySlug(slug: string)
	for _, dungeon in PortalService.HistoryDungeons do
		if dungeon.slug == slug then
			return dungeon
		end
	end
	return nil
end

return PortalService
