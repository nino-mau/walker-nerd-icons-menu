Name = "nerd-icons"
NamePretty = "Nerd Icons"
Icon = "preferences-desktop-font"
Cache = false
Action = "wl-copy %VALUE%"
HideFromProviderlist = false
Description = "Search Nerd Font icons and copy glyph"
SearchName = true
KeepOpen = true

local HOME = os.getenv("HOME") or "."
local CACHE_DIR = HOME .. "/.cache/elephant/nerd-icons"
local GLYPH_FILE = CACHE_DIR .. "/glyphnames.json"
local GLYPH_URL = "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/glyphnames.json"
local MAX_RESULTS = 128

local LOCAL_GLYPH_PATHS = {
	os.getenv("NERD_FONTS_GLYPHS"),
	HOME .. "/.local/share/nerd-fonts/glyphnames.json",
	HOME .. "/.local/share/fonts/nerd-fonts/glyphnames.json",
	HOME .. "/.config/nerd-fonts/glyphnames.json",
	"/usr/share/nerd-fonts/glyphnames.json",
	"/usr/share/fonts/nerd-fonts/glyphnames.json",
}

os.execute("mkdir -p '" .. CACHE_DIR .. "'")

local function shellEscape(value)
	if value == nil then
		return "''"
	end
	return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function readFile(path)
	if not path or path == "" then
		return nil
	end
	local file = io.open(path, "r")
	if not file then
		return nil
	end
	local content = file:read("*a")
	file:close()
	if not content or content == "" then
		return nil
	end
	return content
end

local function writeFile(path, content)
	local file = io.open(path, "w")
	if not file then
		return false
	end
	file:write(content)
	file:close()
	return true
end

local function fetchUrl(url)
	local handle = io.popen("curl -fsSL " .. shellEscape(url) .. " 2>/dev/null")
	if handle then
		local content = handle:read("*a")
		handle:close()
		if content and content ~= "" then
			return content
		end
	end

	handle = io.popen("wget -qO- " .. shellEscape(url) .. " 2>/dev/null")
	if handle then
		local content = handle:read("*a")
		handle:close()
		if content and content ~= "" then
			return content
		end
	end

	return nil
end

local function ensureGlyphJson()
	local content = readFile(GLYPH_FILE)
	if content then
		return content
	end

	for _, path in ipairs(LOCAL_GLYPH_PATHS) do
		local localContent = readFile(path)
		if localContent then
			writeFile(GLYPH_FILE, localContent)
			return localContent
		end
	end

	local fetched = fetchUrl(GLYPH_URL)
	if fetched then
		writeFile(GLYPH_FILE, fetched)
		return fetched
	end

	return nil
end

local function utf8FromCodepoint(code)
	if code <= 0x7F then
		return string.char(code)
	elseif code <= 0x7FF then
		local b1 = 0xC0 + math.floor(code / 0x40)
		local b2 = 0x80 + (code % 0x40)
		return string.char(b1, b2)
	elseif code <= 0xFFFF then
		local b1 = 0xE0 + math.floor(code / 0x1000)
		local b2 = 0x80 + (math.floor(code / 0x40) % 0x40)
		local b3 = 0x80 + (code % 0x40)
		return string.char(b1, b2, b3)
	elseif code <= 0x10FFFF then
		local b1 = 0xF0 + math.floor(code / 0x40000)
		local b2 = 0x80 + (math.floor(code / 0x1000) % 0x40)
		local b3 = 0x80 + (math.floor(code / 0x40) % 0x40)
		local b4 = 0x80 + (code % 0x40)
		return string.char(b1, b2, b3, b4)
	end
	return ""
end

local function unescapeJsonString(value)
	local out = value
	out = out:gsub("\\u(%x%x%x%x)", function(hex)
		return utf8FromCodepoint(tonumber(hex, 16))
	end)
	out = out:gsub('\\"', '"')
	out = out:gsub("\\\\", "\\")
	return out
end

local GLYPHS = nil
local GLYPH_ERROR = nil

local function loadGlyphs()
	if GLYPHS then
		return GLYPHS
	end

	local json = ensureGlyphJson()
	if not json then
		GLYPH_ERROR = "Could not load glyphnames.json"
		GLYPHS = {}
		return GLYPHS
	end

	local list = {}
	for key, body in json:gmatch('"([^"]+)"%s*:%s*{(.-)}') do
		if key ~= "METADATA" then
			local char = body:match('"char"%s*:%s*"([^"]+)"')
			local code = body:match('"code"%s*:%s*"([^"]+)"')
			if char and code then
				char = unescapeJsonString(char)
				table.insert(list, {
					key = key,
					key_lower = key:lower(),
					char = char,
					code = code,
					code_lower = tostring(code):lower(),
				})
			end
		end
	end

	table.sort(list, function(a, b)
		return a.key < b.key
	end)

	if #list == 0 then
		GLYPH_ERROR = "Parsed 0 glyphs from glyphnames.json"
	end

	GLYPHS = list
	return GLYPHS
end

local function normalizeQuery(query)
	local q = (query or ""):lower()
	q = q:gsub("^%s+", ""):gsub("%s+$", "")
	if q:match("^u%+") then
		q = q:gsub("^u%+", "")
	end
	return q
end

function GetEntries(query)
	local entries = {}
	local glyphs = loadGlyphs()

	if not glyphs or #glyphs == 0 then
		table.insert(entries, {
			Text = "Nerd icons unavailable",
			Subtext = GLYPH_ERROR or "No glyph data",
			Value = "",
		})
		return entries
	end

	local q = normalizeQuery(query)
	local count = 0

	for _, glyph in ipairs(glyphs) do
		if q == "" or glyph.key_lower:find(q, 1, true) or glyph.code_lower:find(q, 1, true) then
			table.insert(entries, {
				Text = glyph.char .. "  " .. glyph.key,
				Subtext = "U+" .. tostring(glyph.code):upper(),
				Icon = "face-smile",
				Value = glyph.char,
			})
			count = count + 1
			if count >= MAX_RESULTS then
				break
			end
		end
	end

	if #entries == 0 then
		table.insert(entries, {
			Text = "No icons found",
			Subtext = "Try another query (name or code, e.g. 'cod-arrow' or 'f101')",
			Value = "",
		})
	end

	return entries
end
