-- Show any cursed citizens.
--
-- Version 1.0

local args = {...}
local dorfs = {}
local name

dfhack.color(nil)

-- sanity checks:
if not dfhack.isMapLoaded() then
    qerror('show-cursed only works when a map is loaded.')
end
if #args > 0 then
   qerror('No arguments are currently allowed')
end

-- comparator for sorting units by name:
function compNames(a,b)
    return dfhack.TranslateName(dfhack.units.getVisibleName(a)) < dfhack.TranslateName(dfhack.units.getVisibleName(b))
end

-- build a list of citizens:
for _,v in ipairs(df.global.world.units.active) do
    if dfhack.units.isCitizen(v) then
        table.insert(dorfs,v)
    end
end

-- sort the list by name:
table.sort(dorfs,compNames)

-- show the list:
for _,v in ipairs(dorfs) do
    name = dfhack.units.getIdentity(v)
    if name == nil then
--        print(name)
    else
       print(dfhack.TranslateName(dfhack.units.getVisibleName(v)),v.curse.name)
    end
end
dfhack.color(nil)