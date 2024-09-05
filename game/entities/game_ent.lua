------------------------------------------------------------------------------------
-- game/entities/game_ent.lua
--
-- 本模块为game_ent单元
--
-- @module      game_ent
-- @author      Administrator
-- @license     MIT
-- @release     v1.0.0 - 2023-04-07
-- @copyright   2023
-- @usage
-- local game_ent = import('game/entities/game_ent.lua')
------------------------------------------------------------------------------------

-- 模块定义
---@class game_ent
local game_ent = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-04-07 - Initial release',
    -- 模块名称
    MODULE_NAME = 'game_ent module'
}

-- 自身模块
local this = game_ent
-- 框架模块
local settings = settings
local trace = trace
local decider = decider
local common = common
-- 引用模块
---@type unit
local unit = import('game/entities/unit')
---@type game_res
local game_res = import('game/resources/game_res')
---@type ui_res
local ui_res = import('game/resources/ui_res')
---@type common_unt
local common_unt = import('game/entities/unit/common_unt')
---------------------------------------------------------------------
-- [事件] 预载函数(重载脚本时)
---------------------------------------------------------------------
this.super_preload = function()

    game_ent.wc_close_window = decider.run_normal_wrapper('关闭所有窗口', this.close_window)

    game_ent.wa_close_window_by_name = decider.run_action_wrapper('关闭指定窗口', this.close_window_by_name)
    game_ent.wa_open_win_by_name = decider.run_action_wrapper('打开指定窗口', this.open_win_by_name)

    game_ent.wa_set_fixed_point = decider.run_action_wrapper('设置定点模式', this.set_fixed_point)
    game_ent.wa_set_counterattack = decider.run_action_wrapper('设置自动反击', this.set_counterattack)
    game_ent.wa_set_auto_type = decider.run_action_wrapper('设置自动类型', this.set_auto_type)

    ---------------------------
    --this.wo_set_pick_mode = decider.run_once_wrapper('一次设置捡物模式', this.set_pick_mode)


--[失败] {主线模块} {wa_set_auto_pick_item} (0x1)


    this.wa_set_sleep_mode = decider.run_action_wrapper('设置睡眠模式', this.set_sleep_mode)
    this.wi_set_sleep_mode = decider.run_interval_wrapper('间隔睡眠模式', this.wa_set_sleep_mode, 1000 * 60 * 2)

    this.wi_detect_abnormal = decider.run_interval_wrapper('间隔检测异常', this.detect_abnormal, 1000 * 30)
end

------------------------------------------------------------------------------------
-- [行为] 打开指定窗口
--
-- @tparam      string     name     窗口名
-- @treturn     boolean
-- @usage
-- game_ent.open_win_by_name(窗口名)
------------------------------------------------------------------------------------
game_ent.open_win_by_name = function(name)
    while decider.is_working() do
        if not ui_res.WIN[name] then
            return false, '未添加' .. name .. '窗口资源'
        end
        if ui_unit.get_parent_window(ui_res.WIN[name].win_name, true) ~= 0 then
            return false, '已在' .. name .. '窗口'
        end
        if not ui_res.WIN[name].win_open then
            return false, '窗口' .. name .. '没有打开指令'
        end
        --通过读取当前窗口不为0判断窗口打开
        ui_res.WIN[name].win_open()
        for i = 1, 10 do
            if ui_unit.get_parent_window(ui_res.WIN[name].win_name, true) ~= 0 then
                decider.sleep(1000)
                -- 关闭教学窗口
                if quest_unit.get_cur_tutorial_id() ~= 0 then
                    quest_unit.pass_tutorial()
                end
                return true, '打开' .. name .. '窗口'
            end
            decider.sleep(500)
        end
        decider.sleep(500)
    end
    return false, '打开' .. name .. '窗口失败'
end

------------------------------------------------------------------------------------
-- [行为] 关闭所有打开窗口
--
-- @usage
-- game_ent.close_window()
------------------------------------------------------------------------------------
game_ent.close_window = function()
    if quest_unit.get_cur_tutorial_id() ~= 0 then
        quest_unit.pass_tutorial()
    end
    for i, v in pairs(ui_res.WIN) do
        --判断窗口是否打开
        if ui_unit.get_parent_window(v.win_name, true) ~= 0 then
            if v.win_close then
                v.win_close()
            else
                if i ~= '死亡' then
                    game_ent.close_window_by_name(v.win_name)
                end
            end
        end
    end
end

