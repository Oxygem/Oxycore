local brands = oxy.config.brands

local brand = {}

--setup our brand
function brand:setup()
    local brand = brands[luawa.request.hostname] or {}
    self.name = brand.name or brands.default.name
    self.logo = brand.logo or brands.default.logo
end

return brand