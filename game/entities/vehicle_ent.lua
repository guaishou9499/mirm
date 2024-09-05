------------------------------------------------------------------------------------
-- game/entities/vehicle_ent.lua
--
-- 本模块为vehicle_ent单元
--
-- @module      vehicle_ent
-- @author      Administrator
-- @license     MIT
-- @release     v1.0.0 - 2023-04-08
-- @copyright   2023
-- @usage
-- local vehicle_ent = import('game/entities/vehicle_ent.lua')
------------------------------------------------------------------------------------

-- 模块定义
---@class vehicle_ent
local vehicle_ent = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-04-08 - Initial release',
    -- 模块名称
    MODULE_NAME = 'vehicle_ent module'
}

-- 自身模块
local this = vehicle_ent
-- 框架模块
local settings = settings
local trace = trace
local decider = decider
local common = common
-- 引用模块
---@type unit
local unit = import('game/entities/unit')
---@type item_res
local item_res = import('game/resources/item_res')

---------------------------------------------------------------------
-- [事件] 预载函数(重载脚本时)
---------------------------------------------------------------------
this.super_preload = function()
    this.wi_auto_vehicle = decider.run_interval_wrapper('坐骑检查', this.auto_vehicle, 1000 * 60 * 6)
end

--------------------------------------------------------------------------------
-- [行为] 自动坐骑
--
-- @treturn     boolean
-- @usage
-- vehicle_ent.auto_vehicle()
--------------------------------------------------------------------------------
this.auto_vehicle = function()
    local ret = false
    local status = local_player:status()
    if status == 9 or status == 8 then
        return ret
    end
    ret = this.add_vehicle()
    ret = this.use_vehicle()
    return ret
end

--------------------------------------------------------------------------------
-- [行为] 召唤坐骑
--
-- @treturn     boolean
-- @usage
-- vehicle_ent.add_vehicle()
--------------------------------------------------------------------------------
this.add_vehicle = function()
    local ret = false
    -- 获取坐骑物品信息
    local vehicle_item_list = this.get_vehicle_item_info()
    if not table_is_empty(vehicle_item_list) then
        for i = 1, #vehicle_item_list do
            ret = unit.wa_add_vehicle(vehicle_item_list[i].id)
            trace.log_info('召唤坐骑', vehicle_item_list[i].name)
            decider.sleep(1000)
            ret = unit.wa_pass_pet_direct()
        end
    end
    return ret
end

--------------------------------------------------------------------------------
-- [行为] 使用坐骑
--
-- @treturn     boolean
-- @usage
-- vehicle_ent.use_vehicle()
--------------------------------------------------------------------------------
this.use_vehicle = function()
    local ret = false
    -- 获取坐骑信息
    local vehicle_list = this.get_vehicle_info()
    if not table_is_empty(vehicle_list) then
        -- 使用经验最高的坐骑
        table.sort(vehicle_list, function(a, b)
            return a.exp > b.exp
        end)
        ret = unit.wa_use_vehicle(vehicle_list[1].id)
        trace.log_info('使用坐骑', vehicle_list[1].name)
    end
    return ret
end

--------------------------------------------------------------------------------
-- [读取] 获取坐骑物品信息
--
-- @treturn      t                              坐骑信息 table，包括：
-- @tfield[t]    integer        id              坐骑id
-- @tfield[t]    string         name            坐骑名字
-- @usage
-- local ret = vehicle_ent.vehicle_item_list()
--------------------------------------------------------------------------------
this.get_vehicle_item_info = function()
    local ret = {}
    ret = unit.get_info(item_unit
    , { { 'name', item_res.vehicle_item_list, unit.of } }
    , { 'id', 'name' }
    , true
    , { 0, 0 }
    )
    return ret
end

--------------------------------------------------------------------------------
-- [读取] 获取坐骑信息
--
-- @treturn      t                              坐骑信息 table，包括：
-- @tfield[t]    integer        id              坐骑id
-- @tfield[t]    string         name            坐骑名字
-- @tfield[t]    integer        exp             坐骑经验
-- @usage
-- local ret = vehicle_ent.get_vehicle_info()
--------------------------------------------------------------------------------
this.get_vehicle_info = function()
    local ret = {}
    ret = unit.get_info(vehicle_unit
    , { { 'status', 2, unit.eq }, { 'is_use', false, unit.eq } }
    , { 'id', 'name', 'exp' }
    , true
    , {}
    )
    return ret
end

---------------------------------------------------------------------
-- [内部] 将对象转换为字符串
--
-- @local
-- @treturn      string                     模块名称
---------------------------------------------------------------------
function vehicle_ent.__tostring()
    return this.MODULE_NAME
end

vehicle_ent.__index = vehicle_ent

---------------------------------------------------------------------
-- [构造] 创建一个新的实例
--
-- @local 
-- @tparam       table     args             可选参数，用于初始化新实例
-- @treturn      table                      新创建的实例
---------------------------------------------------------------------
function vehicle_ent:new(args)
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

    return setmetatable(new, vehicle_ent)
end

---------------------------------------------------------------------
-- 返回实例对象
return vehicle_ent:new()
---------------------------------------------------------------------