local _, addon = ...
local Game = {}
addon.Game = Game

local words, buckets, distances, starts
local candidates = [[
BACK BAKE BALL BAND BANK BARN BASE BATH BEAM BEAR BEAT BELL BELT BEND
BIRD BITE BLOW BLUE BOAT BOLD BONE BOOK BOOT BORN BOWL BULB BURN BUSH
CAKE CALL CALM CAMP CARD CARE CART CASE CASH CAVE CHAT CHIP CITY CLAY
COAL COAT CODE COLD COME COOK COOL COPY CORD CORE COST COVE CURE CUTS
DARK DATE DAWN DEAR DECK DEEP DEER DENT DIRT DISH DOOR DOWN DRAW DROP
EARN EAST EASY EDGE EVEN FACE FACT FAIR FALL FARM FAST FEAR FEED FEEL
FELL FELT FILE FILL FIND FINE FIRE FISH FIVE FLAG FLAT FLEW FLOW FOAM
FOLD FOOD FOOT FORK FORM FORT FOUR FREE FROM FUEL FULL GAME GATE GAVE
GEAR GIFT GIRL GIVE GLAD GLOW GOAL GOAT GOLD GOLF GONE GOOD GRAB GRAY
GREW GROW HAIR HALF HALL HAND HANG HARD HARM HATE HAVE HAWK HEAD HEAL
HEAR HEAT HEEL HELD HELP HERB HERE HERO HIDE HIGH HIKE HILL HINT HOLD
HOLE HOME HOOD HOOK HOPE HORN HOST HOUR HUGE HUNT HURT IDEA IRON ITEM
JUMP JUST KEEP KEPT KIND KING KITE KNEE KNEW KNIT KNOW LACE LACK LAKE
LAMB LAMP LAND LANE LAST LATE LAWN LEAD LEAF LEAN LEFT LEND LENS LESS
LIFE LIFT LIKE LIME LINE LINK LION LIST LIVE LOAD LOAF LOAN LOCK LONG
LOOK LOOP LORD LOSE LOSS LOST LOVE LUCK MADE MAIL MAIN MAKE MALE MANY
MARK MASK MASS MATE MEAL MEAN MEAT MEET MELT MEND MICE MILD MILE MILK
MILL MIND MINE MINT MISS MIST MOLE MOOD MOON MORE MOST MOVE MUCH MULE
NAME NEAR NEAT NECK NEED NEST NEWS NEXT NICE NINE NODE NOSE NOTE ONCE
ONLY OPEN OVEN OVER PACE PACK PAGE PAID PAIN PAIR PALE PALM PARK PART
PASS PAST PATH PEAK PEAR PEEL PEER PICK PIER PILE PILL PINE PINK PIPE
PLAN PLAY PLOT PLUG PLUS POEM POET POLE POND POOL POOR PORT POST POUR
PULL PURE PUSH QUIT RACE RACK RAGE RAIN RAKE RANK RARE RATE READ REAL
REAR REED REEF RENT REST RICE RICH RIDE RING RISE RISK ROAD ROAM ROAR
ROBE ROCK RODE ROLE ROLL ROOF ROOM ROOT ROPE ROSE ROWS RULE RUSH RUST
SAFE SAIL SAKE SALE SALT SAME SAND SAVE SEAL SEAM SEAT SEED SEEK SEEM
SEEN SELF SELL SEND SENT SHED SHIP SHOE SHOP SHOT SHOW SHUT SICK SIDE
SIGN SILK SING SINK SITE SIZE SKIN SKIP SLAM SLIM SLIP SLOW SNOW SOAP
SOCK SOFT SOIL SOLD SOLE SOME SONG SOON SORT SOUL SOUR SPIN SPOT STAR
STAY STEM STEP STIR STOP SUIT SURE SWIM TAIL TAKE TALE TALK TALL TAME
TANK TAPE TASK TEAM TEAR TELL TEND TENT TERM TEST TEXT THAN THAT THEM
THEN THEY THIN THIS TIDE TIDY TILE TILL TIME TINY TIRE TOAD TOLD TONE
TOOK TOOL TOPS TORE TORN TOUR TOWN TRAP TREE TRIM TRIP TRUE TUBE TUNE
TURN TWIN TYPE UNIT UPON USED USER VARY VASE VAST VEIL VERY VEST VIEW
VINE VOTE WAGE WAIT WAKE WALK WALL WANT WARM WASH WAVE WAYS WEAK WEAR
WEED WEEK WELL WENT WERE WEST WHAT WHEN WHIP WIDE WIFE WILD WILL WIND
WINE WING WIRE WISE WISH WITH WOLF WOOD WOOL WORD WORE WORK WORM WORN
WRAP YARD YARN YEAR YELL YOUR ZERO ZONE
]]

local function normalize(word)
    if type(word) ~= "string" then return "" end
    return string.upper((word:gsub("^%s+", ""):gsub("%s+$", "")))