------------------------------------------------------------------------------------
-- [行为] 关闭指定窗口
--
-- @tparam      string     win_name     窗口名
-- @treturn     boolean
-- @usage
-- game_ent.close_window_by_name(窗口名)
------------------------------------------------------------------------------------
game_ent.close_window_by_name = function(win_name)
    --通过窗口是否判断是否成功
    if ui_unit.get_parent_window(win_name, true) == 0 then
        return true, '窗口未打开'
    end
    while decider.is_working() do
        ui_unit.close_window(ui_unit.get_parent_window(win_name, true))
        for j = 1, 30 do
            if ui_unit.get_parent_window(win_name, true) == 0 then
                return true, '窗口关闭成功'
            end
            decider.sleep(500)
        end
        decider.sleep(2000)
    end
    return false, '窗口关闭超时'
end

------------------------------------------------------------------------------------
-- [行为] 设置定点模式
--
-- @tparam      boolean     fixed     是否定点
-- @treturn     boolean
-- @usage
-- game_ent.set_fixed_point(是否定点)
------------------------------------------------------------------------------------
game_ent.set_fixed_point = function(fixed)
    fixed = fixed or 0
    if fixed == 0 then
        if actor_unit.is_fixed_point() then
            actor_unit.set_fixed_point(0)
            for i = 1, 30 do
                if not actor_unit.is_fixed_point() then
                    return true
                end
                decider.sleep(500)
            end
            return false, '关闭定点超时'
        else
            return false, '已不是定点状态'
        end
    elseif fixed == 1 then
        if not actor_unit.is_fixed_point() then
            actor_unit.set_fixed_point(1)
            for i = 1, 30 do
                if actor_unit.is_fixed_point() then
                    return true
                end
                decider.sleep(500)
            end
            return false, '打开定点超时'
        else
            return false, '已是定点状态'
        end
    end
    return false, '无效的定点设置'..tostring(fixed)
end

------------------------------------------------------------------------------------
-- [行为] 设置自动反击
--
-- @tparam      boolean     fixed     是否反击
-- @treturn     boolean
-- @usage
-- game_ent.set_counterattack(是否反击)
------------------------------------------------------------------------------------
game_ent.set_counterattack = function(fixed)
    fixed = fixed or 0
    if fixed == 0 then
        if actor_unit.is_counterattack() then
            actor_unit.set_counterattack(0)
            for i = 1, 30 do
                if not actor_unit.is_counterattack() then
                    return true
                end
                decider.sleep(500)
            end
            return false, '关闭反击超时'
        else
            return false, '已关闭反击'
        end
    elseif fixed == 1 then
        if not actor_unit.is_counterattack() then
            actor_unit.set_counterattack(1)
            for i = 1, 30 do
                if actor_unit.is_counterattack() then
                    return true
                end
                decider.sleep(500)
            end
            return false, '打开反击超时'
        else
            return false, '已打开反击'
        end
    end
    return false, '无效的反击设置'..tostring(fixed)
end

------------------------------------------------------------------------------------
-- [行为] 设置自动类型
--
-- @tparam      integer     auto_type     自动类型
-- @treturn     boolean
-- @usage
-- game_ent.set_auto_type(自动类型)
------------------------------------------------------------------------------------
game_ent.set_auto_type = function(auto_type)
    auto_type = auto_type or -1
    if auto_type == actor_unit.get_auto_type() then
        return true, '已是设置自动类型'
    end
    actor_unit.set_auto_type(auto_type)
    for i = 1, 30 do
        if auto_type == actor_unit.get_auto_type() then
            return true
        end
        decider.sleep(500)
    end
    return false,'设置自动类型超时'
end

---------------------------------------------------------------------
-- [行为] 设置睡眠模式
--
-- @tparam      number      mode        0 退出睡眠 1 进入睡眠模式
-- @treturn     boolean     是否成功
---------------------------------------------------------------------
this.set_sleep_mode = function(mode)
    mode = mode or 0
    if mode == 0 then
        if game_unit.is_in_sleep_mode() then
            game_unit.set_sleep_mode(0)
            for i = 1, 30 do
                if not game_unit.is_in_sleep_mode() then
                    decider.sleep(1000)
                    return true
                end
                decider.sleep(500)
            end
            return false, '关闭睡眠模式超时'
        else
            return false, '已关闭睡眠模式'
        end
    elseif mode == 1 then
        if not game_unit.is_in_sleep_mode() then
            game_unit.set_sleep_mode(1)
            for i = 1, 30 do
                if game_unit.is_in_sleep_mode() then
                    decider.sleep(1000)
                    return true
                end
                decider.sleep(500)
            end
            return false, '打开睡眠模式超时'
        else
            return false, '已打开睡眠模式'
        end
    end
    return false, '无效的睡眠模式设置'..tostring(mode)
end

