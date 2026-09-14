local perk_name = "Sleight"
local perk_price = 175 --1500

MM_PERKS[MMPERK_SLEIGHT] = {
	icon = "MM_PI_SLEIGHT",
	icon_scale = FU/2,
	name = perk_name,

	description = {
		--"\x82When equipped:\x80 Pressing [TOSSFLAG] will",
		"\x82When equipped:\x80 You can charge your thrown",
		"knives 40% faster with \x82[FIRE NORMAL]\x80!",
		"Thrown knives also travel 15% faster!"
	},
	cost = perk_price,
}

local id = MM.Shop.addItem({
	name = perk_name,
	price = perk_price,
	category = MM_PERKS.category_id
})
MM.Shop.items[id].perk_id = MMPERK_SLEIGHT