------------------------------------------------------------------------------------
-- game/entities/login_ent.lua
--
-- 这个模块主要是游戏登录操作。
--
-- @module      login_ent
-- @author      admin
-- @license     MIT
-- @release     v1.0.0 - 2023-03-22
-- @copyright   2023
-- @usage
-- local login_ent = import('game/entities/login_ent.lua')
------------------------------------------------------------------------------------
-- 模块定义
--- @class login_ent
local login_ent = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-03-22 - Initial release',
    -- 模块名称
    MODULE_NAME = 'login_ent module',
    -- 只读模式
    READ_ONLY = false,
}

-- 自身模块
local this = login_ent
-- 框架模块
local trace = trace
local decider = decider
local common = common
-- 引用模块
---@type unit
local unit = import('game/entities/unit')
---@type login_res
local login_res = import('game/resources/login_res')

------------------------------------------------------------------------------------
-- [事件] 预载函数(重载脚本)
------------------------------------------------------------------------------------
login_ent.super_preload = function()
    this.start_game = decider.run_action_wrapper('开始游戏', this.start_game)
    this.enter_select_character = decider.run_action_wrapper('选择大区进入游戏', this.enter_select_character)
    this.wait_for_login_queue = decider.run_action_wrapper('等待登陆排队', this.wait_for_login_queue)
    this.open_third_login = decider.run_action_wrapper('打开谷歌登陆', this.open_third_login)
    this.wait_for_google_login = decider.run_action_wrapper('等待谷歌登陆', this.wait_for_google_login)
    this.accept_user_agreement = decider.run_action_wrapper('接受协议', this.accept_user_agreement)
    this.create_character = decider.run_action_wrapper('创建角色', this.create_character)
    this.enter_game = decider.run_action_wrapper('进入游戏', this.enter_game)
end

---------------------------------------------------------------------------------
-- 开始游戏登录
-- 功能：
--     点击开始游戏按钮开始游戏登录；循环10次间隔3秒检测是否开始按钮已加载；
--     如果加载则点击开始游戏登录
-- 返回值：
--     - result boolean
--         - true  表示开始游戏成功
--         - false 表示开始游戏失败
login_ent.start_game = function()
    local result = false
    for i = 1, 10 do
        local status = game_unit.game_status_ex()
        --trace.log_debug(status, ui_unit.btn_is_complated(0x18012B360))
        if status ~= login_res.STATUS_INTRO_PAGE then
            result = true
            break
        end
        if ui_unit.btn_is_complated(0x18012B360) then
          --  314*277
            --if game_unit.in_start_game_ok() then
            ui_unit.debug(0)
            decider.sleep(2000)
            --game_unit.title_start_game()
            --result = unit.wa_btn_click(0x18012B360)
            if ui_unit.btn_click(0x18012B360) then
                result = true
                break
            end
            main_unit.enable_mouse_hook(true)
            decider.sleep(1000)
            main_ctx:lclick(315,277)
            --main_ctx:lclick(311,303)
            -- 311*303
            decider.sleep(500)
            main_ctx:reset_pos()
            main_unit.enable_mouse_hook(false)


            --unit.wa_title_start_game()
            decider.sleep(3000)
        else
            trace.log_trace('正在加载开始游戏按钮[' .. i .. ']')
        end
        decider.sleep(3000)
    end
    return result
end

--------------------------------------------------------------------------------------------------------
-- 选择大区进入游戏 验证资格
-- 功能：
--     选择大区后进入游戏；循环10次间隔5秒检测是否排队成功进入游戏
-- 返回值：
--     - result boolean
--         - true  表示进入游戏成功
--         - false 表示进入游戏失败
login_ent.enter_select_character = function()
    local result = false
    for i = 1, 10 do
        local login_server_name = main_ctx:c_server_name()
        local server_id = login_unit.get_server_id_byname(login_res.server_name[login_server_name], true)
        if server_id ~= 0 then
            login_unit.lobby_login(server_id, true)
            --unit.wa_lobby_login(server_id, true)
            this.wait_for_login_queue()
            result = true
            break
        else
            trace.log_trace('正在加载大区数据[' .. i .. ']')
        end
        decider.sleep(5000)
    end
    return result
