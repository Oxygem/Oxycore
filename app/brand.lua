-- Oxypanel Core
-- File: app/brands.lua
-- Desc: determine which brand info to show

local brands = oxy.config.brands

local brand = {}

--setup our brand
function brand:setup()
    local brand = brands[luawa.request.hostname] or {}
    self.name = brand.name or brands.default.name
    self.logo = brand.logo or brands.default.logo
    self.web = brand.web or brands.default.web
end

return brand