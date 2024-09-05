local VERSION = "2023-4-14"
local AUTHOR_NOTE = "Administrator"

---@class collection_res
local collection_res = {
    VERSION = VERSION,
    AUTHOR_NOTE = AUTHOR_NOTE,
    MODULE_NAME = "collection_res res",
}

local this = collection_res

this.collection_pos_info = {
    [20] = {
        { 3005, 20509, 11216, 101, '银杏谷村庄' },
        --{ 5249, 16747, 11155, 101, '银杏谷村庄' },
    },
    [30] = {
        { 3005, 20509, 11216, 101, '银杏谷村庄' },
        --{ 5249, 16747, 11155, 101, '银杏谷村庄' },
    },
}
-------------------------------------------------------------------------------------
-- 返回对象
return collection_res