end

------------------------------------------------------------------------------------
-- 等待登录排队结束
-- 功能：
--     在登录过程中检查并等待排队结束。在排队过程中，每隔 2.5 秒检查一次排队
--     状态。当不再处于等待状态时，函数返回 true；否则返回 false。
-- 返回值：
--     - result boolean
--         - true  表示排队结束
--         - false 表示退出
login_ent.wait_for_login_queue = function()
    local result = false
    decider.sleep(math.random(2500, 5000))
    while decider.is_working() do
        --if not login_unit.is_waiting_game() then
        if game_unit.game_status_ex() ~= login_res.STATUS_LOGIN_PAGE then
            result = true
            break
        end
        trace.log_trace('正在等待登陆排队'--[[, login_unit.get_waiting_value()]])
        decider.sleep(2500)
    end
    return result
end

------------------------------------------------------------------------------------
-- 打开第三方登陆
-- 功能：
--     等待3秒后，检查当前游戏状态是否为第三方登陆页面。如果是，则执行打开
--     谷歌登陆并等待5秒。
-- 参数：
--     无
-- 返回值：
--     - result boolean
--         - true  表示打开第三方登陆成功
--         - false 表示打开第三方登陆失败
login_ent.open_third_login = function()
    local result = false
    decider.sleep(3000)
    local status = game_unit.game_status_ex()
    if status == login_res.STATUS_THIRDPARTY_LOGIN_PAGE then
        login_unit.open_third_login(0)
        decider.sleep(5000)
        result = true
    end
    return result
end

------------------------------------------------------------------------------------
-- 等待Google登录结束
-- 功能：
--   等待Google登录结束。在登录过程中，等待一定时间（随机范围为2500~5000毫秒）,
--   每隔一段时间（2500毫秒）检查一次登录页面状态。
--   当页面状态不再是Google登录页面时,函数返回true;否则返回false。
--   最后等待不超过6秒 避免账号第一次接受协议 0x20状态进入选择服务器页面
--   该状态会在几秒后自动切换至0x420 之后不会现有此步骤
-- 参数：
--   无
-- 返回值：
--   -result boolean
--   -true 表示Google登录结束
--   -false 表示等待超时
login_ent.wait_for_google_login = function()
    local result = false
    decider.sleep(math.random(2500, 5000))
    while decider.is_working()
    do
        local status = game_unit.game_status_ex()
        if status ~= login_res.STATUS_GOOGLE_LOGIN_PAGE then
            result = true
            break
        end
        decider.sleep(2500)
    end
    for i = 1, 6 do
        local status = game_unit.game_status_ex()
        if status == login_res.STATUS_TERMS_AGREEMENT_PAGE then
            break
        end
        decider.sleep(1000)
    end
    return result
end

------------------------------------------------------------------------------------
-- 选择接受协议
-- 功能：
--   执行选择接受协议动作
--   每隔一段时间（2000毫秒）检查一次页面状态
--   当页面状态不再是接受协议页面时,函数返回true;否则返回false。
-- 参数：
--   无
-- 返回值：
--   -result boolean
--   -true 表示接受协议完成
--   -false 表示接受协议失败
login_ent.accept_user_agreement = function()
    local result = false
    login_unit.terms_agreement_action(0)
    decider.sleep(1000)
    login_unit.terms_agreement_action(1)
    decider.sleep(3000)
    main_ctx:set_reg_time(os.time())
    decider.sleep(1000)
    for i = 1, 10 do
        local status = game_unit.game_status_ex()
        if status ~= login_res.STATUS_TERMS_AGREEMENT_PAGE then
            result = true
            break
        end
        decider.sleep(2000)
    end
    return result