end
Game.Normalize = normalize

function Game.OneLetterApart(first, second)
    if #first ~= 4 or #second ~= 4 then return false end
    local changes = 0
    for i = 1, 4 do
        if first:sub(i, i) ~= second:sub(i, i) then changes = changes + 1 end
    end
    return changes == 1
end

local function visitNeighbors(word, callback)
    for i = 1, 4 do
        local pattern = word:sub(1, i - 1) .. "_" .. word:sub(i + 1)
        for _, neighbor in ipairs(buckets[pattern]) do
            if neighbor ~= word then callback(neighbor) end
        end
    end
end

function Game.Initialize()
    if words then return end
    words, buckets, distances, starts = {}, {}, { POOP = 0 }, {}
    for word in addon.WordData:gmatch("%u+") do
        words[word] = true
        for i = 1, 4 do
            local pattern = word:sub(1, i - 1) .. "_" .. word:sub(i + 1)
            buckets[pattern] = buckets[pattern] or {}
            table.insert(buckets[pattern], word)
        end
    end
    -- One breadth-first search supplies shortest distances for every puzzle.
    local queue, head = { "POOP" }, 1
    while head <= #queue do
        local word = queue[head]
        visitNeighbors(word, function(neighbor)
            if distances[neighbor] == nil then
                distances[neighbor] = distances[word] + 1
                table.insert(queue, neighbor)
            end
        end)
        head = head + 1
    end
    for word in candidates:gmatch("%u+") do
        if distances[word] and distances[word] >= 3 then table.insert(starts, word) end
    end
end

function Game.Distance(word)
    Game.Initialize()
    return distances[normalize(word)]
end

function Game.DailyStart(day)
    Game.Initialize()
    -- Fixed arithmetic and a fixed candidate order keep puzzles consistent.
    return starts[((day * 7919 + 104729) % #starts) + 1]
end

function Game.PracticeStart(random)
    Game.Initialize()
    return starts[(random or math.random)(#starts)]
end

function Game.New(word, mode, day)
    Game.Initialize()
    word = normalize(word)
    if not words[word] then return nil, "That word is not in the bundled dictionary." end
    if not distances[word] then return nil, "That word has no route to POOP in this dictionary." end
    if word == "POOP" then return nil, "Choose a starting word other than POOP." end
    return { start = word, mode = mode or "practice", day = day, path = { word }, hints = 0 }
end

function Game.Submit(session, word)
    word = normalize(word)
    if session.won then return false, "Puzzle complete. Start another practice puzzle." end
    if not word:match("^[A-Z][A-Z][A-Z][A-Z]$") then
        return false, "Enter exactly four letters, A to Z."
    end
    if not words[word] then return false, "That word is not in the bundled dictionary." end
    if not Game.OneLetterApart(session.path[#session.path], word) then
        return false, "Change exactly one letter from the current word."
    end
    table.insert(session.path, word)
    session.won = word == "POOP"
    return true
end

function Game.Undo(session)
    if session.won or #session.path <= 1 then return false end
    table.remove(session.path)
    return true
end

function Game.Hint(session)
    if session.won then return nil end
    local word = session.path[#session.path]
    local nextWord
    visitNeighbors(word, function(neighbor)
        if distances[neighbor] and distances[neighbor] == distances[word] - 1 then
            if not nextWord or neighbor < nextWord then nextWord = neighbor end
        end
    end)
    if nextWord then session.hints = session.hints + 1 end
    return nextWord
end

function Game.Restore(saved, mode, day)
    if type(saved) ~= "table" or type(saved.path) ~= "table" then return nil end
    if saved.mode ~= mode or (mode == "daily" and saved.day ~= day) then return nil end
    local session = Game.New(saved.start, mode, day)
    if not session or saved.path[1] ~= session.start then return nil end
    if mode == "daily" and session.start ~= Game.DailyStart(day) then return nil end
    for i = 2, #saved.path do
        if not Game.Submit(session, saved.path[i]) then return nil end
    end
    if type(saved.hints) == "number" and saved.hints >= 0 then
        session.hints = math.floor(saved.hints)
    end
    return session
end

function Game.RecordWin(db, session)
    if not session.won or session.mode ~= "daily" or db.lastWonDay == session.day then return end
    db.wins = (db.wins or 0) + 1
    db.streak = db.lastWonDay == session.day - 1 and (db.streak or 0) + 1 or 1
    db.bestStreak = math.max(db.bestStreak or 0, db.streak)
    db.lastWonDay = session.day
end

function Game.Result(session)
    local state = session.won and "Complete" or "In progress"
    local label = session.mode == "daily" and ("Daily " .. tostring(session.day)) or "Practice"
    return string.format("Poople for WoW | %s | %s\n%s -> POOP | %d moves | par %d | %d hints\n%s",
        label, state, session.start, #session.path - 1, distances[session.start],
        session.hints, table.concat(session.path, " > "))
end
