-------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @author:   admin
-- @email:    88888@qq.com
-- @date:     2022-06-30
-- @module:   quest
-- @describe: 主线任务处理
-- @version:  v1.0
--

-------------------------------------------------------------------------------------
local quest = {
    VERSION = '20211016.28',
    AUTHOR_NOTE = "-[quest module - 20211016.28]-",
    MODULE_NAME = '主线模块',
}

-- 自身模块
local this = quest
-- 配置模块
local settings = settings
-- 日志模块
local trace = trace
-- 决策模块
local decider = decider

-------------------------------------------------------------------------------------
---@type unit
local unit = import('game/entities/unit')
---@type login_res
local login_res = import('game/resources/login_res')
---@type quest_ent
local quest_ent = import('game/entities/quest_ent')
---@type game_ent
local game_ent = import('game/entities/game_ent')
---@type actor_ent
local actor_ent = import('game/entities/actor_ent')
---@type move_ent
local move_ent = import('game/entities/move_ent')
---@type mail_ent
local mail_ent = import('game/entities/mail_ent')
---@type equip_ent
local equip_ent = import('game/entities/equip_ent')
---@type skill_ent
local skill_ent = import('game/entities/skill_ent')
---@type shop_ent
local shop_ent = import('game/entities/shop_ent')
---@type shortcuts_ent
local shortcuts_ent = import('game/entities/shortcuts_ent')
---@type pet_ent
local pet_ent = import('game/entities/pet_ent')
---@type vehicle_ent
local vehicle_ent = import('game/entities/vehicle_ent')
---@type avatar_ent
local avatar_ent = import('game/entities/avatar_ent')
---@type achieve_ent
local achieve_ent = import('game/entities/achieve_ent')

---@type switch_ent
local switch_ent = import('game/entities/switch_ent')

-------------------------------------------------------------------------------------
-- 运行前置条件
this.eval_ifs = {
    -- [启用] 游戏状态列表
    yes_game_state = { login_res.STATUS_IN_GAME, login_res.STATUS_LOADING_MAP },
    -- [禁用] 游戏状态列表
    not_game_state = {},
    -- [启用] 配置开关列表
    yes_config = {},
    -- [禁用] 配置开关列表
    not_config = {},
    -- [时间] 模块超时设置(可选)
    time_out = 0,
    -- [其它] 特殊情况才用(可选)
    is_working = function()
        return this.working_condition()
    end,
    -- [其它] 功能函数条件(可选)
    is_execute = function()
        -- 角色死亡判断
        return not game_ent.is_player_dead()
    end,
}

---------------------------------------------------------------------
-- 模块运行特殊条件
this.working_condition = function()
    local ret = false
    --剧情内返回真
    if actor_unit.map_type() == 2 then
        return true
    end
    -- 判断主线是否断档
    return true --switch_ent.quest()
end

------------------------------------------------------------------------------------
-- 预载函数(重载脚本时)
quest.super_preload = function()

end

-------------------------------------------------------------------------------------
-- 模块协程
this.aux_coroutine = function()

end

-------------------------------------------------------------------------------------
-- 预载处理
quest.preload = function()

end

-- 卸载处理
quest.unload = function()

end

-- 定时调用入口
quest.on_timer = function(timer_id)
    xxmsg('quest.on_timer -> ' .. timer_id)
end
-------------------------------------------------------------------------------------
-- entry前置处理函数
quest.pre_enter = function()

    unit.wa_set_auto_pick_item(1)
end

-- entry离开处理函数
quest.post_enter = function()

end
-------------------------------------------------------------------------------------
-- 轮循功能入口
quest.looping = function()
    -- 关闭睡眠模式
    game_ent.wi_set_sleep_mode()
    --自动复活
    actor_ent.wc_revive_player(1)
    --关闭窗口
    game_ent.close_window()
    actor_ent.wi_active_teleport()
    if local_player:level() >= 4 then
        --卡位检查
        if move_ent.move_lag() then
            move_ent.switch_line()
        end
        mail_ent.wc_daily_mail()
        -- 回复复活经验
        actor_ent.wc_recovery_exp()
        -- 逃跑回血
        move_ent.wc_escape_for_recovery(60)
        -- 成就
        achieve_ent.wc_get_adventure()
        -- 化身
        avatar_ent.wc_set_avatar()
        -- 自动装备
        equip_ent.wi_auto_equip()
        -- 自动技能
        skill_ent.wi_auto_skill()
        -- 自动宠物
        pet_ent.wi_auto_pet()
        -- 自动坐骑
        vehicle_ent.wi_auto_vehicle()
        if actor_unit.map_type() ~= 2 then
            -- 自动商店
            local buy_type = '主线'
            if local_player:level() < 18 then
                buy_type = '主线前期'
            end
            shop_ent.wi_auto_shop_dungeon(buy_type)
            -- 激活传送柱
            actor_ent.wi_active_teleport()
        end
        -- 间隔设置快捷键
        shortcuts_ent.wi_set_shortcuts()
    end
    --关闭窗口
    game_ent.close_window()
end

-------------------------------------------------------------------------------------
-- 入口函数
quest.entry = function()
    while decider.is_working()
    do
        -- 执行轮循任务
        decider.looping()
        -- 自动完成主线任务
        quest_ent.do_quest()
        -- 适当延时处理
        decider.sleep(500)
    end
end

-------------------------------------------------------------------------------------
-- 模块超时处理
quest.on_timeout = function()
    xxmsg('。。。。。主线模块处理超时。。。。。')
end

-------------------------------------------------------------------------------------
-- 实例化新对象

function quest.__tostring()
    return this.MODULE_NAME
end

quest.__index = quest

function quest:new(args)
    local new = { }

    -- 预载函数(重载脚本时)
    if this.super_preload then
        this.super_preload()
    end

    if args then
        for key, val in pairs(args) do
            new[key] = val
        end
    end

    -- 设置元表
    return setmetatable(new, quest)
end

-------------------------------------------------------------------------------------
-- 返回对象
return quest:new()

-------------------------------------------------------------------------------------