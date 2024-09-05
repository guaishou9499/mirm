local VERSION = "2023-4-4"
local AUTHOR_NOTE = "Administrator"

---@class pet_res
local pet_res = {
    VERSION = VERSION,
    AUTHOR_NOTE = AUTHOR_NOTE,
    MODULE_NAME = "pet_res",
}

local this = pet_res

this.pet_list = { "高级必获灵宠召唤券", "活动灵宠召唤券", "宝物必获灵宠召唤券", "猪猪灵宠召唤券", "【活动】灵宠召唤券",
                  '돈돈 영물 소환권',
}

-------------------------------------------------------------------------------------
-- 返回对象
return pet_res