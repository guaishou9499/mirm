------------------------------------------------------------------------------------
-- game/entities/shortcuts_ent.lua
--
-- 本模块为quick_ent单元
--
-- @module      quick_ent
-- @author      Administrator
-- @license     MIT
-- @release     v1.0.0 - 2023-03-29
-- @copyright   2023
-- @usage
-- local quick_ent = import('game/entities/shortcuts_ent.lua')
------------------------------------------------------------------------------------

-- 模块定义
---@class shortcuts_ent
local shortcuts_ent = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-03-29 - Initial release',
    -- 模块名称
    MODULE_NAME = 'shortcuts ent'
}

-- 自身模块
local this = shortcuts_ent
-- 框架模块
local settings = settings
local trace = trace
local decider = decider
local common = common
-- 引用模块
---@type unit
local unit = import('game/entities/unit')
---@type shop_res
local shop_res = import('game/resources/shop_res')
---------------------------------------------------------------------
-- [事件] 预载函数(重载脚本时)
---------------------------------------------------------------------
this.super_preload = function()
    xxmsg('quick_ent.super_preload')
    this.wi_set_shortcuts = decider.run_interval_wrapper('间隔设置快捷键', this.set_shortcuts, 1000 * 60 * 3)
    this.wi_set_shortcut = decider.run_interval_wrapper('间隔设置单个快捷键', this.set_shortcut, 1000 * 60 * 3)
end

---------------------------------------------------------------------
-- [读取] 通过物品名称获取res_id和数量
--
-- @tparam  string  name    物品名称
-- @treturn number          物品res_id
---------------------------------------------------------------------
this.get_item_info = function(name)
    local info = unit.get_info(item_unit,
            { { 'name', name, unit.eq } },
            { 'res_id', 'num' },
            false,
            { 0, 0 }
    )

    local res_id = info[1] and info[1].res_id or 0
    local num = info[1] and info[1].num or 0
    return res_id, num
end


---------------------------------------------------------------------
-- [行为] 设置指定位置快捷键
--
-- @tparam      number      pos     快捷键位置 从0开始
-- @tparam      number      mode    1 装备 0 取下 蓝（小）（中）
---------------------------------------------------------------------
this.set_shortcut = function(mode)
    local ret = false
    if mode == 0 then
        --trace.log_debug('快捷键状态', quick_unit.get_quick_item_active_state(1))
        if quick_unit.get_quick_item_active_state(1) == 1 then
            ret = unit.wa_set_item_quick(0, 1)
            --ret = quick_unit.set_item_quick(0, 1)
        end
        if quick_unit.get_quick_item_active_state(3) == 1 then
            ret = unit.wa_set_item_quick(0, 3)
            --ret = quick_unit.set_item_quick(0, 3)
        end
    else
        -- todo: 快捷键取消后激活状态仍为 1
        local item_res_id, item_num = this.get_item_info('마력 회복약(소)')
        if item_res_id ~= 0 and item_num ~= 0 --[[and quick_unit.get_quick_item_active_state(pos) ~= 1]] then
            ret = unit.wa_set_item_quick(item_res_id, 1)
            --ret = quick_unit.set_item_quick(item_res_id, 1)
        end
        item_res_id, item_num = this.get_item_info('마력 회복약(중)')
        if item_res_id ~= 0 and item_num ~= 0 --[[and quick_unit.get_quick_item_active_state(pos) ~= 1]] then
            ret = unit.wa_set_item_quick(item_res_id, 3)
            --ret = quick_unit.set_item_quick(item_res_id, 3)
        end
    end
    return ret
end

---------------------------------------------------------------------
-- [行为] 设置自动物品快捷键
--
---------------------------------------------------------------------
this.set_shortcuts = function()
    local ret = false
    local cur_level = local_player:level()
    local level = math.ceil(cur_level / 10) * 10
    local item_name = shop_res.potion_list[level] and shop_res.potion_list[level].names or {}
    if table_is_empty(item_name) then
        trace.log_debug('药水名称错误')
        return false
    end
    for i = 0, 1 do
        local name = item_name[i + 1]
        if string.find(name, --[['小']]'(소)') then
            if quick_unit.get_quick_item_name_byidx(i) ~= name or quick_unit.get_quick_item_active_state(i) ~= 1
                or local_player:hp() <= 10 or local_player:mp() <= 10
            then
                local item_res_id, item_num = this.get_item_info(name)
                if item_res_id ~= 0 and item_num ~= 0 then
                    quick_unit.set_item_quick(item_res_id, i)
                    ret = true
                end
            end
        elseif string.find(name, --[['中']]'(중)') then
            --xxmsg('9999',quick_unit.get_quick_item_name_byidx(i + 2),quick_unit.get_quick_item_active_state(i + 2))
            if quick_unit.get_quick_item_name_byidx(i + 2) ~= name or quick_unit.get_quick_item_active_state(i + 2) ~= 1
                    or local_player:hp() <= 10 or local_player:mp() <= 10
            then
                local item_res_id, item_num = this.get_item_info(name)
                if item_res_id ~= 0 and item_num ~= 0 then
                    quick_unit.set_item_quick(item_res_id, i + 2)
                    ret = true
                end
            end
        end
    end


    return ret
end
---------------------------------------------------------------------
-- [内部] 将对象转换为字符串
--
-- @local
-- @treturn      string                     模块名称
---------------------------------------------------------------------
function shortcuts_ent.__tostring()
    return this.MODULE_NAME
end

shortcuts_ent.__index = shortcuts_ent

---------------------------------------------------------------------
-- [构造] 创建一个新的实例
--
-- @local
-- @tparam       table     args             可选参数，用于初始化新实例
-- @treturn      table                      新创建的实例
---------------------------------------------------------------------
function shortcuts_ent:new(args)
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

    return setmetatable(new, shortcuts_ent)
end

---------------------------------------------------------------------
-- 返回实例对象
return shortcuts_ent:new()
---------------------------------------------------------------------