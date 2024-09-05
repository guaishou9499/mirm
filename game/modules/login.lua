-------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @author:   admin
-- @email:    88888@qq.com
-- @date:     2022-06-30
-- @module:   login
-- @describe: 登陆处理
-- @version:  v1.0
--

-------------------------------------------------------------------------------------
--
local login = {
    VERSION = '20211016.28',
    AUTHOR_NOTE = "-[login module - 20211016.28]-",
    MODULE_NAME = '登陆模块',
}

-- 自身模块
local this = login
-- 配置模块
local settings = settings
-- 日志模块
local trace = trace
-- 决策模块
local decider = decider

-------------------------------------------------------------------------------------
---@type login_res
local login_res = import('game/resources/login_res')
local login_ent = import('game/entities/login_ent')
local config = import('game/entities/config')
local redis_ent = import('game/entities/redis_ent')
---@type common_unt
local common_unt = import('game/entities/unit/common_unt')
-------------------------------------------------------------------------------------
-- 运行前置条件
this.eval_ifs = {
    -- [启用] 游戏状态列表
    yes_game_state = {},
    -- [禁用] 游戏状态列表
    not_game_state = { login_res.STATUS_IN_GAME },
    -- [启用] 配置开关列表
    yes_config = {},
    -- [禁用] 配置开关列表
    not_config = {},
    -- [时间] 模块超时设置(可选)
    time_out = 0,
    -- [其它] 特殊情况才用(可选)
    is_working = function()
        return true
    end,
    -- [其它] 功能函数条件(可选)
    is_execute = function()
        return true
    end,
}

-- 轮循函数列表
this.poll_functions = {}

------------------------------------------------------------------------------------
-- 预载函数(重载脚本时)
this.super_preload = function()

end

-------------------------------------------------------------------------------------
-- 预载处理
this.preload = function()
    redis_ent.connect_redis()
    redis_ent.get_user_info()
end

-------------------------------------------------------------------------------------
-- entry前置处理函数
this.pre_enter = function()
    settings.log_level = 0
    settings.log_type_channel = 3
end

-------------------------------------------------------------------------------------
-- 轮循功能入口
this.looping = function()
    -- 效验登陆异常
    this.check_login_error()
end

-------------------------------------------------------------------------------------
-- 功能入口函数
this.entry = function()
    local action_list = {
        [login_res.STATUS_INTRO_PAGE] = login_ent.start_game,
        [login_res.STATUS_THIRDPARTY_LOGIN_PAGE] = login_ent.open_third_login,
        [login_res.STATUS_GOOGLE_LOGIN_PAGE] = login_ent.wait_for_google_login,
        [login_res.STATUS_TERMS_AGREEMENT_PAGE] = login_ent.accept_user_agreement,
        [login_res.STATUS_SERVER_SELECT_PAGE] = login_ent.enter_select_character,
        [login_res.STATUS_LOGIN_PAGE] = login_ent.enter_select_character,
        [login_res.STATUS_CREATE_CHARACTER] = login_ent.create_character,
        [login_res.STATUS_CHARACTER_SELECT] = login_ent.enter_game,
    }

    decider.sleep(2000)
    while decider.is_working()
    do
        -- 执行轮循任务
        decider.looping()
        -- 根据状态执行相应功能
        local status = game_unit.game_status_ex()
        local action = action_list[status]
        if action ~= nil then
            action()
        end
        -- 适当延时(切片)
        decider.sleep(2500)
    end
end

-------------------------------------------------------------------------------------
-- 模块超时处理
this.on_timeout = function()
    xxmsg('。。。。。登陆模块处理超时。。。。。')
end

-------------------------------------------------------------------------------------
-- 定时调用入口
this.on_timer = function(timer_id)
    --xxmsg('login.on_timer -> '..timer_id)
end

-------------------------------------------------------------------------------------
-- entry离开处理函数
this.post_enter = function()

end

-------------------------------------------------------------------------------------
-- 卸载处理
this.unload = function()
    --xxmsg('login.unload')
end

-------------------------------------------------------------------------------------
-- 效验登陆异常
this.check_login_error = function()

end

-------------------------------------------------------------------------------------
-- 实例化新对象

function login.__tostring()
    return this.MODULE_NAME
end

login.__index = login

function login:new(args)
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
    return setmetatable(new, login)
end

-------------------------------------------------------------------------------------
-- 返回对象
return login:new()

-------------------------------------------------------------------------------------