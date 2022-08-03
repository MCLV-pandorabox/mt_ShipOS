-- Bookmark JumpDrive
-- copy from Simplified FeXoR JD code
-- working title
-- tags:
--   mxnote comment by MCLV
--   mxedit bookmark by MCLV
-- Status: testing bookmarks limits . jumpdrive page seems to fail sometimes, find out why . current bookmark limit = 24 . fails to save after that
-- Basic Pandorabox tools

-- NOTE Hardcoded module names. I have no clue why this would make anything better.
local math, os, string, table = math, os, string, table

-- ########
-- Settings
-- ########

local help = false

local permission = {authorised_users = {"MCLV", "1155"}}
if mem.permission == nil then
    mem.permission = {ignore = false}
end
permission.check = function(user)
    if mem.permission.ignore == true then
        return true
    end
    local is_allowed = false
    for i, u in ipairs(permission.authorised_users) do
        if user == u then
            is_allowed = true
            break
        end
    end
    return is_allowed
end

local event_catcher = {touchscreen = {channel = "ts_ec", max_lines = 30}, monitor = {channel = "mon_ec"}}
if mem.events == nil then
    mem.events = {count = 0}
end

local jumpdrive = {channel = "jumpdrive",instajump = false}
if mem.linebuffer == nil then
    mem.linebuffer = {}
    if mem.linebuffer.jumpdrive == nil then
        mem.linebuffer.jumpdrive = {"Here the Jumpdrive's responses will be shown."}
    end
end

local touchscreen = {
    channel = "ts",
    uiDebug = false,
    pages = {"Events", "Jumpdrive","Bookmarks"},
    permissions = {"Open", "Users", "Locked"},
    linebuffer = {jumpdrive = {memory = mem.linebuffer.jumpdrive, max_lines = 50}}
}
if mem.page == nil then
    mem.page = 1
end
if mem.ts_lock == nil then
    mem.ts_lock = 2
end

if mem.instant_jump == nil then
    mem.instant_jump = {distance = 50}
end

-- ########
-- Helper functions
-- ########
function bookmarkXport()
    s={};
    for k,v in pairs(mem.l) do
        --table.insert(s, k .. "," .. v[1] .. "," .. v[2] .. "," .. v[3])
        table.insert(s, tostring(k) .. "," .. tostring(v))
    end
    table.sort(s)
    return s
end
function importBookmarks(CSVBM) -- mxnote CSVBM= CSV bookmark text . format: name,x,y,z \n . name can not have special chars or spaces because it is used as a key in a hash table
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
    local fieldsep = string.byte(",")
    local linesep = string.byte("\n")
    local field = {}
    local line = {"two"}
    local acc = "" -- string accumulator
    local nByte=0;
    for nChar = 1, #sInput do
        nByte = sInput:byte(nChar)
        if nByte == fieldsep then
            table.insert(field, acc)
            acc = ""
        elseif nByte == linesep then
            table.insert(field, acc)
            table.insert(line, field)
            field = {}
            acc = ""
        elseif nChar == #sInput then
            acc = acc .. string.char(nByte)
            table.insert(field,acc)
            table.insert(line,field)
            --we finished, but code may continue. no probl, xcept for eficiency
        else
            acc = acc .. string.char(nByte)
        end
    end
    return line
end

function array_keys(tbl)
    ks = {}
    local n = 0
    -- local tbl=table.sort(tbl)
    for i, v in pairs(tbl) do
        n = n + 1
        table.insert(ks, i)
        --ks[n]=tostring(i)
    end
    return ks
end
function indexOf(array, value) --mxnote find index of the value in array(table) : Handy for dropdown boxes
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return nil
end
local character = {}
character.is_numeric = function(sChar)
    if sChar:byte() >= 48 and sChar:byte() <= 57 then
        return true
    else
        return false
    end
end

local coordinates = {names = {"x", "y", "z"}}

function coordinates:to_table(sInput)
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
                    table.insert(tNumberList, string.char(nByte))
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
    for i, name in ipairs(self.names) do
        tOutput[name] = tonumber(tNumberList[i] or "0")
    end
    return tOutput
end

function coordinates:to_string(coordinate_table)
    return coordinate_table.x .. "," .. coordinate_table.y .. "," .. coordinate_table.z
end

local function get_string(data, maxdepth)
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

