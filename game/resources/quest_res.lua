local VERSION = "2023/3/24"
local AUTHOR_NOTE = "Administrator"

---@class quest_res
local quest_res = {
    VERSION = VERSION,
    AUTHOR_NOTE = AUTHOR_NOTE,
    MODULE_NAME = "quest_res",
}

local this = quest_res

-- 场景地图列表
this.scenario_maps = {
    0x385, 0x3AA, 0x3A5, 0x3C1, 0x3A6, 0x3A7, 0x3A8, 0x3C2, 0x3A9, 0x386, 0x3AC, 901, 939, 941, 946, 942, 943,
}

-- 带剧情任务等待时间
this.scenario_quest = {
    [40010] = 1000 * 20,
}
-------------------------------------------------------------------------------------
-- 返回对象
return quest_res