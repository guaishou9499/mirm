------------------------------------------------------------------------------------
-- game/entities/skill_ent.lua
--
-- 本模块为skill_ent单元
--
-- @module      skill_ent
-- @author      Administrator
-- @license     MIT
-- @release     v1.0.0 - 2023-04-08
-- @copyright   2023
-- @usage
-- local skill_ent = import('game/entities/skill_ent.lua')
------------------------------------------------------------------------------------

-- 模块定义
---@class skill_ent
local skill_ent = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-04-08 - Initial release',
    -- 模块名称
    MODULE_NAME = 'skill_ent module'
}

-- 自身模块
local this = skill_ent
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
    this.wi_auto_skill = decider.run_interval_wrapper('技能检查', this.auto_skill, 1000 * 60 * 6)
end

--------------------------------------------------------------------------------
-- [行为] 自动技能
--
-- @treturn     boolean
-- @usage
-- skill_ent.auto_skill()
--------------------------------------------------------------------------------
this.auto_skill = function()
    local ret = false
    if local_player:level() < 3 then
        return ret
    end
    this.learn_skill()
    this.learn_force()
    return ret
end

--------------------------------------------------------------------------------
-- [行为] 学习技能
--
-- @treturn     boolean
-- @usage
-- skill_ent.learn_skill()
--------------------------------------------------------------------------------
this.learn_skill = function()
    local ret = false
    -- 获取技能物品信息
    local skill_item_list = this.get_skill_item_info()
    xxmsg(#skill_item_list)
    for i = 1, #skill_item_list do
        xxmsg(skill_item_list[i].name)
    end
    -- 获取技能信息
    local skill_list = this.get_skill_info()
    if not table_is_empty(skill_item_list) then
        for i = 1, #skill_item_list do
            local skill_name = string.sub(skill_item_list[i].name, 1, -8)
            -- 判断技能是否学习
            if not skill_list[skill_name] then
                ret = unit.wa_skill_learn(skill_item_list[i].id)
                trace.log_info('学习技能', skill_item_list[i].name)
                decider.sleep(1000)
            else
                -- todo: 缺少指令 可用发包实现
                trace.log_info('升级技能', skill_item_list[i].name)
                if skill_item_list[i].name == '화염장 비급' then
                    local packet = packet_unit:new(64)
                    packet:push_word(0) --2字节word
                    packet:push_dword(0x157) --4字节dword
                    packet:push_dword(1) --4字节dword
                    packet:send(0xDF)
                    packet:delete()
                end
                decider.sleep(1000)
            end
        end
    end
    return ret
end

--------------------------------------------------------------------------------
-- [行为] 学习内功
--
-- @treturn     boolean
-- @usage
-- skill_ent.learn_force()
--------------------------------------------------------------------------------
this.learn_force = function()
    local ret = false
    local item_list = this.get_force_item_info()
    -- print_t(item_list)
    if not table_is_empty(item_list) then
        for i = 1, #item_list do
            local idx = table.index_of(this.force_item_list, item_list[i].name) - 1
            local level = skill_unit.get_force_level_byidx(idx)
            unit.wa_reinforce(idx, level + 1)
            --skill_unit.reinforce(idx, level + 1)
            decider.sleep(1000)
        end
    end
    return ret
end

--------------------------------------------------------------------------------
-- [读取] 获取技能物品信息
--
-- @treturn      t                              技能物品信息 table，包括：
-- @tfield[t]    integer        id              技能物品id
-- @tfield[t]    string         name            技能物品名字
-- @usage
-- local ret = skill_ent.get_skill_item_info()
--------------------------------------------------------------------------------
this.get_skill_item_info = function()
    local ret = {}
    ret = unit.get_info(item_unit
    , { { 'name', item_res.skill_item_list, unit.of } }
    , { 'id', 'name' }
    , true
    , { 0, 0 }
    )
    return ret
end

--------------------------------------------------------------------------------
-- [读取] 获取内功物品信息
--
-- @treturn      t                              内功物品信息 table，包括：
-- @tfield[t]    integer        id              内功物品id
-- @tfield[t]    string         name            内功物品名字
-- @usage
-- local ret = skill_ent.get_force_item_info()
--------------------------------------------------------------------------------
this.get_force_item_info = function()
    local ret = {}
    ret = unit.get_info(item_unit
    , { { 'name', item_res.force_item_list, unit.of } }
    , { 'id', 'name' }
    , true
    , { 0, 0 }
    )
    return ret
end

--------------------------------------------------------------------------------
-- [读取] 获取技能信息
--
-- @treturn      t                              技能信息 table，包括：
-- @tfield[t]    integer        id              技能id
-- @tfield[t]    string         name            技能名字
-- @usage
-- local ret = skill_ent.get_skill_info()
--------------------------------------------------------------------------------
this.get_skill_info = function()
    local ret = {}
    local skill_info = unit.get_info(skill_unit
    , { { 'name', '0', unit.ne } }
    , { 'id', 'name' }
    , true
    , { 0, 0 }
    )
    for i = 1, #skill_info do
        ret[skill_info[i].name] = skill_info[i].id
    end
    return ret
end

---------------------------------------------------------------------
-- [内部] 将对象转换为字符串
--
-- @local
-- @treturn      string                     模块名称
---------------------------------------------------------------------
function skill_ent.__tostring()
    return this.MODULE_NAME
end

skill_ent.__index = skill_ent

---------------------------------------------------------------------
-- [构造] 创建一个新的实例
--
-- @local 
-- @tparam       table     args             可选参数，用于初始化新实例
-- @treturn      table                      新创建的实例
---------------------------------------------------------------------
function skill_ent:new(args)
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

    return setmetatable(new, skill_ent)
end

---------------------------------------------------------------------
-- 返回实例对象
return skill_ent:new()
---------------------------------------------------------------------