local function get_time_string(datetable)
    local date_table = datetable or os.datetable()
    local date_string = date_table.year .. "." .. date_table.month .. "." .. date_table.day
    local time_string = date_table.hour .. ":" .. date_table.min .. ":" .. date_table.sec
    return date_string .. " " .. time_string
end

local function merge_shallow_tables(t1, t2)
    local t3 = {}
    for k, v in pairs(t1) do
        t3[k] = v
    end
    for k, v in pairs(t2) do
        t3[k] = v
    end
    return t3
end

local function add_line_to_buffer(linebuffer, message)
    -- expects linebuffer to be an array with keys memory (link to line table in mem) and max_lines (integer)
    if type(message) ~= "string" then
        message = get_string(message)
    end
    table.insert(linebuffer.memory, 1, message)
    while table.maxn(linebuffer.memory) > linebuffer.max_lines do
        table.remove(linebuffer.memory)
    end
end

local function touchscreen_add_line(msg)
    table.insert(mem.event_catcher.touchscreen_line_table, 1, tostring(mem.events.count) .. ": " .. tostring(msg))
    while table.maxn(mem.event_catcher.touchscreen_line_table) > event_catcher.touchscreen.max_lines do
        table.remove(mem.event_catcher.touchscreen_line_table)
    end
end

local function send_to_monitors(message)
    -- Omitt appending it's own and other "display" type content to avoid doubling the output
    if message ~= nil and message.msg ~= nil  and message.channel == "ts" and touchscreen.uiDebug == false then
        -- touchscreen_add_line('ts line detected. uiDebug = False')
        return -- mxnote don't log touch screen unless uiDebug flag is true
    end
    
    if message ~= nil and message.msg ~= nil and message.msg.display ~= nil then
        message.msg.display = "<cut>"
    end
    if message.channel then
        digiline_send(event_catcher.monitor.channel, message.channel)
    elseif message.type then
        digiline_send(event_catcher.monitor.channel, message.type)
    else
        digiline_send(event_catcher.monitor.channel, get_string(message, 1))
    end
    if message ~= nil and message.type == "interrupt" then
        message.time = get_time_string()
    end
    touchscreen_add_line(get_string(message,6))
    digiline_send(
        event_catcher.touchscreen.channel,
        {
            {command = "clear"},
            {
                command = "add",
                element = "textarea",
                name = "display",
                label = "Events:",
                default = table.concat(mem.event_catcher.touchscreen_line_table, "\n"),
                X = 0.2,
                Y = 0.1,
                W = 10.2,
                H = 9.5
            }
        }
    )
end

