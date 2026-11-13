_G.ModuloMarket = {}
assert(loadfile(arg[1] .. "/AddOns/ModuloMarket/TurnInData.lua"))()
assert(loadfile(arg[1] .. "/AddOns/ModuloMarket/TurnInEngine.lua"))()
local data = ModuloMarket.TurnInData
assert(#data.crates == 30, "expected all 30 labelled crates")
local countOptions, names, ids = 0, {}, {}
local catalog, byID = {}, {}
for _, crate in ipairs(data.crates) do
    assert(not ids[crate.id], "crate item IDs must be unique")
    ids[crate.id] = true
    local crateMarket = { itemID=crate.id, itemName=crate.name, minPriceCopper=1000, minPriceQuantity=1, totalQuantity=2 }
    byID[crate.id] = crateMarket
    for _, bundle in ipairs(crate.bundles) do
        countOptions = countOptions + 1
        assert(#bundle == 1, "each tooltip bullet is a separate alternative bundle")
        local name, qty = bundle[1][1], bundle[1][2]
        assert(type(name)=="string" and type(qty)=="number" and qty > 0)
        names[name] = true
    end
end
for name in pairs(names) do
    catalog[#catalog+1] = { itemID=100000+#catalog, itemName=name, minPriceCopper=100, minPriceQuantity=100, totalQuantity=100 }
end
assert(countOptions == 96, "expected 96 alternative material choices")
local rows = ModuloMarket.TurnInEngine.BuildRows(catalog, byID)
assert(#rows == 30, "all crates remain visible")
local first = rows[1]
assert(first.completionCostCopper == 2000, "completion cost includes one crate plus cheapest complete material option")
assert(first.cashReturnCopper == 250 and first.rewardFavor == 5 and first.reputation == 0)
assert(first.netCostCopper == 1750 and first.netCostPerFavorCopper == 350)
local artisan = rows[#rows]
assert(artisan.rewardFavor == nil and artisan.cashReturnCopper == nil and artisan.netCostPerFavorCopper == nil)
local shallow = {}
for _, item in ipairs(catalog) do
    shallow[#shallow+1] = { itemID=item.itemID, itemName=item.itemName, minPriceCopper=100, minPriceQuantity=1, totalQuantity=100 }
end
local shallowRows = ModuloMarket.TurnInEngine.BuildRows(shallow, byID)
assert(shallowRows[1].completionCostCopper == nil, "do not extrapolate beyond known cheapest-price depth")
assert(shallowRows[1].bestBundle == nil, "no falsely priced best bundle")
local noCrate = {}
for id, item in pairs(byID) do if id ~= rows[1].itemID then noCrate[id] = item end end
local noCrateRows = ModuloMarket.TurnInEngine.BuildRows(catalog, noCrate)
assert(noCrateRows[1].completionCostCopper == nil, "crate AH price is mandatory")
assert(data.firstTurnInBonus.favor == 50 and data.firstTurnInBonus.reputation == 2000)
print("PASS 30 crate definitions / unique IDs")
print("PASS 96 one-of bundle alternatives")
print("PASS crate + material completion cost")
print("PASS cash, Favor and reputation returns")
print("PASS Artisan unknown rewards remain unknown")
print("PASS insufficient cheapest-price depth fails closed")
print("PASS missing crate AH price fails closed")
print("PASS one-time Shipping Label bonus remains separate")
