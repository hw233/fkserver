return {
	escape = function(s)
		s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
		return string.gsub(s, " ", "+")
	end ,
	unescape = function(s)
		return string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
	end,
}