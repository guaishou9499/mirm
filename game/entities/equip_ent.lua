------------------------------------------------------------------------------------
-- game/entities/equip_ent.lua
--
-- 本模块为equip_ent单元
--
-- @module      equip_ent
-- @author      Administrator
-- @license     MIT
-- @release     v1.0.0 - 2023-03-24
-- @copyright   2023
-- @usage
-- local equip_ent = import('game/entities/equip_ent.lua')
------------------------------------------------------------------------------------

-- 模块定义
---@class equip_ent
local equip_ent = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-03-24 - Initial release',
    -- 模块名称
    MODULE_NAME = 'equip_ent module'
}

-- 自身模块
local this = equip_ent
-- 框架模块
local settings = settings
local trace = trace
local decider = decider
local common = common
-- 引用模块
---@type unit
local unit = import('game/entities/unit')
---@type common_unt
local common_unt = import('game/entities/unit/common_unt')
---------------------------------------------------------------------
-- [事件] 预载函数(重载脚本时)
---------------------------------------------------------------------
this.super_preload = function()
    this.wi_auto_equip = decider.run_interval_wrapper('检查装备', this.auto_equip, 1000 * 60 * 6)
end

---------------------------------------------------------------------
-- [读取] 获取更优装备信息
--
-- @tparam      number      equip_pos       装备位置
-- @tparam      number      quality         装备品质
-- @treturn     table       装备信息
---------------------------------------------------------------------
this.get_better_equip = function(equip_pos, quality)
    local ret = {}
    ret = unit.get_info(item_unit,
            { { 'equip_pos', equip_pos, unit.eq }, { 'quality', quality, unit.ge }, { 'type', 2, unit.eq }, { 'race', { 2, 6 }, unit.of } },
            { 'durability', 'name', 'id', 'type', 'equip_pos', 'quality', 'combat_power' },
            true,
            { 0, 0 }
    )
    return ret
end

---------------------------------------------------------------------
-- [读取] 获取当前装备信息
--
-- @tparam      number      equip_pos       装备位置
-- @treturn     table       装备信息
---------------------------------------------------------------------
this.get_used_equip = function(equip_pos)
    local ret = {}
    local used_equip_obj = item_unit.get_equip_ptr_bypos(equip_pos)
    if used_equip_obj ~= 0 then
        ret = unit.get_info(item_unit,
                { { 'type', 2, unit.eq }, { 'quality', 1, unit.ge } },
                { 'id', 'name', 'durability', 'type', 'equip_pos', 'quality', 'combat_power' },
                false,
                { 1, 1 },
                used_equip_obj
        )
    end
    return ret
end

---------------------------------------------------------------------
-- [行为] 佩戴更优装备
--
-- @tparam      number      equip_pos       装备位置
-- @treturn     boolean     佩戴成功与否
---------------------------------------------------------------------
this.use_better_equip = function(equip_pos)
    local ret = false
    local tag = false

    local used_equip_info = this.get_used_equip(equip_pos)
    local quality = used_equip_info[1] and used_equip_info[1].quality or 0
    local combat_power = used_equip_info[1] and used_equip_info[1].combat_power or 0
    local better_equip_info = this.get_better_equip(equip_pos, quality)
    if not table_is_empty(better_equip_info) then
        tag = true
    end

    if tag then
        table.sort(better_equip_info, function(a, b) return a.combat_power > b.combat_power  end)
        if better_equip_info[1].combat_power > combat_power then
            local id = better_equip_info[1].id
            local name = better_equip_info[1].name
            ret = true
            trace.log_info('佩戴' .. name)
            --item_unit.use_equip(id, equip_pos, 0)
            unit.wa_use_equip(id, equip_pos, 0)
            decider.sleep(1000)
        end
    end

    return ret
end

---------------------------------------------------------------------
-- [行为] 配戴所有更好的装备
--
-- @treturn     boolean     佩戴成功与否
---------------------------------------------------------------------
this.use_equip = function()
    local ret = false
    for i = 0, 15 do
        if not decider.is_working() then
            break
        end
        if this.use_better_equip(i) then
            ret = true
        end
    end
    return ret
end

---------------------------------------------------------------------
-- [行为] 自动装备
---------------------------------------------------------------------
this.auto_equip = function()
    if local_player:level() < 3 then
        return false
    end
    this.use_equip()
end

---------------------------------------------------------------------
-- [内部] 将对象转换为字符串
--
-- @local
-- @treturn      string                     模块名称
---------------------------------------------------------------------
function equip_ent.__tostring()
    return this.MODULE_NAME
end

equip_ent.__index = equip_ent

---------------------------------------------------------------------
-- [构造] 创建一个新的实例
--
-- @local
-- @tparam       table     args             可选参数，用于初始化新实例
-- @treturn      table                      新创建的实例
---------------------------------------------------------------------
function equip_ent:new(args)
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

    return setmetatable(new, equip_ent)
end

---------------------------------------------------------------------
-- 返回实例对象
return equip_ent:new()
---------------------------------------------------------------------