-- List citizens not in any of the burrows passed as arguments.
--
-- Version 1.0:
--    Removed column names
--    Removed profession coloring
--    Changed 'occupation' to 'profession'
--    Incorporated a couple of technical suggestions from Putnam
--    Corrected logic for speeds
--    Aligned columns in the output
--    Moved speed to first column, to simplify columnation logic
-- 
-- Credit where due - essentially all of this code is from existing scripts:
--    fat-dwarves.lua
--    siren.lua

local args = {...}
local burrows = {}
local dorfs = {}
local name

-- sanity checks:
if not dfhack.isMapLoaded() then
    qerror('You must load a map to use this.')
end
if #args == 0 then
    qerror('Pass the name(s) of one or more burrows as arguments.')
    return
end

-- show help text:
if args[1] == 'help' then
    print('')
    print('Shows relative speed, name, and profession of citizens who are')
    print('not in any of the specified burrows')
    print('')
    print('Usage:')
    print('   whosout <burrowname(s)>')
    print('')
    return
end

-- see if a location is in one of the burrows in the table built below:
function inBurrows(pos)
    if #burrows == 0 then
        return false
    else
        for _,v in ipairs(burrows) do
            if dfhack.burrows.isAssignedTile(v, pos) then
                return true
            end
        end
        return false
    end
end

-- comparator for sorting units by name:
function compNames(a,b)
    return dfhack.TranslateName(dfhack.units.getVisibleName(a)) < dfhack.TranslateName(dfhack.units.getVisibleName(b))
end

-- round a positive number to an integer:
function round(n)
    return math.floor(n+0.5)
end

-- build a table of the burrows in the argument list:
for _,v in ipairs(args) do
    local b = dfhack.burrows.findByName(v)
    if not b then
        qerror('Unknown burrow: '..v)
    else
        table.insert(burrows, b)
    end
end

-- collect and display a list of the citizens not in one of those burrows:
for _,v in ipairs(df.global.world.units.active) do
    if dfhack.units.isCitizen(v) then
        local x,y,z = dfhack.units.getPosition(v)
        if not inBurrows(xyz2pos(x,y,z)) then
            table.insert(dorfs,v)
        end
    end
end
dfhack.color(nil)
if #dorfs == 0 then
    if #burrows == 1 then
        print('All your live, sane citizens are in that burrow.')
    else
        print('All your live, sane citizens are in one of those burrows.')
    end
else
    table.sort(dorfs,compNames)
    for _,v in ipairs(dorfs) do
    name = dfhack.TranslateName(dfhack.units.getVisibleName(v))
    dfhack.print(round(1000000/dfhack.units.computeMovementSpeed(v)),name)
    if string.len(name) < 32 then
        dfhack.print('\t')
    end
    if string.len(name) < 24 then
        dfhack.print('\t')
    end
    if string.len(name) < 16 then
        dfhack.print('\t')
    end
    if string.len(name) < 8 then
        dfhack.print('\t')
    end
    print(dfhack.units.getProfessionName(v))
    end
end