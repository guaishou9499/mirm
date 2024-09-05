-------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @author:   admin
-- @email:    88888@qq.com
-- @date:     2022-06-30
-- @module:   gather
-- @describe: 主线任务处理
-- @version:  v1.0
--

-------------------------------------------------------------------------------------
local gather = {
    VERSION = '20211016.28',
    AUTHOR_NOTE = '-[gather module - 20211016.28]-',
    MODULE_NAME = '采集模块',
}

-- 自身模块
local this = gather
-- 配置模块
local settings = settings
-- 日志模块
local trace = trace
-- 决策模块
local decider = decider

-------------------------------------------------------------------------------------
--
-- 登陆资源
local login_res = import('game/resources/login_res')
---@type gather_res
local gather_res = import('game/resources/gather_res')
---@type switch_ent
local switch_ent = import('game/entities/switch_ent')
---@type redis_ent
local redis_ent = import('game/entities/redis_ent')
---@type common_unt
local common_unt = import('game/entities/unit/common_unt')
---@type move_ent
local move_ent = import('game/entities/move_ent')
---@type shop_ent
local shop_ent = import('game/entities/shop_ent')
---@type mail_ent
local mail_ent = import('game/entities/mail_ent')
---@type achieve_ent
local achieve_ent = import('game/entities/achieve_ent')
---@type item_unt
local item_unt = import('game/entities/unit/item_unt')
---@type avatar_ent
local avatar_ent = import('game/entities/avatar_ent')
---@type exchange_ent
local exchange_ent = import('game/entities/exchange_ent')
---@type collection_ent
local collection_ent = import('game/entities/collection_ent')
---@type shortcuts_ent
local shortcuts_ent = import('game/entities/shortcuts_ent')

-------------------------------------------------------------------------------------
-- 运行前置条件
this.eval_ifs = {
    -- [启用] 游戏状态列表
    yes_game_state = {  },
    -- [禁用] 游戏状态列表
    not_game_state = {},
    -- [启用] 配置开关列表
    yes_config = { },
    -- [禁用] 配置开关列表
    not_config = {},
    -- [时间] 模块超时设置(可选)
    time_out = 0,
    -- [其它] 特殊情况才用(可选)
    is_working = function()
        return true
        --return gather.out_gather()
    end,
    -- [其它] 功能函数条件(可选)
    is_execute = function()
        return true --game_unit.game_status() ~= 400
    end,
}

------------------------------------------------------------------------------------
-- 预载函数(重载脚本时)
gather.super_preload = function()


end



-------------------------------------------------------------------------------------
-- 预载处理
gather.preload = function()

end

-------------------------------------------------------------------------------------
-- 轮循功能入口
gather.looping = function()
    -- 获取用户设置 包装了1分钟读一次
    redis_ent.wi_get_user_info()
    --邮件
    mail_ent.wc_daily_mail()
    --见闻录和成就
    achieve_ent.wc_get_adventure()
    -- 获取采集类型信息
    local gather_type_info = collection_ent.get_gather_type_info()
    -- 判断是否跟换工具
    collection_ent.switch_tool(gather_res.TOOL[gather_type_info.gather_type].pos, gather_res.TOOL[gather_type_info.gather_type].res_id)
    -- 采集自动商店
    if shop_ent.wi_auto_shop_gather(gather_type_info.gather_type) then
        exchange_ent.wi_exchange()
    end
    -- 药品快捷键
    shortcuts_ent.set_shortcuts()
end


-------------------------------------------------------------------------------------
-- 入口函数
gather.entry = function()
    local regional, map_list, proficiency_id = collection_ent.compliant_regional()
    -- 退出距离
    local out_dist = 3000
    -- 获取当前采集等级
    local my_gather_level = actor_unit.get_proficiency_lv(proficiency_id)
    -- 切换矿点记录（次）
    this.switch_num = 0
    -- 切换频道记录（次）
    this.chick_switch_num = 0
    while decider.is_working()
    do
        ---- 执行任务
        decider.looping()
        -- 执行采矿操作
        gather.execute_gather(regional,map_list,my_gather_level,proficiency_id,out_dist)
         --适当延时处理
        decider.sleep(2500)
    end
end

--采集
function gather.execute_gather(regional,map_list,my_gather_level,proficiency_id,out_dist)
    local player_status = local_player:status()
    -- 采集状态
    if player_status == 29 or player_status == 30 then
        -- 采集时清空记录
        this.chick_switch_num = 0
        this.switch_num = 0
        -- 记录矿区信息到redis
        collection_ent.wi_set_redis_gather(regional.map_name,true)
        trace.output('采集中')
    else
        -- 不在采集地图
        if regional.map_id == actor_unit.map_id() then
            -- 超出距离移动到矿点
            if local_player:dist_xy(regional.x, regional.y) >= out_dist then
                collection_ent.move_regional(regional)
            end
            -- 攻击状态
            if player_status == 8 or player_status == 9 then
            else
                -- 记录矿区信息到redis
                collection_ent.wi_set_redis_gather(regional.map_name,false)
                -- 钓鱼/采集
                if proficiency_id == 0x6 then
                    -- 钓鱼
                    collection_ent.w_fishing(regional)
                else
                    local gather_list = collection_ent.get_can_gather_list(regional.func)
                    if not table_is_empty(gather_list) then
                        -- 采集采集物
                        collection_ent.wa_gather_item(gather_list,regional.map_id)
                    end
                end
                -- 切换频道
                if collection_ent.switch_line() then
                    move_ent.wi_switch_line()
                    collection_ent.move_regional(regional)
                end
                -- 切换矿点
                regional, map_list = collection_ent.switch_regional(regional, map_list, proficiency_id, my_gather_level)
                trace.output(string.format('等待采集[%s/120]',this.chick_switch_num))
            end
        else
            -- 移动到矿点
            collection_ent.move_regional(regional)
        end
    end
end

-------------------------------------------------------------------------------------
-- 模块超时处理
gather.on_timeout = function()
    xxmsg('。。。。。主线模块处理超时。。。。。')
end

-------------------------------------------------------------------------------------
-- 模块is_working判断
gather.out_gather = function()
    local switch = {
        ['主线判断'] = { func = function()
            return switch_ent.quest()
        end },
        ['副本判断'] = { func = function()
            return switch_ent.dungeon()
        end },
        ['挂机判断'] = { func = function()
            return switch_ent.vitality()
        end },
    }
    local ret_b = true
    for i, v in pairs(switch) do
        if v.func and v.func() then
            ret_b = false
            break
        end
    end
    return ret_b
end

-------------------------------------------------------------------------------------
-- 实例化新对象

function gather.__tostring()
    return this.MODULE_NAME
end

gather.__index = gather

function gather:new(args)
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
    return setmetatable(new, gather)
end

-------------------------------------------------------------------------------------
-- 返回对象
return gather:new()

-------------------------------------------------------------------------------------