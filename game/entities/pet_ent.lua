------------------------------------------------------------------------------------
-- game/entities/pet_ent.lua
--
-- 本模块为pet_ent单元
--
-- @module      pet_ent
-- @author      Administrator
-- @license     MIT
-- @release     v1.0.0 - 2023-04-04
-- @copyright   2023
-- @usage
-- local pet_ent = import('game/entities/pet_ent.lua')
------------------------------------------------------------------------------------

-- 模块定义
---@class pet_ent
local pet_ent = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-04-04 - Initial release',
    -- 模块名称
    MODULE_NAME = 'pet_ent module'
}

-- 自身模块
local this = pet_ent
-- 框架模块
local settings = settings
local trace = trace
local decider = decider
local common = common
-- 引用模块
---@type unit
local unit = import('game/entities/unit')
---@type pet_res
local pet_res = import('game/resources/pet_res')
---@type game_ent
local game_ent = import('game/entities/game_ent')

---------------------------------------------------------------------
-- [事件] 预载函数(重载脚本时)
---------------------------------------------------------------------
this.super_preload = function()
    this.wi_auto_pet = decider.run_interval_wrapper('宠物检查', this.auto_pet, 1000 * 60 * 6)
end

---------------------------------------------------------------------
-- [行为] 使用精灵召唤券
--
--  @treturn        boolean     true 成功 false 失败
---------------------------------------------------------------------
this.use_pet_item = function()
    local ret = false
    local item_list = this.get_item_info()
    for i = 1, #item_list do
        --pet_unit.add_pet(item_list[i].id, 1)
        unit.wa_add_pet(item_list[i].id, 1)
        ret = true
        decider.sleep(5000)
        game_ent.close_window()
    end
    return ret
end

---------------------------------------------------------------------
-- [行为] 装备精灵
--
--  @treturn        boolean     true 成功 false 失败
---------------------------------------------------------------------
this.set_pet = function()
    local ret = false
    local pet_list = this.get_pet_info()
    if table_is_empty(pet_list) then
        return false
    end
    if pet_list[1].id ~= pet_unit.get_summon_pet_id() then
        for i = 1, #pet_list do
            if pet_list[i].summon_pos ~= 3 then
                unit.wa_ues_pet(pet_list[i].id, 3)
                --pet_unit.ues_pet(pet_list[i].id, 3)
                decider.sleep(1000)
            end
        end
    else
        return false
    end
    local n = #pet_list > 3 and 2 or #pet_list - 1
    for i = 0, n do
        local pet_id = pet_list[i + 1].id
        unit.wa_ues_pet(pet_id, i)
        --pet_unit.ues_pet(pet_id, i)
        decider.sleep(1000)
        ret = true
    end
    return ret
end

---------------------------------------------------------------------
-- [行为] 自动装备精灵
--
--  @treturn        boolean     true 成功 false 失败
---------------------------------------------------------------------
this.auto_pet = function()
    local ret = false
    if local_player:level() < 4 then
        return ret
    end
    this.use_pet_item()
    this.set_pet()
    return ret
end

---------------------------------------------------------------------
-- [读取] 通过精灵召唤券名称获取物品信息
--
--  @treturn        返回满足要求的列表
---------------------------------------------------------------------
this.get_item_info = function()
    local ret = {}
    local pet_list = pet_res.pet_list
    ret = unit.get_info(item_unit,
            { { 'name', pet_list, unit.of }, },
            { 'id', 'num' },
            true,
            { 0, 0 }
    )
    return ret
end

---------------------------------------------------------------------
-- [读取] 获取精灵列表 按品质排序
--
--  @treturn        返回满足要求的列表
---------------------------------------------------------------------
this.get_pet_info = function()
    local ret = {}
    ret = unit.get_info(pet_unit,
            { },
            { 'id', 'quality', 'summon_pos' },
            true,
            {}
    )
    if not table_is_empty(ret) then
        table.sort(ret, function(a, b)
            return a.quality > b.quality
        end)

    end
    return ret
end

---------------------------------------------------------------------
-- [内部] 将对象转换为字符串
--
-- @local
-- @treturn      string                     模块名称
---------------------------------------------------------------------
function pet_ent.__tostring()
    return this.MODULE_NAME
end

pet_ent.__index = pet_ent

---------------------------------------------------------------------
-- [构造] 创建一个新的实例
--
-- @local
-- @tparam       table     args             可选参数，用于初始化新实例
-- @treturn      table                      新创建的实例
---------------------------------------------------------------------
function pet_ent:new(args)
    local new = {}

    -- 预载函数(重载脚本时)
    if this.super_preload then
        this.super_preload()
    end

    if args then
        for key, val in pairs(args) do
            new[key] = val
        end
    end

    return setmetatable(new, pet_ent)
end

---------------------------------------------------------------------
-- 返回实例对象
return pet_ent:new()
---------------------------------------------------------------------