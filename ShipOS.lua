--
-- mt_ShipOS 
-- https://github.com/MCLV-pandorabox/mt_ShipOS
--
-- by MCLV ( https://github.com/MCLV-pandorabox )
-- License: MIT-Zero. See below. Code should be free.
--   .  and I should have plenty of coffee. 
--   Maybe we can work something out if you feel like it.
--
-- Installing:
--   Make sure you have a touch screen, a jumpdrive and a luacontroller all connected properly with digiline.
--   Set touch screen channel to "touch", jumpdrive to "jumpdrive" . or . change mem.ui.screen1.channel and mem.jd.channel in the code below
--   Change mem.system.admin below to your player name.
--   copy/paste the ShipOS.lua code you have just edited in the luacontroller and run
--   That's it.
--
-- tags:
--  help:
--    help/install instructions
--  mxnote
--    comment by MCLV
--  mxedit 
--    bookmark by MCLV
--  F
--    function group description
--
-- MCLV 20230117
-- navigation and touch screen done
-- test multi user
-- MCLV 20230117
-- add bookmark screen and testing(OK) done
-- MCLV 20230118 added settings page and add user management
-- MCLV 20230124 added fleet support. just change the jumpdrive channel to the fleetcontroller's channel
-- MCLV 20230126 added new handy table functions table_key_exists and table_value_exits (tke,tve)
-- MCLV 20230126 improved multi user handling of touch screen - unauthorised user can look but no touch
local msg = event.msg
local dls = digiline_send
local table_insert = table.insert
-- F useful debug function
function log(msg)
    table_insert(mem.log, msg)
end
-- F data manipulation functions
function table_keys(tbl) --mxnote list all the keys of a table (php naming convention) 
    ks = {}
    local n = 0
    -- local tbl=table.sort(tbl)
    for i, v in pairs(tbl) do
        n = n + 1
        table_insert(ks, i)
        --ks[n]=tostring(i)
    end
    return ks
end
function table_key_exists(tbl,key)
    for i,v in pairs(tbl) do
        if i == key then return true end
    end
    return false
end
local tke = table_key_exists 
function table_value_exists(tbl,key)
    for i,v in pairs(tbl) do
        if v == key then return true end
    end
    return false
end
local tve=table_value_exists
function indexOf(array, value) --mxnote find index of the value in array(table) : Handy for dropdown boxes
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return 
end
function reverseTable(t) -- FAI: function written by OpenAI's chat https://chat.openai.com/
    local reversedTable = {}
    local itemCount = #t
    for i, v in ipairs(t) do
        reversedTable[itemCount + 1 - i] = v
    end
    return reversedTable
end
function merge(t1, t2)
    local t3 = {}
    for k, v in pairs(t1) do
        t3[k] = v
    end
    for k, v in pairs(t2) do
        t3[k] = v
    end
    return t3
end
function get_string(data, maxdepth) -- *FeXoR's Jumpdrive "code:get_string"
    local maxdepth = maxdepth or 3
    if type(data) == "string" then
        return data
    elseif type(data) == "table" and maxdepth > 0 then
        local oString = "{"
        for k, v in pairs(data) do
            local val = v
            if type(v) == "table" then
                val = get_string(val, maxdepth - 1)
            end
            oString = oString .. tostring(k) .. "=" .. tostring(val) .. ", "
        end
        return string.sub(oString, 1, -3) .. "}"
    else
        return tostring(data)
    end
    return "Something went wrong!"
end
function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end
function numberUnits(num, units) 
    local num = num or 0
    local suffix = ""
    if num >= 1000000 then
        suffix = "M"
        num = round(num / 1000000,1)
    elseif num >= 1000 then
        suffix = "k"
        num = round(num / 1000,1)
    end

    if suffix == "" and units then
        num = round(num,1)
    end

    return tostring(num) .. " " .. suffix .. units
end

-- F coordinate functions
function ctt(sInput) -- coordinates to table
    local tNumberList = {}
    if type(sInput) == "string" then
        local bContinuous = false
        for nChar = 1, #sInput do
            local nByte = sInput:byte(nChar)
            -- A new numerical string starts - potentially - ignoring repetitions of "-"
            if
                (bContinuous == false and (nByte == 45 or (nByte >= 48 and nByte <= 57))) or
                    (nByte == 45 and sInput:byte(nChar - 1) ~= 45)
             then
                -- Override previous non valid numerical string "-"
                if #tNumberList > 0 and tNumberList[#tNumberList] == "-" then
                    tNumberList[#tNumberList] = string.char(nByte)
                else
                    table_insert(tNumberList, string.char(nByte))
                end
                bContinuous = true
            elseif bContinuous and (nByte >= 48 and nByte <= 57) then
                tNumberList[#tNumberList] = tostring(tNumberList[#tNumberList]) .. string.char(nByte)
            elseif nByte ~= 45 then
                bContinuous = false
            end
        end
        -- Remove tailing non valid numerical string "-"
        if tNumberList[#tNumberList] == "-" then
            tNumberList[#tNumberList] = nil
        end
    end
    local tOutput = {}
    for i, name in ipairs({"x", "y", "z"}) do
        tOutput[name] = tonumber(tNumberList[i] or "0")
    end
    return tOutput
end
function cts(coordinate_table) -- coordinates to string
    return coordinate_table.x .. "," .. coordinate_table.y .. "," .. coordinate_table.z
end
function coords_add(c1, c2)
    if type(c1) == "string" then
        c1 = ctt(c1)
    end
    if type(c2) == "string" then
        c2 = ctt(c2)
    end
    local c3 = {}
    for k, v in pairs(c1) do
        c3[k] = v
    end
    for k, v in pairs(c2) do
        c3[k] = c3[k] + c2[k]
    end
    return c3
end
function coords_sub(c1, c2)
    if type(c1) == "string" then
        c1 = ctt(c1)
    end
    if type(c2) == "string" then
        c2 = ctt(c2)
    end
    local c3 = {}
    for k, v in pairs(c1) do
        c3[k] = v
    end
    for k, v in pairs(c2) do
        c3[k] = c3[k] - c2[k]
    end
    return c3
end
function coords_neg(c1)
    c2 = {}
    if type(c1) == "string" then
        c1 = ctt(c1)
    end
    for k, v in pairs(c1) do
        c2[k] = 0 - v
    end
    return c2
end
function split(str, delimiter) -- FAI
  local fields = {}
  local field = ""
  for i = 1, #str do
    local char = string.sub(str, i, i)
    if char == delimiter then
      table_insert(fields, field)
      field = ""
    else
      field = field .. char
    end
  end
  table_insert(fields, field)
  return fields
end
function join(tbl, delimiter)  -- FAI
  local str = ""
  for i, v in ipairs(tbl) do
    str = str .. v
    if i < #tbl then
      str = str .. delimiter
    end
  end
  return str
end

-- F Jumpdrive Bookmark functions
function bookmarkExport(bookmarks_table)
    s={};
    for k,v in pairs(bookmarks_table) do
        --table_insert(s, k .. "," .. v[1] .. "," .. v[2] .. "," .. v[3])
        table_insert(s, tostring(k) .. "," .. tostring(v))
    end
    table.sort(s)
    return s
end
function bookmarkImport(CSVBM) -- mxnote CSVBM= CSV bookmark text . format: name,x,y,z \n . name can not have special chars or spaces because it is used as a key in a hash table
    --mxnote: importing function takes a high tole on the luacontroller, and might time out! resulting in a no-save.
    -- bookmarks can still be added using the 'add button' .  Will need to find a nicer solution for this soon
   local T=csvtotable(CSVBM)
   local bm={}
   for i,v in ipairs(T) do
       if type(v) == "table" then
           bm[v[1]] = "" .. v[2] .. "," .. v[3] .. "," .. v[4] 
           --bm[i] = type(v) .. ": " .. v[1]
       end
   end
   return bm
end
function csvtotable(sInput) -- mxnote very simple csv reader. no escape characters, no quotes, if you want a comma in your field text: tuff luk
    -- mxnote CSV is a common data exchange format FeXoR, not cryptic at all imo ;)
    -- https://en.wikipedia.org/wiki/Comma-separated_values
    local fieldsep = string.byte(",")
    local linesep = string.byte("\n")
    local field = {}
    local lines = {"two"}
    --local acc = "" -- string accumulator
    --mxnote: I think acc is much easier to type then stringaccumulator, but allright, a replace is easily done to make it less 'cryptic'.
    local stringaccumulator = "" 
    local nByte=0;
    for nChar = 1, #sInput do
        nByte = sInput:byte(nChar)
        if nByte == linesep then
            table_insert(field, stringaccumulator)
            table_insert(lines, field)
            field = {}
            stringaccumulator = ""
        elseif nByte == fieldsep then
            table_insert(field, stringaccumulator)
            stringaccumulator = ""
        elseif nChar == #sInput then
            stringaccumulator = stringaccumulator .. string.char(nByte)
            table_insert(field,stringaccumulator)
            table_insert(lines,field)
            --we finished, but code may continue. no probl, xcept for eficiency
        else
            stringaccumulator = stringaccumulator .. string.char(nByte)
        end
    end
    return lines
end
-- F user managment functions
function acl_role(key)
    if indexOf(mem.system.admin, key) ~= nil then
        return "admin"
    elseif indexOf(mem.system.staff, key) ~= nil then
        return "staff"
    else
        return "user"
    end
end
-- F main stuff --
function jdset(c) --jumpdrive set -- (table) c,  returns nil
    dls(mem.jd.channel, merge({command = "set", formupdate = true}, c))
end
function init()
    --mxnote:
    -- The init function is to make sure that all the mem variables are defined and properly preset.
    -- we don't do variable or object bootstrapping in this place, 
    --   Everything is assumed to be defined because you add all initial variables and objects here.
    --   We don't want to waste processor time checking if references exist or not
    mem.log = {}
    log("initialized")
    --mxnote convention: add standard vars here in the mem.ui.vars.[varname] convention for easy searching through code
    mem.ui = {}
        mem.ui.screen1 = {}
        mem.ui.screen1.channel = "touch"
        mem.ui.screen1.active_page = 1
        mem.ui.screen1.pages = {"Navigation", "Bookmarks","Notepad","Settings"} --mxedit
    mem.ui.vars = {} -- mxnote the (temporary)place for variables that need to be remembered between actions,pages. Stuff only gets realy used when the user presses a button(in most cases)
        mem.ui.vars.radius = 1 -- hardcode radius
        mem.ui.vars.step = 11
        mem.ui.vars.comment = ""
        mem.ui.vars.jdmessages = {}
        mem.ui.destination=0 
        mem.ui.vars.bookmarkstext="bookmark description,0,0,0"
        mem.ui.vars.notepadtext="Notes for ship go here"
    mem.system = {}
        mem.system.user = ""
        mem.system.admin = {"MCLV"} --help: change this to your username
        mem.system.staff = {} --help: change these to the names of your friends that you'd also like to be able to access the system. Or you can just use the settings tab in the running system
        mem.system.bookmarks = {}
    mem.jdlog = {lst = "", buffer = {}}
    mem.jd = {}
        mem.jd.delay=0.3 
        mem.jd.channel = "jumpdrive" -- help: enter fleet controller or jumpdrive digiline channel
        mem.jd.msg = ""
        mem.jd.command = "" -- next command we'd like to send to the jd by interrupt -- sometimes we need to wait before we can send (digilines)
        mem.jd.target = ""
        mem.jd.position = ""
end
function UI_ShowScreen(msg)
    -- ui images from unified inventory  ./unified_inventory/textures/ui_on_icon.png
    local screen
    local _swidth, _sheight = 10, 8 --screen width and height
    local _bh = 0.8 -- _bh = button heightx``
    local _bh2 = _bh/2 -- _bh = button heightx``
    local _C12 = _swidth / 12 -- 12 column grid width
    local _C6 = _swidth / 6 -- 6 column grid width
    local _R12 = _sheight / 12
    local role = acl_role(mem.system.user)
    local clickerRole = "user"
    -- ui messages interpretation
    if msg == nil then 
        msg = {tabheader = "1"}
    end
    if msg.clicker ~= nil then
        clickerRole=acl_role(msg.clicker)
        if clickerRole == "staff" or clickerRole == "admin" then 
            mem.system.user = msg.clicker
        end
        
        if msg.login ~= nil then
            msg.tabheader=1
            mem.ui.screen1.active_page=1
        end
    end
    -- security protected UI changes
    -- if clicker is not authorised, he can watch, but no touch(change values)
    if tve({"admin","staff"},clickerRole) then
        if msg.tabheader ~= nil then
            mem.ui.screen1.active_page = tonumber(msg.tabheader)
        end
        if msg.target and false then
            mem.jd.target = msg.target
        end
        if msg.radius then 
            mem.ui.vars.radius = tonumber(msg.radius)
            mem.jd.radius = mem.ui.vars.radius
            jdset({r = mem.jd.radius})
        end
        if msg.comment then
            mem.ui.vars.comment = msg.comment
        end
        if msg.valuesset and msg.target then
            mem.jd.target = msg.target
            jdset(ctt(mem.jd.target))
            dls(mem.jd.channel, {command = "get"})
        end

        if msg.jump then
            if msg.comment and msg.comment ~= "" then
                mem.ui.vars.comment = msg.comment
                UI_jdlog("-- " .. msg.comment .. " --")
            end
            mem.jd.target = msg.target
            jdset(ctt(mem.jd.target))
            mem.jd.command = "jump"
            interrupt(mem.jd.delay)
        end
        if msg.simulate then
            if msg.comment and msg.comment ~= "" then
                UI_jdlog("-- " .. msg.comment .. " --")
            end
            UI_jdlog("-simulation-")

            mem.jd.target = msg.target
            jdset(ctt(mem.jd.target))
            mem.jd.command = "simulate"
            interrupt(mem.jd.delay)
        end
        if msg.step then
            mem.ui.vars.step = msg.step
        end
        if msg.frompos then
            mem.jd.target = mem.jd.position
        end
        if msg.set then
            msg.jd.target = msg.target
        end

        -- plus minus buttons --
        if msg.xplus then
            local v = ctt(mem.jd.target)
            v.x = v.x + mem.ui.vars.step
            mem.jd.target = cts(v)
        end
        if msg.xminus then
            local v = ctt(mem.jd.target)
            v.x = v.x - mem.ui.vars.step
            mem.jd.target = cts(v)
        end
        if msg.yplus then
            local v = ctt(mem.jd.target)
            v.y = v.y + mem.ui.vars.step
            mem.jd.target = cts(v)
        end
        if msg.yminus then
            local v = ctt(mem.jd.target)
            v.y = v.y - mem.ui.vars.step
            mem.jd.target = cts(v)
        end
        if msg.zplus then
            local v = ctt(mem.jd.target)
            v.z = v.z + mem.ui.vars.step
            mem.jd.target = cts(v)
        end
        if msg.zminus then
            local v = ctt(mem.jd.target)
            v.z = v.z - mem.ui.vars.step
            mem.jd.target = cts(v)
        end
        -- /plus minus buttons --
        if msg.notepadtext then
            mem.ui.vars.notepadtext=msg.notepadtext
        end
        if msg.clearjdlog then
            mem.ui.vars.jdmessages = {}
        end
        if msg.bookmarkstext ~= nil then
            mem.ui.vars.bookmarkstext=msg.bookmarkstext
        end
        if msg.bmSave then
            mem.system.bookmarks = bookmarkImport(mem.ui.vars.bookmarkstext)
        end
        if msg.bmLoad then
            mem.ui.vars.bookmarkstext = table.concat(bookmarkExport(mem.system.bookmarks), "\n")
        end
        if msg.bmAdd then
            mem.system.bookmarks = merge(mem.system.bookmarks,bookmarkImport(mem.ui.vars.bookmarkstext))
        end
        if msg.bmToNav and msg.bookmark then
            mem.jd.target = mem.system.bookmarks[msg.bookmark]
            mem.ui.screen1.active_page=1
        end
        if msg.bmJump and msg.bookmark then
            mem.jd.target = mem.system.bookmarks[msg.bookmark]
            jdset(ctt(mem.jd.target))
            mem.jd.command = "jump"
            interrupt(mem.jd.delay)
        end
        if msg.jddelay then
            mem.jd.delay = tonumber(msg.jddelay) 
        end
    end
    if clickerRole == "admin" then
        if msg.Sstaff then
            mem.system.staff = split(msg.Sstaff,",")
        end
        if msg.Sadmin then
            mem.system.admin = split(msg.Sadmin,",")
        end
    end
    -- ui layout
    if tve({"admin","staff"},role) then
        screen = {
            {command = "clear"},
            {command = "set", width = _swidth, height = _sheight, no_prepend = true, real_coordinates = true},
            {command = "add", element = "bgcolor", bgcolor = "#202040FF", fullscreen = "false", fbgcolor = "#10101040"},
            {
                command = "add",
                element = "animated_image",
                name = "backgroundimage1",
                texture_name = "default_river_water_flowing_animated.png",
                frame_count = 16,
                frame_duration = 200,
                frame_start = 1,
                X = 0,
                Y = 0,
                H = _R12 * 12,
                W = _swidth
            },
            {
                command = "add",
                element = "tabheader",
                X = 0,
                Y = 0,
                name = "tabheader",
                captions = mem.ui.screen1.pages,
                current_tab = tonumber(mem.ui.screen1.active_page),
                transparent = false,
                draw_border = true
            }
        }
        -- ui screens layout
        local page = mem.ui.screen1.active_page
        local pageName= mem.ui.screen1.pages[page] --mxedit "", "","Notepad","Settings"
        if pageName == "Navigation" then
            local target = ""
            if mem.jd.target == "" then
                if mem.jd.position == "" then
                    target = ""
                else
                    target = mem.jd.position
                end
            else
                target = mem.jd.target
            end
            table_insert(
                screen,
                {
                    command = "add",
                    element = "button",
                    X = _C12 * 0,
                    Y = 0,
                    W = _C12 * 2,
                    H = _R12,
                    name = "frompos",
                    label = "Pos->"
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "field",
                    Y = 0,
                    X = _C12 * 3,
                    W = _C12 * 5,
                    H = _R12,
                    name = "target",
                    label = "",
                    default = target
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "label",
                    label="R:",
                    Y = 0+.3,
                    X = (_C12 * 8) +.3,
                    W = _C12 * 1,
                    H = _R12,
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "field",
                    Y = 0,
                    X = _C12 * 9,
                    W = _C12 * 1,
                    H = _R12,
                    name = "radius",
                    label = "",
                    default = tostring(mem.ui.vars.radius)
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "button",
                    X = _C12 * 10,
                    Y = 0,
                    W = _C12 * 2,
                    H = _R12,
                    name = "valuesset",
                    label = "-> JD"
                }
            )

            table_insert(
                screen,
                {
                    command = "add",
                    element = "button_exit",
                    name = "jump",
                    label = "Jump",
                    Y = _R12 * 1,
                    X = _C12,
                    W = _swidth - (_C12 * 2),
                    H = _R12
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "button",
                    name = "simulate",
                    label = "Simulate",
                    Y = _R12 * 2,
                    X = _C12,
                    W = _swidth - (_C12 * 2),
                    H = _R12
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "field",
                    X = _C12 * 5,
                    Y = _R12 * 4,
                    W = _C12 * 2,
                    H = _R12,
                    name = "step",
                    label = "step",
                    default = tostring(mem.ui.vars.step) or "mem.ui.vars.step not found"
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "button",
                    X = _C12 * 9,
                    Y = _R12 * 3,
                    W = _C12 * 2,
                    H = _R12,
                    name = "xplus",
                    label = "+X+"
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "button",
                    X = _C12,
                    Y = _R12 * 3,
                    W = _C12 * 2,
                    H = _R12,
                    name = "xminus",
                    label = "-X-"
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "button",
                    X = _C12 * 9,
                    Y = _R12 * 4,
                    W = _C12 * 2,
                    H = _R12,
                    name = "yplus",
                    label = "+Y+"
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "button",
                    X = _C12,
                    Y = _R12 * 4,
                    W = _C12 * 2,
                    H = _R12,
                    name = "yminus",
                    label = "-Y-"
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "button",
                    X = _C12,
                    Y = _R12 * 5,
                    W = _C12 * 2,
                    H = _R12,
                    name = "zminus",
                    label = "-Z-"
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "textarea",
                    X = _C12 * 1,
                    Y = _R12 * 7,
                    W = _C12 * 10,
                    H = _R12 * 4,
                    name = "jdmessages",
                    label = "Jumpdrive report",
                    default = table.concat(reverseTable(mem.ui.vars.jdmessages), "\n")
                }
            )
            table_insert(--mxnote in the layout, this element's label interferes with the button +Z+ button if it's "over" the button (although not visible), thats why its here
                screen,
                {
                    command = "add",
                    element = "field",
                    Y = _R12 * 6,
                    X = _C12 * 5,
                    W = _C12 * 6,
                    H = _R12,
                    name = "comment",
                    label = "Comment",
                    default = mem.ui.vars.comment
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "button",
                    X = _C12 * 9,
                    Y = _R12 * 5,
                    W = _C12 * 2,
                    H = _R12,
                    name = "zplus",
                    label = "+Z+"
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "button",
                    Y = _R12 * 11,
                    X = _C12 * 8,
                    W = _C12 * 3,
                    H = _R12,
                    name = "clearjdlog",
                    label = "Clear log"
                }
            )
        end
        if pageName == "Example" then
            table_insert(
                screen,
                {
                    command = "add",
                    element = "button_exit",
                    name = "reset",
                    label = "screen 2",
                    Y = 0,
                    X = 0,
                    W = _swidth
                }
            )
        end
        if pageName == "Bookmarks" then
            options = table_keys(mem.system.bookmarks)
            table.sort(options)
            selected_index = indexOf(options, mem.ui.destination) 
            table_insert(
                screen,
                {
                    command = "add",
                    element = "textarea",
                    name = "bookmarkstext",
                    label = "Bookmark text:",
                    default = mem.ui.vars.bookmarkstext,
                    X = _C12,
                    Y = _R12 * 2,
                    W = _C12 * 10,
                    H = _C12 * 7 
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "dropdown",
                    label = "Bookmarks",
                    X = _C12,
                    Y = 0,
                    W = _C12 * 7,
                    H = _R12,
                    name = "bookmark",
                    choices = options,
                    selected_id = selected_index,
                    index_event = false
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "button",
                    X = _C12 * 8,
                    Y = 0,
                    W = _C12 * 3,
                    H = _R12,
                    name = "bmToNav",
                    label = "->Nav"
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "button_exit",
                    X = _C12 * 8,
                    Y = _R12,
                    W = _C12 * 3,
                    H = _R12,
                    name = "bmJump",
                    label = "Jump"
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "button",
                    X = _C12 * 0,
                    Y = _R12 * 11,
                    W = _C12 * 2,
                    H = _R12,
                    name = "bmSave",
                    label = "Save"
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "button",
                    X = _C12 * 2,
                    Y = _R12 * 11,
                    W = _C12 * 2,
                    H = _R12,
                    name = "bmLoad",
                    label = "Load"
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "button",
                    X = _C12 * 4,
                    Y = _R12 * 11,
                    W = _C12 * 2,
                    H = _R12,
                    name = "bmAdd",
                    label = "Add"
                }
            )
        end
        if pageName == "Notepad" then
            --notepad 
            table_insert(
                screen,
                {
                    command = "add",
                    element = "textarea",
                    X = _C12 * 0,
                    Y = _R12 * 0,
                    W = _C12 * 12,
                    H = _R12 * 12,
                    name = "notepadtext",
                    label = "",
                    default = mem.ui.vars.notepadtext
                }
            )
        end
        if pageName == "Settings" and role =="admin" then
            table_insert(
                screen,
                {
                    command = "add",
                    element = "field",
                    Y = (_bh2 *2) +(_R12 * 1),
                    X = _C12 * 1,
                    W = _C12 * 10,
                    H = _R12,
                    name = "Sstaff",
                    label = "system.staff",
                    default = join(mem.system.staff,",")
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "field",
                    Y = _bh2+(_R12 * 0),
                    X = _C12 * 1,
                    W = _C12 * 10,
                    H = _R12,
                    name = "Sadmin",
                    label = "system.admin",
                    default = join(mem.system.admin,",")
                }
            )
            table_insert(
                screen,
                {
                    command = "add",
                    element = "field",
                    Y = (_bh2 *3) +(_R12 * 2),
                    X = _C12 * 1,
                    W = _C12 * 10,
                    H = _R12,
                    name = "jddelay",
                    label = "jumpdrive delay time",
                    default = tostring(mem.jd.delay) 
                }
            )
        end
        if pageName == "Settings" and role =="staff" then
            table_insert(
                screen,
                {
                    command = "add",
                    element = "field",
                    Y = _bh2+(_R12 * 0),
                    X = _C12 * 1,
                    W = _C12 * 10,
                    H = _R12,
                    name = "jddelay",
                    label = "jumpdrive delay time",
                    default = tostring(mem.jd.delay) 
                }
            )
            
        end
        digiline_send(mem.ui.screen1.channel, screen)
    else
        _swidht, _sheight = 1, 1
        digiline_send(
            mem.ui.screen1.channel,
            {
                {command = "clear"},
                {command = "set", width = _swidth, height = _sheight, no_prepend = true, real_coordinates = true},
                {
                    command = "add",
                    element = "bgcolor",
                    bgcolor = "#202040FF",
                    fullscreen = "false",
                    fbgcolor = "#10101040"
                },
                {
                    command = "add",
                    element = "button_exit",
                    name = "login",
                    label = "- request access -",
                    Y = 0,
                    X = 0,
                    W = _swidth,
                    H = _sheight
                }
            }
        )
    end
end
function UI_jdlog(msg)
    table_insert(mem.ui.vars.jdmessages, msg)
    --UI_ShowScreen()
end

if event then
    if event.type == "digiline" then
        if event.channel then
            if event.channel == mem.ui.screen1.channel then
                --UI_ShowScreen(event.msg)
                --[[ uidebug
                log("ui message recieved. " .. event.msg.clicker or 'unknown')
                log(event) -- log all messages for debugging purposes only
                /uidebug]]--
            elseif event.channel == mem.jd.channel then
                table_insert(mem.jdlog.buffer, event)

                if event.msg ~= nil then
                    if event.msg.target ~= nil then
                        mem.jd.target = cts(event.msg.target)
                        mem.jd.position = cts(event.msg.position)
                        mem.jd.radius = event.msg.radius
                    end
                    if event.msg.msg ~= nil then
                        mem.jd.msg = event.msg.msg
                        UI_jdlog(mem.jd.target .. " : " .. event.msg.msg)
                    end
                    if event.msg.success == true and event.msg.time == nil and
                            mem.jd.command == "simulated jump"
                     then
                        UI_jdlog("Simulation success!")
                    end
                    if event.msg.success == true and event.msg.time ~= nil then
                        mem.jd.msg = "successful jump"
                        mem.jd.position = mem.jd.target
                        UI_jdlog("jump: " .. mem.jd.target)
                    end
                    if event.msg.distance  then -- mxnote:  if we get distance from the jumpdrive, it is safe to assume that power_req and distance are also there, if not, this should fail because the software should be updated due to a change in the jumpdrive mod
                        local tolog={"JDGet: ".. mem.ui.vars.comment }
                        
                        if event.msg.max_power_req  then
                            table_insert(tolog,"\tmax power_req: " .. numberUnits(event.msg.max_power_req,"EU"))
                            table_insert(tolog,"\ttotal power_req: " .. numberUnits(event.msg.total_power_req,"EU"))
                        else
                            table_insert(tolog,"\tpowerstorage: " .. numberUnits(event.msg.powerstorage,"EU"))
                            table_insert(tolog,"\tpower_req: " .. numberUnits(event.msg.power_req,"EU"))
                        end
                        table_insert(tolog,"\tdistance: " .. numberUnits(event.msg.distance,"m"))
                        if event.msg.engines then
                            for i, v in ipairs(event.msg.engines) do
                                table_insert(tolog,"\t\t E"..i.." powerstorage: ".. numberUnits(v.powerstorage,"EU"))
                            end
                        end
                        UI_jdlog(table.concat(tolog,"\n"))
                        log({DEBUG="distance detected"})
                    end
                end

                
                
            else
                log(event)
            end
        end
        UI_ShowScreen(event.msg)
    end
    if event.type == "interrupt" then
        if mem.jd.command == "jump" then
            mem.jd.command = "attempted:jump"
            dls(mem.jd.channel, {command = "jump"})
        elseif mem.jd.command == "simulate" then
            mem.jd.command = "simulated jump"
            dls(mem.jd.channel, {command = "simulate"})
            UI_ShowScreen()
        end
    end
    if event.type == "program" then
        if next(mem) == nil then
            init()
            dls(mem.jd.channel, {command = "get"})
        end
        -- some debug stuff here
        mem.log={}
        --log({DEBUG="running cvs_string_to_table_v2 on bookmarkstext",result=csv_string_to_table_v2(mem.ui.vars.bookmarkstext)})
        --log({DEBUG="running csvtotable on bookmarkstext",result=csvtotable(mem.ui.vars.bookmarkstext)})
        --log({DEBUG=indexOf(table_keys({one="one",two=2}),'one')})
        mem.jdlog = {lst = "", buffer = {}}
        dls(mem.jd.channel, {command = "get"})
        --[[]
            log({
                TEST="1buttonworks"
            })
        ]]--
        --
        UI_ShowScreen()
    --dls(mem.jd.channel,{command="get"})
    end
end
-- The MIT-Zero License
-- 
-- Copyright (c) 2023 github.com/MCLV-pandorabox
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