---------------------------------------------------------------------
-- [行为] 设置反击模式
--
-- @tparam      number      mode        0 关闭 1开启
-- @treturn     boolean     是否成功
---------------------------------------------------------------------
this.set_counterattack_mode = function(mode)
    local ret = false
    if mode == 0 then
        if actor_unit.is_counterattack() then
            --ret = actor_unit.set_counterattack(0)
            ret = unit.wa_set_counterattack(0)
        else
            ret = true
        end
    elseif mode == 1 then
        if not actor_unit.is_counterattack() then
            --ret = actor_unit.set_counterattack(1)
            ret = unit.wa_set_counterattack(1)
        else
            ret = true
        end
    end
    return ret
end

---------------------------------------------------------------------
-- [行为] 设置自动模式
--
-- @tparam      number      mode        0 关闭 1开启
-- @treturn     boolean     是否成功
---------------------------------------------------------------------
this.set_auto_mode = function(mode)
    local ret = false
    if mode == 0 then
        if actor_unit.get_auto_type() ~= -1 or quest_unit.get_cur_auto_quest_id() ~= 0 then
            --ret = actor_unit.set_auto_type(-1)
            ret = unit.wa_set_auto_type(-1)
        end
    elseif mode == 1 then
        -- todo: 待完成
    end
    return ret
end

---------------------------------------------------------------------
-- [行为] 设置捡物模式
--
-- @tparam      number      mode        0 主角宠物 1宠物 2不获取
-- @treturn     boolean     是否成功
---------------------------------------------------------------------
this.set_pick_mode = function(mode)
    local ret = false
    if pet_unit.get_summon_pet_id() == 0 then
        return ret
    end
    if mode == 0 then
        --game_unit.set_auto_pick_item(0)
        unit.wa_set_auto_pick_item(0)
    elseif mode == 1 then
        --game_unit.set_auto_pick_item(1)
        unit.wa_set_auto_pick_item(1)
    elseif mode == 2 then
        --game_unit.set_auto_pick_item(2)
        unit.wa_set_auto_pick_item(2)
    end
    return ret
end

---------------------------------------------------------------------
-- [行为] 检测主角异常
---------------------------------------------------------------------
this.abnormal_info = { ['卡点'] = { time = 0, times = 0, info = { 0, 0, 0 } }
, ['主线'] = { time = 0, times = 0, info = { 0, 0, 0 } }
}
this.detect_abnormal = function(type)
    local ret = false
    type = type or '卡点'
    if this.abnormal_info[type].time == 0 then
        this.abnormal_info[type].time = os.time()
        this.abnormal_info[type].info = { local_player:cx(), local_player:cy(), actor_unit.map_id() }
    end
    --print_t(this.abnormal_info[type])
    --trace.log_warn('--------------', trace.curr_module)
    if common_unt.is_in_list(local_player:status(), game_res.player_running)
            or common_unt.is_in_list(local_player:status(), game_res.player_still) and quest_unit.get_cur_tutorial_id() ~= 0
    then
        local cur_x, cur_y, cur_map = local_player:cx(), local_player:cy(), actor_unit.map_id()
        local last_x, last_y, last_map = table.unpack(this.abnormal_info[type].info)
        if local_player:dist_xy(last_x, last_y) < 400 and cur_map == last_map then
            trace.log_warn('需要关注主角状态' .. this.abnormal_info[type].times)
            this.abnormal_info[type].times = this.abnormal_info[type].times + 1
        else
            this.abnormal_info[type].times = 0
            this.abnormal_info[type].info = { cur_x, cur_y, cur_map }
        end
    end
    if this.abnormal_info[type].times >= 3 then
        this.abnormal_info[type].times = 0
        game_ent.set_sleep_mode(0)
        ret = true
    end
    return ret
end

------------------------------------------------------------------------------------
-- 判断角色是否死亡
--
------------------------------------------------------------------------------------
this.is_player_dead = function()
    local ret = false
    if local_player:is_dead() and ui_unit.get_parent_window(ui_res.WIN['死亡'].win_name,true) ~= 0 then
        ret = true
    end
    return ret
end
---------------------------------------------------------------------
-- [内部] 将对象转换为字符串
--
-- @local
-- @treturn      string                     模块名称
---------------------------------------------------------------------
function game_ent.__tostring()
    return this.MODULE_NAME
end

game_ent.__index = game_ent

---------------------------------------------------------------------
-- [构造] 创建一个新的实例
--
-- @local
-- @tparam       table     args             可选参数，用于初始化新实例
-- @treturn      table                      新创建的实例
---------------------------------------------------------------------
function game_ent:new(args)
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

    return setmetatable(new, game_ent)
end

---------------------------------------------------------------------
-- 返回实例对象
return game_ent:new()
---------------------------------------------------------------------