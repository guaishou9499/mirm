------------------------------------------------------------------------------------
-- game/entities/actor_ent
--
-- 本模块为角色模块
--
-- @module      actor
-- @author      admin
-- @license     MIT
-- @release     v1.0.0 - 2023-03-22
-- @copyright   2023
------------------------------------------------------------------------------------

-- 模块定义
---@class actor_ent
local actor_ent = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-03-22 - Initial release',
    -- 模块名称
    MODULE_NAME = "actor_ent module",
}

-- 自身模块
local this = actor_ent
-- 框架模块
local settings = settings
local trace = trace
local decider = decider
local common = common
-- 引用模块
---@type unit
local unit = import('game/entities/unit')
---@type move_ent
local move_ent = import('game/entities/move_ent')
---@type common_unt
local common_unt = import('game/entities/unit/common_unt')
---@type game_ent
local game_ent = import('game/entities/game_ent')
------------------------------------------------------------------------------------
-- [事件] 预载函数(重载脚本时)
this.super_preload = function()
    -- 前置条件包装
    this.wc_recovery_exp = decider.run_condition_wrapper('恢复经验', this.recovery_exp, function()
        -- 免费次数或恢复经验次数为0不执行
        if actor_unit.get_lost_exp_num() == 0 or actor_unit.get_recovery_num() == 0 then
            return false
        end
        return true
    end)
    this.wc_revive_player = decider.run_condition_wrapper('复活模块', this.revive_player, function()
        -- 未死亡不执行
        return game_ent.is_player_dead()
    end)


    this.wt_active_teleport = decider.run_timeout_wrapper('激活传送柱', this.active_teleport, 120)
    this.wi_active_teleport = decider.run_interval_wrapper('检查激活传送柱', this.wt_active_teleport,20 * 1000)
end

--------------------------------------------------------------------------------
-- [行为] 复活
--
-- @tparam          integer           mode            复活模式
-- @treturn         boolean
-- @usage
-- local ret = actor_ent.revive_man(复活模式)
--------------------------------------------------------------------------------
actor_ent.revive_man = function(mode)
    -- 通过hp判断是否复活成功
    if local_player:hp_percent() > 0 then
        return false, '角色未死亡'
    end
    actor_unit.revive_man(mode)
    for i = 1, 30 do
        if local_player:hp_percent() > 0 then
            decider.sleep(500)
            return true, '复活成功'
        end
        decider.sleep(500)
    end
    return false, '复活超时'
end

--------------------------------------------------------------------------------
-- [行为] 恢复经验
--
-- @treturn         boolean
-- @usage
-- local ret = actor_ent.recovery_exp()
--------------------------------------------------------------------------------
this.recovery_exp = function()
    local ret = false
    -- 获取丢失交易数量
    local lost_exp_num = actor_unit.get_lost_exp_num()
    -- 获取免费恢复数量
    local free_recovery_num = actor_unit.get_recovery_num()
    local tab = {}
    -- 遍历丢失经验按丢失比例排序
    for i = 0, lost_exp_num - 1 do
        local id = actor_unit.get_lost_exp_id_byidx(i)
        local exp = actor_unit.get_lost_exp_byidx(i)
        tab[#tab + 1] = { id = id, exp = exp }
    end
    table.sort(tab, function(a, b)
        return a.exp > b.exp
    end)
    local recovery_num = lost_exp_num > free_recovery_num and free_recovery_num or lost_exp_num
    for i = 1, recovery_num do
        ret = unit.wa_recovery_exp(tab[i].id)
        trace.log_info('恢复经验值', tab[i].exp)
        decider.sleep(1000)
    end
    return ret
end

--------------------------------------------------------------------------------
-- [条件] 激活传送柱
--
-- @treturn      boolean
-- @usage
-- local ret = actor_ent.active_teleport()
--------------------------------------------------------------------------------
this.active_teleport = function()
    local ret = false
    local obj = actor_unit.cur_map_teleport_ptr()
    local actor_obj = actor_unit:new()
    if actor_obj:init(obj) then
        local res_id = actor_obj:res_id()
        if not actor_unit.teleport_is_active(res_id)  then
            move_ent.wn_move_map_xy(nil, actor_obj:cx(), actor_obj:cy(), actor_obj:cz(), nil, '激活传送柱', 1000)
            -- 激活传送柱
            unit.wa_active_teleport(obj)
            decider.sleep(1000)
            ret = true
        end
    end
    actor_obj:delete()
    return ret
end

--------------------------------------------------------------------------------
-- [条件] 判断是否切换矿点
--
-- @tparam          integer           mode            复活模式
-- @treturn         boolean
-- @usage
-- local ret = actor_ent.revive_player(复活模式)
--------------------------------------------------------------------------------
actor_ent.revive_player = function(mode)
    local ret = false
    local revive_time = os.time()
    while decider.is_working() do
        -- 复活角色
        actor_ent.revive_man(mode)
        -- 角色生命值大于80%退出
        if local_player:hp_percent() >= 80 then
            break
        end
        trace.output(string.format('复活恢复中%0.0f', local_player:hp_percent()))
        -- 复活超时退出
        if os.time() - revive_time >= 60 then
            return false, '复活超时'
        end
        decider.sleep(1000)
    end
    return ret
end

------------------------------------------------------------------------------------
function actor_ent.__tostring()
    return this.MODULE_NAME
end

actor_ent.__index = actor_ent

function actor_ent:new(args)
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

    return setmetatable(new, actor_ent)
end

return actor_ent:new()