end

------------------------------------------------------------------------------------
-- 创建角色
-- 功能：
--   创建角色
--   每隔一段时间（2500毫秒）检查一次页面状态
--   当页面状态进入角色选择或者已进入游戏时返回true；如果超时30秒则返回false
--   进入游戏状态STATUS_IN_GAME  sleep is_working会导致判断结束返回false 日志显示为创建角色失败
-- 参数：
--   无
-- 返回值：
--   -result boolean
--   -true 表示创建角色成功
--   -false 表示创建角色超时失败
login_ent.create_character = function()
    local result = false
    local job_id = this.get_create_job_id()
    if job_id ~= 0 then
        login_unit.create_char('', job_id)
        decider.sleep(2000)
        result = true
        if not this.wait_for_join_status(30, login_res.STATUS_CHARACTER_SELECT, login_res.STATUS_IN_GAME) then
            result = false
        end
    else
        error('创建角色取职业ID失败')
    end
    return result
end

------------------------------------------------------------------------------------
-- 通过职业名称取职业ID
-- 参数：
--   无
-- 返回值：
--    -result string 职业名
login_ent.get_create_job_id = function()
    local result = 0
    local job_name = main_ctx:c_job()
    if job_name == '战士' then
        result = 0xC
    elseif job_name == '术士' then
        result = 0x15
    elseif job_name == '道士' then
        result = 0x1F
    end
    return result
end

------------------------------------------------------------------------------------
-- 等待游戏进入指定状态
-- 功能：
--     持续检查当前游戏状态，直到状态进入指定状态列表中的一项。每隔2.5秒检查一
--     次游戏状态。当游戏状态进入指定状态列表中的一项时，函数返回 true；否则返
--     回 false。
-- 参数：
-- ... 一个或多个游戏状态码，用于表示指定状态列表。
-- 返回值：
--     - result boolean
--         - true  表示等待成功
--         - false 表示等待失败
login_ent.wait_for_join_status = function(wait_time, ...)
    local result = false
    local status_list = { ... }
    local start_time = os.time()
    while decider.is_working()
    do
        if os.time() - start_time > wait_time then
            break
        end
        local status = game_unit.game_status_ex()
        for _, v in ipairs(status_list)
        do
            if status ~= v then
                result = true
                break
            end
        end
        -- 验证等待是否成功
        if result then
            break
        end
        decider.sleep(2500)
    end
    return result
end

------------------------------------------------------------------------------------
-- 选择角色进入游戏
-- 功能：
--   默认选择序号1角色进入角色
--   每隔一段时间（2500毫秒）检查一次页面状态
--   当页面状态进入游戏时返回true；如果超时30秒则返回false
-- 参数：
--   无
-- 返回值：
--   - result boolean
--      - true  表示进入游戏成功
--      - false 表示进入游戏失败
login_ent.enter_game = function()
    local result = false
    local enter_role_id = this.get_role_id_byidx(1)
    if enter_role_id ~= 0 then
        login_unit.enter_game(enter_role_id)
        result = true
        if not this.wait_for_join_status(30, login_res.STATUS_IN_GAME) then
            result = false
        end
    else
        error('取登陆游戏角色id失败')
    end
    return result
end

------------------------------------------------------------------------------------
-- 通过序号获取角色ID
login_ent.get_role_id_byidx = function(idx)
    local result = 0
    local list = role_unit.list()
    local role_obj = role_unit:new()
    if idx <= #list then
        if role_obj:init(list[idx]) then
            result = role_obj:id()
        end
    end
    role_obj:delete()
    return result
end

------------------------------------------------------------------------------------
-- 实例化新对象

function login_ent.__tostring()
    return this.MODULE_NAME
end

login_ent.__index = login_ent

function login_ent:new(args)
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
    return setmetatable(new, login_ent)
end

-------------------------------------------------------------------------------------
-- 返回对象
return login_ent:new()

-------------------------------------------------------------------------------------