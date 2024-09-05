local VERSION = "2023-4-5"
local AUTHOR_NOTE = "Administrator"

---@class game_res
local game_res = {
    VERSION = VERSION,
    AUTHOR_NOTE = AUTHOR_NOTE,
    MODULE_NAME = "game_res",
}

local this = game_res


--主角状态 1 2静止中 8 9攻击中 14 15移动中 29采集中 30钓鱼中 32
-- 18
this.player_still = { 1, 2 }
this.player_running = { 14, 15 }
this.player_fighting = { 8, 9 }
this.player_gathering = { 29, }
this.player_teleporting = { 24 }
this.player_fishing = { 30 }

this.level_info = {
    [10607] = 30,
}
-------------------------------------------------------------------------------------
-- 返回对象
return game_res