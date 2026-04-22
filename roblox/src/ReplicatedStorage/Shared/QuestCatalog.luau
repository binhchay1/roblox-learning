export type SubjectQuest = {
	id: string,
	subject: string,
	tier: "cap1" | "cap2",
	levelMin: number,
	levelMax: number,
	displayName: string,
}

local QuestCatalog: { SubjectQuest } = {
	-- Cap 1
	{ id = "tv_writing_01", subject = "tieng_viet", tier = "cap1", levelMin = 1, levelMax = 8, displayName = "Tieng Viet - Ren ky nang viet" },
	{ id = "math_basic_01", subject = "toan", tier = "cap1", levelMin = 1, levelMax = 8, displayName = "Toan - Phep tinh co ban" },
	{ id = "eng_beginner_01", subject = "tieng_anh", tier = "cap1", levelMin = 3, levelMax = 10, displayName = "Tieng Anh - Beginner (lop 3+)" },
	{ id = "tnxh_01", subject = "tnxh", tier = "cap1", levelMin = 1, levelMax = 7, displayName = "Tu nhien va Xa hoi" },
	{ id = "lsdl_cap1_01", subject = "lich_su_dia_ly", tier = "cap1", levelMin = 4, levelMax = 10, displayName = "Lich su va Dia ly (cap 1)" },
	{ id = "khoa_hoc_cap1_01", subject = "khoa_hoc", tier = "cap1", levelMin = 4, levelMax = 10, displayName = "Khoa hoc (su song - nang luong - vat chat)" },
	{ id = "tinhoc_cn_cap1_01", subject = "tin_hoc_cong_nghe", tier = "cap1", levelMin = 3, levelMax = 10, displayName = "Tin hoc va Cong nghe (cap 1)" },

	-- Cap 2
	{ id = "ngu_van_01", subject = "ngu_van", tier = "cap2", levelMin = 11, levelMax = 20, displayName = "Ngu van - Tac pham va tao lap van ban" },
	{ id = "toan_daiso_hinhhoc_01", subject = "toan", tier = "cap2", levelMin = 11, levelMax = 20, displayName = "Toan - Dai so / Hinh hoc" },
	{ id = "tieng_anh_cap2_01", subject = "tieng_anh", tier = "cap2", levelMin = 11, levelMax = 20, displayName = "Ngoai ngu 1 - Tieng Anh (cap 2)" },
	{ id = "khtn_01", subject = "khoa_hoc_tu_nhien", tier = "cap2", levelMin = 12, levelMax = 22, displayName = "KHTN - Ly Hoa Sinh tich hop" },
	{ id = "lsdl_cap2_01", subject = "lich_su_dia_ly", tier = "cap2", levelMin = 11, levelMax = 22, displayName = "Lich su va Dia ly (cap 2)" },
	{ id = "tin_hoc_cap2_01", subject = "tin_hoc", tier = "cap2", levelMin = 11, levelMax = 22, displayName = "Tin hoc - Ky nang may tinh / lap trinh co ban" },
	{ id = "cong_nghe_cap2_01", subject = "cong_nghe", tier = "cap2", levelMin = 11, levelMax = 22, displayName = "Cong nghe - Nong nghiep / cong nghiep / gia dinh" },
}

return QuestCatalog