-- ########
-- Touchscreen
-- ########
local function update_page(page)
    if touchscreen.pages[mem.page] == page then
        local message = {
            {command = "clear"},
            -- BUG background9 needs to be before bgcolor
            -- {command = "add", element = "background9", X = 0, Y = 0, W = 0, H = 0, image = "ui_formbg_9_sliced.png", auto_clip = true, middle = 16},
            -- BUG focus doesn't seem to work at all: focus = "target"
            {command = "set", width = 13, height = 10, no_prepend = true, real_coordinates = true},
            {command = "add", element = "bgcolor", bgcolor = "#202040FF", fullscreen = "false", fbgcolor = "#10101040"},
            {command = "add", element = "label", label = "Page:", X = 0.2, Y = 0.3},
            {
                command = "add",
                element = "textlist",
                name = "page",
                listelements = touchscreen.pages,
                selected_id = mem.page,
                X = 0.1,
                Y = 0.5,
                W = 1.5,
                H = 7.7
            },
            {command = "add", element = "label", label = "Lock:", X = 0.2, Y = 8.5},
            {
                command = "add",
                element = "textlist",
                name = "lock",
                listelements = touchscreen.permissions,
                selected_id = mem.ts_lock,
                X = 0.1,
                Y = 8.7,
                W = 1.5,
                H = 1.2
            }
        }
        if page == "Events" then
            table.insert(
                message,
                {
                    command = "add",
                    element = "textarea",
                    name = "display",
                    label = "Events:",
                    default = table.concat(mem.event_catcher.touchscreen_line_table, "\n"),
                    X = 1.5,
                    Y = 0.55,
                    W = 11.25,
                    H = 9.3
                }
            )
        elseif page == "Bookmarks" then
            --mxedit
            local bookmarkstxt=bookmarkXport()
            table.insert(
                message,
                {
                    command = "add",
                    element = "textarea",
                    name = "bookmarktxt",
                    label = "Bookmark export:",
                    default = table.concat(bookmarkstxt, "\n"),
                    X = 1.6,
                    Y = 1.5,
                    W = 11.5,
                    H = 8.75
                }
            )
            table.insert(
                message,
                {
                    command = "add",
                    element = "button",
                    name = "save",
                    label = "Save",
                    X = 1.6,
                    Y = 0,
                    W = 1,
                    H = 0.8
                }
            )


        elseif page == "Jumpdrive" then
            table.insert(
                message,
                {
                    command = "add",
                    element = "button",
                    name = "request_data",
                    label = "Refresh",
                    X = 1.7,
                    Y = 0.25,
                    W = 1.2,
                    H = 0.5
                }
            )
            table.insert(
                message,
                {
                    command = "add",
                    element = "label",
                    X = 3.1,
                    Y = 0.5,
                    label = "Distance: " ..
                        tostring(math.ceil(mem.jumpdrive.distance)) ..
                            "  |  " ..
                                "EU needed: " ..
                                    tostring(math.ceil(mem.jumpdrive.power_req)) ..
                                        " stored: " .. tostring(math.ceil(mem.jumpdrive.powerstorage))
                }
            )

            -- BUG The "H" parameter only shifts a field instead of resizing it. Best leave it out (same as H=0.8
            -- BUG The "set" focus propperty doesn't seem to work. The first input field added get's the focus
            table.insert(
                message,
                {
                    command = "add",
                    element = "field",
                    name = "target",
                    label = "Target (Current: " .. coordinates:to_string(mem.jumpdrive.position) .. ")",
                    default = coordinates:to_string(mem.jumpdrive.target),
                    X = 3.8,
                    Y = 1.8,
                    W = 4.5
                }
            )

            -- Needs to be behind (in GUI so in front in code) radius selection or that will be blocked by it's invisible label
            table.insert(
                message,
                {
                    command = "add",
                    element = "textarea",
                    name = "display",
                    label = "The Jumpdrive says:",
                    default = table.concat(mem.linebuffer.jumpdrive, "\n"),
                    X = 1.6,
                    Y = 3.8,
                    W = 10.7,
                    H = 6
                }
            )

            table.insert(message, {command = "add", element = "label", label = "Radius", X = 12, Y = 3.7})
            table.insert(
                message,
                {
                    command = "add",
                    element = "textlist",
                    name = "radius",
                    listelements = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15"},
                    selected_id = tonumber(mem.jumpdrive.radius),
                    X = 12.4,
                    Y = 3.85,
                    W = 1,
                    H = 6
                }
            )

            -- BUG The "H" parameter only shifts a field instead of resizing it. Best leave it out (same as H=0.8
            table.insert(
                message,
                {
                    command = "add",
                    element = "field",
                    name = "jump_step_value",
                    label = "Distance",
                    default = tostring(mem.instant_jump.distance),
                    X = 1.7,
                    Y = 1.8,
                    W = 1.1
                }
            )
            table.insert(
                message,
                {
                    command = "add",
                    element = "button",
                    name = "jump_step_increase",
                    label = "+",
                    X = 1.7,
                    Y = 1,
                    W = 1.1,
                    H = 0.5
                }
            )
            table.insert(
                message,
                {
                    command = "add",
                    element = "button",
                    name = "jump_step_decrease",
                    label = "-",
                    X = 1.7,
                    Y = 2.6,
                    W = 1.1,
                    H = 0.5
                }
            )
            --
            local incbutton="button_exit"
            if jumpdrive.instajump == false then
                incbutton="button"
            end
            
            table.insert(
                message,
                {
                    command = "add",
                    element = incbutton,
                    name = "xi",
                    label = (help and "@ E") or "E",
                    X = 3.8,
                    Y = 1,
                    W = 1.5,
                    H = 0.5
                }
            )
            table.insert(
                message,
                {
                    command = "add",
                    element = incbutton,
                    name = "xd",
                    label = (help and "@ W") or "W",
                    X = 3.8,
                    Y = 2.6,
                    W = 1.5,
                    H = 0.5
                }
            )
            table.insert(
                message,
                {
                    command = "add",
                    element = incbutton,
                    name = "yi",
                    label = (help and "@ ^") or "^",
                    X = 5.3,
                    Y = 1,
                    W = 1.5,
                    H = 0.5
                }
            )
            table.insert(
                message,
                {
                    command = "add",
                    element = incbutton,
                    name = "yd",
                    label = (help and "@ v") or "v",
                    X = 5.3,
                    Y = 2.6,
                    W = 1.5,
                    H = 0.5
                }
            )
            table.insert(
                message,
                {
                    command = "add",
                    element = incbutton,
                    name = "zi",
                    label = (help and "@ N") or "N",
                    X = 6.8,
                    Y = 1,
                    W = 1.5,
                    H = 0.5
                }
            )
            table.insert(
                message,
                {
                    command = "add",
                    element = incbutton,
                    name = "zd",
                    label = (help and "@ S") or "S",
                    X = 6.8,
                    Y = 2.6,
                    W = 1.5,
                    H = 0.5
                }
            )
            if help then
                table.insert(message, {command = "add", element = "label", label = "<  I. J.  >", X = 2.8, Y = 1.25})
                table.insert(message, {command = "add", element = "label", label = "<  I. J.  >", X = 2.8, Y = 2.85})
                table.insert(
                    message,
                    {command = "add", element = "label", label = '< "@" means "Attempt Jump" v', X = 8.3, Y = 1.25}
                )
                table.insert(
                    message,
                    {
                        command = "add",
                        element = "label",
                        label = "< Instant Jump components ( I. J. )",
                        X = 8.3,
                        Y = 2.85
                    }
                )
            end

            table.insert(
                message,
                {
                    command = "add",
                    element = "button",
                    name = "reset_target",
                    label = "Reset",
                    X = 2.8,
                    Y = 1.8,
                    W = 1,
                    H = 0.8
                }
            )
            table.insert(
                message,
                {
                    command = "add",
                    element = "button",
                    name = "set_target",
                    label = "Set",
                    X = 8.3,
                    Y = 1.8,
                    W = 1,
                    H = 0.8
                }
            )
            table.insert(
                message,
                {
                    command = "add",
                    element = "button",
                    name = "simulate",
                    label = "Test",
                    X = 9.4,
                    Y = 1.8,
                    W = 1,
                    H = 0.8
                }
            )
            table.insert(
                message,
                {
                    command = "add",
                    element = "button_exit",
                    name = "jump",
                    label = (help and "Jump @") or "Jump",
                    X = 10.5,
                    Y = 1.8,
                    W = 1.5,
                    H = 0.8
                }
            )
            
            selected = mem.jumpdrive.instajump
            table.insert(
                message,
                {
                    command = "add",
                    element = "checkbox",
                    name = "instajump",
                    label = "Instant Jump",
                    X = 8.3,
                    Y = 2.9,
                    W = 1,
                    H = 0.8,
                    selected = selected
                }
            )
            if mem.l == nil then
                mem.l = {
                    NotFound = "0,0,0"
                }
            end

            options = array_keys(mem.l)
            table.sort(options)
            -- options = {"one","dos","tres"}
            selected_index = indexOf(options, mem.destination)

            table.insert(
                message,
                {
                    command = "add",
                    element = "dropdown",
                    label = "Bookmarks",
                    X = 8.3,
                    Y = 1,
                    W = 4.0,
                    H = 0.5,
                    name = "bookmark",
                    choices = options,
                    selected_id = selected_index,
                    index_event = false
                }
            )
        else
            table.insert(
                message,
                {
                    command = "add",
                    element = "label",
                    label = "This page is not yet handled: " .. tostring(touchscreen.pages[mem.page]),
                    X = 4,
                    Y = 4
                }
            )
        end

        digiline_send(touchscreen.channel, message)
    end
end

-- Handle touchscreen messages
if event.type == "digiline" and event.channel == touchscreen.channel and event.msg then
    if event.msg.page ~= nil then
        local i_page = tonumber(string.sub(event.msg.page, 5))
        if i_page ~= mem.page then
            mem.page = i_page
            update_page(touchscreen.pages[mem.page])
        end
    elseif event.msg.lock ~= nil then
        local i_lock = tonumber(string.sub(event.msg.lock, 5))
        if permission.check(event.msg.clicker) then
            if i_lock ~= mem.ts_lock then
                mem.ts_lock = i_lock
                if mem.ts_lock == 1 then
                    digiline_send(touchscreen.channel, {command = "unlock"})
                    mem.permission.ignore = true
                elseif mem.ts_lock == 2 then
                    digiline_send(touchscreen.channel, {command = "unlock"})
                    mem.permission.ignore = false
                elseif mem.ts_lock == 3 then
                    digiline_send(touchscreen.channel, {command = "lock"})
                    mem.permission.ignore = false
                else
                    send_to_monitors("Unhandled ts_lock value: " .. tostring(mem.ts_lock))
                end
                update_page(touchscreen.pages[mem.page])
            end
        else
            send_to_monitors("You can't unlock, " .. tostring(event.msg.clicker) .. " ;)")
        end
    elseif touchscreen.pages[mem.page] == "Jumpdrive" then
        local authorised = permission.check(event.msg.clicker)
        local jumpdrive_page_needs_update = false
        local min_jump_step_value = 2 * mem.jumpdrive.radius + 1

        if event.msg.jump_step_value ~= nil then
            if tonumber(event.msg.jump_step_value) < min_jump_step_value then
                mem.instant_jump.distance = min_jump_step_value
            else
                mem.instant_jump.distance = tonumber(event.msg.jump_step_value)
            end
            if tonumber(event.msg.jump_step_value) ~= mem.instant_jump.distance then
                jumpdrive_page_needs_update = true
            end
        end
--mxnote bookmarks
        if event.msg.bookmark ~= nil and mem.destination~=event.msg.bookmark then
            mem.destination = event.msg.bookmark 
            mem.jumpdrive.target = coordinates:to_table(mem.l[event.msg.bookmark])
            update_page("Jumpdrive")
            --jumpdrive_page_needs_update = true
        end
        if event.msg.radius ~= nil then
            if authorised then
                mem.jumpdrive.radius = tonumber(string.sub(event.msg.radius, 5))
                if event.msg.target ~= nil then
                    mem.jumpdrive.target = coordinates:to_table(event.msg.target)
                    digiline_send(
                        jumpdrive.channel,
                        merge_shallow_tables(
                            {command = "set", r = mem.jumpdrive.radius, formupdate = false},
                            mem.jumpdrive.target
                        )
                    )
                else
                    digiline_send(jumpdrive.channel, {command = "set", r = mem.jumpdrive.radius, formupdate = false})
                end
                digiline_send(jumpdrive.channel, {command = "get"})
            else
                send_to_monitors("You can't change the radius, " .. tostring(event.msg.clicker) .. " ;)")
            end
        elseif event.msg.key_enter_field ~= nil then
            if event.msg.key_enter_field == "target" then
                mem.jumpdrive.target = coordinates:to_table(event.msg.target)
                digiline_send(
                    jumpdrive.channel,
                    merge_shallow_tables({command = "set", formupdate = false}, mem.jumpdrive.target)
                )
                digiline_send(jumpdrive.channel, {command = "get"})
            elseif event.msg.key_enter_field == "jump_step_value" then
                jumpdrive_page_needs_update = true
            else
                send_to_monitors("Unknown key_enter_field: " .. tostring(event.msg.key_enter_field))
            end
        elseif event.msg.reset_target ~= nil then
            digiline_send(jumpdrive.channel, {command = "reset"})
            digiline_send(jumpdrive.channel, {command = "get"})
        elseif event.msg.set_target ~= nil then
            if event.msg.target ~= nil then
                mem.jumpdrive.target = coordinates:to_table(event.msg.target)
                digiline_send(
                    jumpdrive.channel,
                    merge_shallow_tables({command = "set", formupdate = false}, mem.jumpdrive.target)
                )
                digiline_send(jumpdrive.channel, {command = "get"})
            end
        elseif event.msg.request_data ~= nil then
            mem.jumpdrive.target = coordinates:to_table(event.msg.target)
            digiline_send(
                jumpdrive.channel,
                merge_shallow_tables({command = "set", formupdate = false}, mem.jumpdrive.target)
            )
            digiline_send(jumpdrive.channel, {command = "get"})
        elseif event.msg.simulate ~= nil then
            mem.jumpdrive.target = coordinates:to_table(event.msg.target)
            digiline_send(
                jumpdrive.channel,
                merge_shallow_tables({command = "set", formupdate = false}, mem.jumpdrive.target)
            )
            digiline_send(jumpdrive.channel, {command = "simulate"})
        elseif event.msg.jump ~= nil then
            if authorised then
                mem.jumpdrive.target = coordinates:to_table(event.msg.target)
                --                 mem.jumpdrive.target = mem.jumpdrive.position
                digiline_send(
                    jumpdrive.channel,
                    merge_shallow_tables({command = "set", formupdate = false}, mem.jumpdrive.target)
                )
                digiline_send(jumpdrive.channel, {command = "jump"})
            else
                send_to_monitors("You can't jump, " .. tostring(event.msg.clicker) .. " ;)")
            end
        elseif event.msg.jump_step_increase ~= nil then
            local target_jump_step_value = tonumber(event.msg.jump_step_value) + 1
            if target_jump_step_value > min_jump_step_value then
                mem.instant_jump.distance = target_jump_step_value
            else
                mem.instant_jump.distance = min_jump_step_value
            end
            if mem.instant_jump.distance ~= tonumber(event.msg.jump_step_value) then
                jumpdrive_page_needs_update = true
            end
        elseif event.msg.jump_step_decrease ~= nil then
            local target_jump_step_value = tonumber(event.msg.jump_step_value) - 1
            if target_jump_step_value > min_jump_step_value then
                mem.instant_jump.distance = target_jump_step_value
            else
                mem.instant_jump.distance = min_jump_step_value
            end
            if mem.instant_jump.distance ~= tonumber(event.msg.jump_step_value) then
                jumpdrive_page_needs_update = true
            end
        elseif event.msg.xi ~= nil then
            if authorised then
                --                 mem.jumpdrive.target = mem.jumpdrive.position
                mem.jumpdrive.target.x = mem.jumpdrive.target.x + mem.instant_jump.distance
                if mem.jumpdrive.instajump then
                    digiline_send(
                        jumpdrive.channel,
                        merge_shallow_tables({command = "set", formupdate = false}, mem.jumpdrive.target)
                    )
                    digiline_send(jumpdrive.channel, {command = "jump"})
                else 
                    jumpdrive_page_needs_update =true
                end
                
            else
                send_to_monitors("You can't jump, " .. tostring(event.msg.clicker) .. " ;)")
            end
        elseif event.msg.xd ~= nil then
            if authorised then
                --                 mem.jumpdrive.target = mem.jumpdrive.position
                mem.jumpdrive.target.x = mem.jumpdrive.target.x - mem.instant_jump.distance
                if mem.jumpdrive.instajump then
                    digiline_send(
                        jumpdrive.channel,
                        merge_shallow_tables({command = "set", formupdate = false}, mem.jumpdrive.target)
                    )
                    digiline_send(jumpdrive.channel, {command = "jump"})
                else 
                    jumpdrive_page_needs_update =true
                end
            else
                send_to_monitors("You can't jump, " .. tostring(event.msg.clicker) .. " ;)")
            end
        elseif event.msg.yi ~= nil then
            if authorised then
                --                 mem.jumpdrive.target = mem.jumpdrive.position
                mem.jumpdrive.target.y = mem.jumpdrive.target.y + mem.instant_jump.distance
                if mem.jumpdrive.instajump then
                    digiline_send(
                        jumpdrive.channel,
                        merge_shallow_tables({command = "set", formupdate = false}, mem.jumpdrive.target)
                    )
                    digiline_send(jumpdrive.channel, {command = "jump"})
                else 
                    jumpdrive_page_needs_update =true
                end
                
            else
                send_to_monitors("You can't jump, " .. tostring(event.msg.clicker) .. " ;)")
            end
        elseif event.msg.yd ~= nil then
            if authorised then
                --                 mem.jumpdrive.target = mem.jumpdrive.position
                mem.jumpdrive.target.y = mem.jumpdrive.target.y - mem.instant_jump.distance
                if mem.jumpdrive.instajump then
                    digiline_send(
                        jumpdrive.channel,
                        merge_shallow_tables({command = "set", formupdate = false}, mem.jumpdrive.target)
                    )
                    digiline_send(jumpdrive.channel, {command = "jump"})
                else 
                    jumpdrive_page_needs_update =true
                end
            else
                send_to_monitors("You can't jump, " .. tostring(event.msg.clicker) .. " ;)")
            end
        elseif event.msg.zi ~= nil then
            if authorised then
                --                 mem.jumpdrive.target = mem.jumpdrive.position
                mem.jumpdrive.target.z = mem.jumpdrive.target.z + mem.instant_jump.distance
                if mem.jumpdrive.instajump then
                    digiline_send(
                        jumpdrive.channel,
                        merge_shallow_tables({command = "set", formupdate = false}, mem.jumpdrive.target)
                    )
                    digiline_send(jumpdrive.channel, {command = "jump"})
                else 
                    jumpdrive_page_needs_update =true
                end
                
            else
                send_to_monitors("You can't jump, " .. tostring(event.msg.clicker) .. " ;)")
            end
        elseif event.msg.zd ~= nil then
            if authorised then
                --                 mem.jumpdrive.target = mem.jumpdrive.position
                mem.jumpdrive.target.z = mem.jumpdrive.target.z - mem.instant_jump.distance
                if mem.jumpdrive.instajump then
                    digiline_send(
                        jumpdrive.channel,
                        merge_shallow_tables({command = "set", formupdate = false}, mem.jumpdrive.target)
                    )
                    digiline_send(jumpdrive.channel, {command = "jump"})
                else 
                    jumpdrive_page_needs_update =true
                end
                
            else
                send_to_monitors("You can't jump, " .. tostring(event.msg.clicker) .. " ;)")
            end
        elseif event.msg.instajump ~= nil then
            if authorised then
                mem.jumpdrive.instajump = event.msg.instajump == "true"
                jumpdrive_page_needs_update =true
            end
        end
        if jumpdrive_page_needs_update == true then
            update_page("Jumpdrive")
        end
    elseif touchscreen.pages[mem.page] == "Bookmarks" then
        --mxedit
        if event.msg.bookmarktxt ~=nil and event.msg.save ~= nil then
            send_to_monitors("BookmarksSave")
            
            mem.l = importBookmarks(event.msg.bookmarktxt)
            
            
        end
        
    end
end

-- ########
-- Jumpdrive
-- ########
if mem.jumpdrive == nil then
    mem.jumpdrive = {
        radius = 1,
        power_req = 0,
        distance = 0,
        powerstorage = 0,
        position = {x = 0, y = 0, z = 0},
        target = {x = 0, y = 0, z = 0},
        success = false,
        msg = "",
        time = 0
    }
end
if event.type == "program" then
    digiline_send(jumpdrive.channel, {command = "get"})
end

if event.type == "digiline" and event.channel == jumpdrive.channel and event.msg then
    local output = ""
    local updated = {}
    for k, v in pairs(event.msg) do
        if mem.jumpdrive[k] ~= nil then
            --             if mem.jumpdrive[k] ~= v then output = output .. " " .. tostring(k) .. ": " .. get_string(mem.jumpdrive[k]) .. " -> " .. get_string(v) end
            mem.jumpdrive[k] = v
        else
            add_line_to_buffer(
                touchscreen.linebuffer.jumpdrive,
                "Unknown jumpdrive propperty: " .. get_string(k) .. ":" .. get_string(v)
            )
        end
    end

    if event.msg.success ~= nil then
        if event.msg.success == true then
            output = output .. " Success! (".. coordinates:to_string(mem.jumpdrive.target) ..")" 
        else
            output = output .. " Failure! (".. coordinates:to_string(mem.jumpdrive.target) ..") (Best refresh and reset)"
        end
    end
    if event.msg.msg then
        output = output .. " " .. event.msg.msg
    end
    if event.msg.time then
        output = output .. " Jumped (" .. tostring(event.msg.time) .. ")"
        mem.jumpdrive.position = mem.jumpdrive.target
        digiline_send(jumpdrive.channel, {command = "get"})
    end
    if output ~= nil then
        if output ~= "" then
            add_line_to_buffer(touchscreen.linebuffer.jumpdrive, tostring(mem.events.count) .. ":" .. output)
        end
    else
        add_line_to_buffer(touchscreen.linebuffer.jumpdrive, tostring(mem.events.count) .. ":" .. "Output was nil!")
    end

    update_page("Jumpdrive")
end

-- ########
-- Event Catcher
-- ########
if mem.event_catcher == nil then
    mem.event_catcher = {
        touchscreen_line_table = {
            "Initialized at " .. get_time_string() .. ", " .. _VERSION,
            mem.environment_information
        }
    }
end

send_to_monitors(event)
update_page("Events")

mem.events.count = mem.events.count + 1

-- MIT License
-- bla
