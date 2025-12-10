-- Backport Texture:SetColorTexture for 3.3.5 clients.
local texture = CreateFrame("Frame"):CreateTexture()
local meta = getmetatable(texture)

if meta and meta.__index then
	-- Always add the method, even if it exists (in case of version conflicts)
	if not meta.__index.SetColorTexture then
		function meta.__index:SetColorTexture(r, g, b, a)
			if type(r) == "table" then
				-- Handle table format: {r, g, b, a}
				return self:SetTexture(r[1] or r.r or 1, r[2] or r.g or 1, r[3] or r.b or 1, r[4] or r.a or 1)
			end
			-- Handle individual parameters: r, g, b, a
			r = r or 1
			g = g or 1
			b = b or 1
			a = a or 1
			-- Use white texture with color modulation
			self:SetTexture("Interface\\Buttons\\WHITE8X8")
			self:SetVertexColor(r, g, b, a)
		end
	end
end

texture:Hide()
texture:SetTexture(nil)
texture = nil

