------------------------------------------------------------------------------------
-- game/entities/switch_ent.lua
--
-- 这个模块主要是项目内物品相关功能操作。
--
-- @module      switch_ent
-- @author      admin
-- @license     MIT
-- @release     v1.0.0 - 2023-03-22
-- @copyright   2023
-- @usage
-- local switch_ent = import('game/entities/switch_ent.lua')
------------------------------------------------------------------------------------

-- 模块定义
---@class switch_ent
local switch_ent = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-03-22 - Initial release',
    -- 模块名称
    MODULE_NAME = 'switch_ent module',
    -- 只读模式
    READ_ONLY = false,
}

-- 实例对象
local this = switch_ent
-- 日志模块
local trace = trace
-- 决策模块
local decider = decider
local common = common
---@type redis_ent
local redis_ent = import('game/entities/redis_ent')
---@type unit
local unit = import('game/entities/unit')
---@type common_unt
local common_unt = import('game/entities/unit/common_unt')
------------------------------------------------------------------------------------
-- [事件] 预载函数(重载脚本)
------------------------------------------------------------------------------------
switch_ent.super_preload = function()

end

---------------------------------------------------------------------
-- [判断] 判断主线是否断档
--
-- @treturn  boolean                  主线断档返回true否则返回false
-- @usage
-- local quest = switch_ent.quest()
-- if not quest then print_r('主线已断档') end
---------------------------------------------------------------------
function switch_ent.quest()
    if redis_ent['执行主线'] == 0 then
        return false
    end
    if local_player:level() ~= 0 then
        this.my_level = local_player:level()
    end
    if not this.my_level then
        this.my_level = 0
    end
    if redis_ent['结束主线等级'] and redis_ent['结束主线等级'] ~= 0 and this.my_level > redis_ent['结束主线等级'] then
        return false
    end
    local quest_info = unit.get_info(quest_unit
    , { { 'main_type', 0, unit.eq }, { 'status', 4, unit.eq }, { 'name', '0', unit.ne } }
    , { 'id' }
    , false
    , {})
    if not table_is_empty(quest_info) then
       return common_unt.is_in_list(quest_info[1].id, { 10607, 10801 })
    end
    return true
end

---------------------------------------------------------------------
-- [判断] 判断是否存在可做副本
--
-- @treturn  boolean                  无可做副本返回true否则返回false
-- @usage
-- local dungeon_ok = switch_ent.dungeon()
-- if not dungeon then print_r('无可做副本') end
---------------------------------------------------------------------
function switch_ent.dungeon()
    if redis_ent['执行副本'] == 0 then
        return false
    end
    if redis_ent.read_to_ini_user_time(main_ctx:c_server_name()..'副本信息', local_player:name() .. '读取') == '' then

        dungeon_unit.open_dungeon_wnd()
        decider.sleep(2000)
        ui_unit.close_window(ui_unit.get_parent_window('IllusionDungeonEntryWindow_BP_C', true))

        decider.sleep(2000)
        redis_ent.write_sixh_ini_user(main_ctx:c_server_name()..'副本信息', local_player:name() .. '读取', 1)
    end
    if redis_ent['1封印之塔'] ~= 0 then
        if dungeon_unit.illusion_has_time(0x70) then
            return true
        end
    end
    if redis_ent['2梦幻秘境'] ~= 0 then
        if dungeon_unit.illusion_has_time(0x65) then
            return true
        end
    end
    if redis_ent['3邪灵之塔'] ~= 0 then
        if dungeon_unit.illusion_has_time(0x6F) then
            return true
        end
    end
    if redis_ent['4未知秘境'] ~= 0 then

    end
    if redis_ent['5城主秘境'] ~= 0 then

    end
    if redis_ent['6活动副本'] ~= 0 then

    end
    return false
end

---------------------------------------------------------------------
-- [判断] 获取角色活力值是否大于需求值
--
-- @treturn  boolean                  活力值高于需求值返回true否则返回false
-- @usage
-- local vitality = switch_ent.vitality()
-- if not vitality then print_r('活力值高于需求值') end
---------------------------------------------------------------------
function switch_ent.vitality()
    if redis_ent['挂机采集'] == 0 then
        if redis_ent['执行挂机'] == 1 then
            return true
        else
            return false
        end
    end
    if actor_unit.get_vitality() < redis_ent['低活力值采集(秒)'] then
        --TODO:写入组队临时加入一个false
        return false
    end
    --TODO:判断队伍中所有人的活力值都低于需求值返回false
    return true
end

------------------------------------------------------------------------------------
-- [内部] 将对象转换为字符串
--
-- @local
-- @treturn      string                     模块名称
------------------------------------------------------------------------------------
function switch_ent.__tostring()
    return this.MODULE_NAME
end

------------------------------------------------------------------------------------
-- [内部] 防止动态修改(this.READ_ONLY值控制)
--
-- @local
-- @tparam       table     t                被修改的表
-- @tparam       any       k                要修改的键
-- @tparam       any       v                要修改的值
------------------------------------------------------------------------------------
switch_ent.__newindex = function(t, k, v)
    if this.READ_ONLY then
        error('attempt to modify read-only table')
        return
    end
    rawset(t, k, v)
end

------------------------------------------------------------------------------------
-- [内部] 设置item的__index元方法指向自身
--
-- @local
------------------------------------------------------------------------------------
switch_ent.__index = switch_ent

------------------------------------------------------------------------------------
-- [构造] 创建一个新的实例
--
-- @local 
-- @tparam       table     args             可选参数，用于初始化新实例
-- @treturn      table                      新创建的实例
------------------------------------------------------------------------------------
function switch_ent:new(args)
    local new = {}
    -- 预载函数(重载脚本时)
    if this.super_preload then
        this.super_preload()
    end
    -- 将args中的键值对复制到新实例中
    if args then
        for key, val in pairs(args) do
            new[key] = val
        end
    end
    -- 设置元表
    return setmetatable(new, switch_ent)
end

-------------------------------------------------------------------------------------
-- 返回实例对象
-------------------------------------------------------------------------------------
return switch_ent:new()

-------------------------------------------------------------------------------------