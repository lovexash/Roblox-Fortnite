-- Aura RNG | Util
-- Shared helper functions used by both server and client.

local Util = {}

-- Abbreviate a large number into a short suffixed string.
-- 1500 -> "1.5K", 1_000_000 -> "1M", 1e15 -> "1Q"
local SUFFIXES = {
	{ 1e15, "Q" }, -- Quadrillion
	{ 1e12, "T" }, -- Trillion
	{ 1e9,  "B" }, -- Billion
	{ 1e6,  "M" }, -- Million
	{ 1e3,  "K" }, -- Thousand
}

function Util.Abbreviate(n)
	n = tonumber(n) or 0
	if n < 1000 then
		-- whole numbers stay whole, fractions show one decimal
		if n == math.floor(n) then
			return tostring(math.floor(n))
		end
		return string.format("%.1f", n)
	end
	for _, pair in ipairs(SUFFIXES) do
		local value, suffix = pair[1], pair[2]
		if n >= value then
			local scaled = n / value
			-- drop trailing ".0"
			if scaled >= 100 then
				return string.format("%d%s", math.floor(scaled), suffix)
			elseif scaled == math.floor(scaled) then
				return string.format("%d%s", scaled, suffix)
			else
				return string.format("%.2f%s", scaled, suffix)
			end
		end
	end
	return tostring(math.floor(n))
end

-- Format a rarity (the "1 in X" denominator) as a readable string.
function Util.FormatRarity(rarity)
	return "1 in " .. Util.Abbreviate(rarity)
end

-- Add thousands separators: 1234567 -> "1,234,567"
function Util.Commas(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	local sign = ""
	if s:sub(1, 1) == "-" then
		sign = "-"
		s = s:sub(2)
	end
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	out = out:gsub("^,", "")
	return sign .. out
end

-- Clamp helper.
function Util.Clamp(v, lo, hi)
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

-- Linear interpolation between two Color3 values.
function Util.LerpColor(a, b, t)
	return a:Lerp(b, t)
end

-- Format seconds as MM:SS.
function Util.Clock(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

-- Generate a short pseudo-unique id (used for trade sessions / aura instances).
local counter = 0
function Util.Uid()
	counter += 1
	return string.format("%x%x", os.clock() * 1000 % 0xFFFFFF, counter)
end

return Util
