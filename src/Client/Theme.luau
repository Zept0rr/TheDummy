--!strict
-- Client visual tokens. Not balance.

export type Theme = {
	colors: {
		bg: Color3,
		panel: Color3,
		panelAlt: Color3,
		stroke: Color3,
		text: Color3,
		muted: Color3,
		bonk: Color3,
		ready: Color3,
		poor: Color3,
		locked: Color3,
		tabOn: Color3,
		tabOff: Color3,
		hit: Color3,
	},
	font: {
		display: Enum.Font,
		title: Enum.Font,
		body: Enum.Font,
		mono: Enum.Font,
	},
}

local Theme: Theme = {
	colors = {
		bg = Color3.fromRGB(18, 14, 12),
		panel = Color3.fromRGB(36, 28, 24),
		panelAlt = Color3.fromRGB(48, 38, 32),
		stroke = Color3.fromRGB(72, 56, 44),
		text = Color3.fromRGB(246, 236, 220),
		muted = Color3.fromRGB(168, 150, 132),
		bonk = Color3.fromRGB(255, 196, 74),
		ready = Color3.fromRGB(214, 122, 42),
		poor = Color3.fromRGB(62, 54, 50),
		locked = Color3.fromRGB(52, 46, 44),
		tabOn = Color3.fromRGB(255, 196, 74),
		tabOff = Color3.fromRGB(72, 60, 52),
		hit = Color3.fromRGB(255, 220, 120),
	},
	font = {
		display = Enum.Font.GothamBold,
		title = Enum.Font.GothamBold,
		body = Enum.Font.Gotham,
		mono = Enum.Font.Code,
	},
}

return Theme
