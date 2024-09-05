------------------------------------------------------------------------------------
-- game/entities/actor_unt.lua
--
-- 这个模块主要是项目内物品相关功能操作。
--
-- @module      actor_unt
-- @author      admin
-- @license     MIT
-- @release     v1.0.0 - 2023-03-22
-- @copyright   2023
-- @usage
-- local actor_unt = import('game/entities/actor_unt.lua')
------------------------------------------------------------------------------------

-- 模块定义
---@class actor_unt
local actor_unt = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-03-22 - Initial release',
    -- 模块名称
    MODULE_NAME = 'actor_unt module',
    -- 只读模式
    READ_ONLY = false,
}

-- 实例对象
local this = actor_unt
-- 日志模块
local trace = trace
-- 决策模块
local decider = decider

local common_unt = import('game/entities/unit/common_unt')
------------------------------------------------------------------------------------
-- [事件] 预载函数(重载脚本)
------------------------------------------------------------------------------------
actor_unt.super_preload = function()
 --   this.delete_item = decider.run_action_wrapper('丢弃物品', this.delete_item)
 --   this.wt_open_box_by_name = decider.run_timeout_wrapper('打开箱子', this.open_box_by_name, 15)
end

------------------------------------------------------------------------------------
---获取指定范围内的npc信息
actor_unt.get_npc_info_by_pos = function(x, y, range)
    local ret_t = this.get_actor_info_by_pos(x, y, range, 2)
    local npc_num = #ret_t
    if npc_num > 1 then
        local name = ret_t[1].name
        for i = 2, npc_num do
            if npc_num[i].name == name then
                ret_t = {}
                break
            end
        end
    end
    return ret_t[1] or {}
end


------------------------------------------------------------------------------------
-- 读取范围内目标 返回table
--  --0当前角色，1玩家，2NPC, 3怪物 4采集物品
actor_unt.get_actor_info_by_pos = function(x, y, rand, actor_type)
    local r_tab_R = {}
    local actor_obj = actor_unit:new()
    local list = actor_unit.list(actor_type)
    local arg_rand = rand or 150
    for i = 1, #list do
        local obj = list[i]
        if actor_obj:init(obj) then
            local cx = actor_obj:cx()
            local cy = actor_obj:cy()
            local cz = actor_obj:cz()
            local id = actor_obj:id()
            local level = actor_obj:level()
            if common_unt.is_rang_by_point(cx, cy, x, y, arg_rand) then
                local r_tab = {}
                r_tab.obj = obj
                r_tab.id = id
                r_tab.name = actor_obj:name()
                r_tab.race = actor_obj:race()
                r_tab.hp = actor_obj:hp()
                r_tab.max_hp = actor_obj:max_hp()
                r_tab.mp = actor_obj:mp()
                r_tab.max_mp = actor_obj:max_mp()
                r_tab.direction = actor_obj:direction()
                r_tab.level = level
                r_tab.cx = cx
                r_tab.cy = cy
                r_tab.cz = cz
                r_tab.dist = actor_obj:dist()
                r_tab.is_dead = actor_obj:is_dead()
                r_tab.time = os.time()
                table.insert(r_tab_R, r_tab)
            end
        end
    end
    actor_obj:delete()
    return r_tab_R
end

------------------------------------------------------------------------------------
-- [内部] 将对象转换为字符串
--
-- @local
-- @treturn      string                     模块名称
------------------------------------------------------------------------------------
function actor_unt.__tostring()
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
actor_unt.__newindex = function(t, k, v)
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
actor_unt.__index = actor_unt

------------------------------------------------------------------------------------
-- [构造] 创建一个新的实例
--
-- @local 
-- @tparam       table     args             可选参数，用于初始化新实例
-- @treturn      table                      新创建的实例
------------------------------------------------------------------------------------
function actor_unt:new(args)
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
    return setmetatable(new, actor_unt)
end

-------------------------------------------------------------------------------------
-- 返回实例对象
-------------------------------------------------------------------------------------
return actor_unt:new()

-------------------------------------------------------------------------------------