------------------------------------------------------------------------------------
-- game/entities/unit.lua
--
-- 本模块为unit单元
--
-- @module      unit
-- @author      Administrator
-- @license     MIT
-- @release     v1.0.0 - 2023-03-25
-- @copyright   2023
-- @usage
-- local unit = import('game/entities/unit.lua')
------------------------------------------------------------------------------------

-- 模块定义
---@class unit
local unit = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-03-25 - Initial release',
    -- 模块名称
    MODULE_NAME = 'unit module'
}

-- 自身模块
local this = unit
-- 框架模块
local settings = settings
local trace = trace
local decider = decider
local common = common
-- 引用模块
---@type common_unt
local common_unt = import('game/entities/unit/common_unt')
---------------------------------------------------------------------
-- [事件] 预载函数(重载脚本时)
---------------------------------------------------------------------
this.unit_list = {
    actor_unit, role_unit, sign_unit, quest_unit, ui_unit, main_unit,
    skill_unit, exchange_unit, item_unit, login_unit, mail_unit, party_unit,
    vehicle_unit, pet_unit, stall_unit, achieve_unit, avatar_unit,
    collection_unit, dungeon_unit, game_unit, mandala_unit, quick_unit,
    title_unit, wemix_unit

}
this.super_preload = function()

    -- 如果不同unit有相同名的函数时会出现后面的包装无效
    for k, v in pairs(this.unit_list) do
        for name, func in pairs(v) do
            this['wa_' .. name] = decider.run_action_wrapper('wa_' .. name, func)
        end
    end

    --this.get_info = decider.run_normal_wrapper('读取信息', this.get_info)
    --this.do_action = decider.run_action_wrapper('执行动作', this.do_action)
end

---------------------------------------------------------------------
-- [读取] 通用获取信息函数
--
-- @tparam   object     unit        unit对象
-- @tparam   table      cond        筛选条件 {属性, 值, 比较函数}
-- @tparam   string     fields      需要获取的字段
-- @tparam   boolean    records     获取数据个数 false 单个 true 多个
-- @tparam   table      init        初始条件 {类型, 参数}
-- @treturn  table                  需要获取字段的表 或者 空表
-- @usage
-- local info = this.get_info(quest_unit, {{'id', 1, this.eq},}, {'name'}, false, {})
-- print_r(info)
---------------------------------------------------------------------
this.get_info = function(unit, cond, fields, records, init, obj)
    local ret = {}
    local type = nil
    local arg = nil

    if not table_is_empty(init) then
        if init[1] then
            type = init[1]
        end
        if init[2] then
            arg = init[2]
        end
    end
    --xxmsg(type)
    local list = type and unit.list(type) or unit.list()
    --print_t(list)
    local ctx = unit:new()
    for i = 1, #list do
        local obj = obj or list[i]
        if arg and ctx:init(obj,arg) or ctx:init(obj) then
            local filter = true
            for i = 1, #cond do
                local field_value = ctx[cond[i][1]](ctx)
                if not this.eval(field_value, cond[i][2], cond[i][3]) then
                    filter = false
                    break
                end
            end
            if filter then
                local t = {}
                t.obj = obj
                for j = 1, #fields do
                    t[fields[j]] = ctx[fields[j]](ctx)
                end
                ret[#ret + 1] = t
                if not records then
                    break
                end
            end
        end
    end
    ctx:delete()
    return ret
end

---------------------------------------------------------------------
-- [读取] 通过对象获取信息函数
--
-- @tparam   object     unit    unit对象
-- @tparam   table      cond    筛选条件 {属性, 值, 比较函数}
-- @tparam   table      init    初始条件 {类型, 参数}
-- @tparam   number      obj    对象
-- @tparam   string     ...     可变参数，需要获取的字段
-- @treturn  table              需要获取字段的表 或者 空表
-- @usage
-- local info = this.get_info(quest_unit, {{'id', 1, this.eq},}, 'name')
-- print_r(info)
---------------------------------------------------------------------
this.get_info_by_obj = function(unit, cond, init, obj, ...)
    local ret = {}
    local args = { ... }
    local type = nil
    local arg = nil

    if not table_is_empty(init) then
        if init[1] then
            type = init[1]
        end
        if init[2] then
            arg = init[2]
        end
    end
    local ctx = unit:new()
    local obj = obj
    if arg and ctx:init(obj, arg) or ctx:init(obj) then
        local filter = true
        for i = 1, #cond do
            local field_value = ctx[cond[i][1]](ctx)
            if not this.eval(field_value, cond[i][2], cond[i][3]) then
                filter = false
                break
            end
        end
        if filter then
            ret.obj = obj
            for j = 1, #args do
                ret[args[j]] = ctx[args[j]](ctx)
            end
        end
    end
    ctx:delete()
    return ret
end

---------------------------------------------------------------------
this.eq = function(x, y) return x == y  end
this.ne = function(x, y) return x ~= y  end
this.gt = function(x, y) return x > y  end
this.ge = function(x, y) return x >= y  end
this.lt = function(x, y) return x < y  end
this.le = function(x, y) return x <= y  end
this.of = function(x, y) return common_unt.is_in_list(x, y) end
this.contain = function(x, y) return string.find(x, y) end

this.eval = function(a,b,op) return op(a, b) end

---------------------------------------------------------------------
-- [读取] 通用执行动作函数
--
-- @tparam   object     action  动作函数
-- @tparam   string     ...     可变参数
-- @treturn  boolean            执行动作的结果
-- @usage
---------------------------------------------------------------------
this.do_action = function(action,  ...)
    local ret = false
    local msg = ''
    ret, msg = action(...)
    return ret, msg
end
---------------------------------------------------------------------
-- [内部] 将对象转换为字符串
--
-- @local
-- @treturn      string                     模块名称
---------------------------------------------------------------------
function unit.__tostring()
    return this.MODULE_NAME
end

unit.__index = unit

---------------------------------------------------------------------
-- [构造] 创建一个新的实例
--
-- @local 
-- @tparam       table     args             可选参数，用于初始化新实例
-- @treturn      table                      新创建的实例
---------------------------------------------------------------------
function unit:new(args)
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

    return setmetatable(new, unit)
end

---------------------------------------------------------------------
-- 返回实例对象
return unit:new()
---------------------------------------------------------------------