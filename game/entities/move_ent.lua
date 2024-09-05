------------------------------------------------------------------------------------
-- game/entities/move_ent.lua
--
-- 本模块为move_ent单元
--
-- @module      move_ent
-- @author      Administrator
-- @license     MIT
-- @release     v1.0.0 - 2023-04-06
-- @copyright   2023
-- @usage
-- local move_ent = import('game/entities/move_ent.lua')
------------------------------------------------------------------------------------

-- 模块定义
---@class move_ent
local move_ent = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-04-06 - Initial release',
    -- 模块名称
    MODULE_NAME = 'move_ent module'
}

-- 自身模块
local this = move_ent
-- 框架模块
local settings = settings
local trace = trace
local decider = decider
local common = common
-- 引用模块
---@type unit
local unit = import('game/entities/unit')
---@type game_ent
local game_ent = import('game/entities/game_ent')
---@type redis_ent
local redis_ent = import('game/entities/redis_ent')
---@type map_res
local map_res = import('game/resources/map_res')
---@type login_res
local login_res = import('game/resources/login_res')
---@type item_unt
local item_unt = import('game/entities/unit/item_unt')
---@type common_unt
local common_unt = import('game/entities/unit/common_unt')
---------------------------------------------------------------------
-- [事件] 预载函数(重载脚本时)
---------------------------------------------------------------------
this.super_preload = function()

    --this.wa_move_to_obj = decider.run_action_wrapper('移动至地图', actor_unit.move_to_obj)
    --this.wa_auto_move = decider.run_action_wrapper('移动至坐标', actor_unit.auto_move)
    --地图移动(外部调用)
    move_ent.wn_move_map_xy = decider.run_normal_wrapper('自动移动', this.move_map_xy)
    -- 包装间隔60秒(外部调用)
    move_ent.wi_switch_line = decider.run_interval_wrapper('切换频道', move_ent.switch_line, 30 * 1000)
    -- [行为包装]
    move_ent.wi_teleport_map = decider.run_action_wrapper('传送地图', move_ent.teleport_map)
    move_ent.wa_teleport_to_obj = decider.run_action_wrapper('使用跳跃之牌', this.teleport_to_obj)
    move_ent.wa_transfer = decider.run_action_wrapper('传送柱传送', this.transfer)
    move_ent.wa_move_to_obj = decider.run_action_wrapper('地图移动', this.move_to_obj)
    move_ent.wa_change_channel = decider.run_action_wrapper('切换频道', this.change_channel)
    move_ent.wa_auto_move = decider.run_action_wrapper('坐标移动', this.auto_move_ex)


    this.wa_escape_for_recovery = decider.run_action_wrapper('逃跑回血', this.escape_for_recovery)
    move_ent.wc_escape_for_recovery = decider.run_condition_wrapper('逃跑复血', move_ent.wa_escape_for_recovery, function(hp_percent)
        hp_percent = hp_percent or 40
        return local_player:hp_percent() < hp_percent
    end)
end

--------------------------------------------------------------------------------
-- [行为] 移动到指定地图的x,y,z坐标(外部使用)
--
-- @static
-- @tparam      integer     map_id      地图id(nil值,默认当前地图)
-- @tparam      integer     x           x坐标(nil值,默认只移动到指定地图)
-- @tparam      integer     y           y坐标(nil值,默认只移动到指定地图)
-- @tparam      integer     z           z坐标(nil值,默认只移动到指定地图)
-- @tparam      integer     teleport_id 传送对象id(nil值,无法传送到指定对象位置)
-- @tparam      string      move_type   移动输出控制台类型(nil值,默认为'')
-- @tparam      integer     out_dis     到达位置后退出距离(nil值,默认为400)
-- @tparam      function    func        移动中调用的方法(nil值,不调用方法)
-- @usage
-- move_ent.move_map_xy(地图id,x坐标,y坐标,z坐标,传送对象id,'移动输出控制台类型',到达位置后退出距离,移动中调用的方法)
--------------------------------------------------------------------------------
move_ent.move_map_xy = function(map_id, x, y, z, teleport_id, move_type, out_dis, func)
    map_id = map_id or actor_unit:map_id()
    move_type = move_type or ''
    out_dis = out_dis or 400
    move_ent.wi_teleport_map(map_id, teleport_id, x, y)

    while decider.is_working() do
        --判断是否在地图
        if map_id == actor_unit:map_id() then
            --不存在x轴退出
            if not x then break end
            --未到达指定xy退出
            if local_player:dist_xy(x, y) < out_dis then
                return true, '成功移动到指定位置'
            else
                --存在方法执行方法
                if func then
                    func()
                end
                game_ent.close_window()
                --卡位检查
                if move_ent.move_lag() then
                    move_ent.wi_switch_line()
                end
                --移动判断
                if not local_player:is_move() and game_unit.game_status() == 400 then
                    --关闭定点，反击，自动模式
                    game_ent.wa_set_fixed_point()
                    game_ent.wa_set_counterattack()
                    game_ent.wa_set_auto_type()
                    move_ent.wa_auto_move(x, y, z,out_dis)
                end
                trace.output('移动到' .. move_type)
            end
        else
            move_ent.move_map(map_id, teleport_id, x, y, move_type, func)
        end
        decider.sleep(2000)
    end
    return true, '未能移动到指定位置'
end

--------------------------------------------------------------------------------
-- [行为] 切换频道(外部使用)
--
-- @static
-- @tparam      integer     line      频道id(nil值,默认为当前频道+1.当前频道+1不存在为1频道)
-- @usage
-- move_ent.switch_line(频道id)
--------------------------------------------------------------------------------
move_ent.switch_line = function(line)
    -- 判断当前频道
    local now_line = actor_unit.get_channel_id()
    -- 切换频道为传参频道，当传参为nil时切换频道为当前频道+1
    local switch_line = line or now_line + 1
    -- 当前频道与切换频道一致退出
    if switch_line == now_line then
        return true, '已切换到指定频道'
    end
    -- 请求频道信息 (需要延时几秒)
    actor_unit.req_channel_info()
    decider.sleep(2000)
    -- 切换频道不存在，传参不为nil退出，传参为nil切换频道为1
    if not actor_unit.is_valid_channel(switch_line) then
        if not line then
            switch_line = 1
            -- 当前频道为1退出
            if switch_line == now_line then
                return true, '已切换到频道1'
            end
        else
            return false, '指定频道不存在'
        end
    end
    local change_num = 0
    local change_time = 0
    while decider.is_working() do
        --2次切换未成功退出
        if change_num > 2 then
            break
        end
        --TODO:死亡退出
        --每30秒切换一次频道
        if os.time() - change_time > 30 then
            change_num = change_num + 1
            change_time = os.time()
            move_ent.wa_change_channel(switch_line)
        end
        if switch_line == actor_unit.get_channel_id() then
            return true, '已切换到指定频道'
        end
    end
    return false, '未能切换指定频道'
end

---------------------------------------------------------------------
-- [行为] 坐标位置移动
--
-- @tparam          integer      x              x坐标
-- @tparam          integer      y              y坐标
-- @tparam          integer      z              z坐标
-- @tparam          integer      out_dis        退出距离
-- @treturn         boolean
-- @usage
-- move_ent.auto_move(x坐标, y坐标, z坐标,退出距离)
---------------------------------------------------------------------
function move_ent.auto_move_ex(x, y, z,out_dis)
    --通过是否移动判断执行是否成功
    out_dis = out_dis or 400
    actor_unit.auto_move(x, y, z)
    for i = 1, 10 do
        if local_player:is_move() or local_player:dist_xy(x,y) < out_dis then
            return true, '移动坐标成功'
        end
        decider.sleep(500)
    end
    return false, '移动坐标失败'
end

---------------------------------------------------------------------
-- [行为] 移动到地图
--
-- @tparam          integer      map_id    地图id
-- @treturn         boolean
-- @usage
-- move_ent.move_to_obj(地图id)
---------------------------------------------------------------------
function move_ent.move_to_obj(map_id)
    --通过是否移动判断执行是否成功
    actor_unit.move_to_obj(map_id, 1000)
    for i = 1, 10 do
        if local_player:is_move() or map_id == actor_unit:map_id() then
            return true, '移动地图成功'
        end
        decider.sleep(500)
    end
    return false, '移动地图失败'
end

---------------------------------------------------------------------
-- [行为] 切换频道
--
-- @tparam          integer      switch_line    频道id
-- @treturn         boolean
-- @usage
-- move_ent.change_channel(频道id)
---------------------------------------------------------------------
function move_ent.change_channel(switch_line)
    --通过当前频道判断是否成功
    local line = actor_unit.get_channel_id()
    actor_unit.change_channel(switch_line)
    for i = 1, 10 do
        if line ~= actor_unit.get_channel_id() then
            return true, '切换频道成功'
        end
        decider.sleep(500)
    end
    return false, '切换频道失败'
end

---------------------------------------------------------------------
-- [行为] 使用跳跃之牌传送
--
-- @tparam          integer      map_id         地图id
-- @tparam          integer      teleport_id    传送点id
-- @treturn         boolean
-- @usage
-- move_ent.teleport_to_obj(地图id, 传送点id)
---------------------------------------------------------------------
function move_ent.teleport_to_obj(map_id, teleport_id)
    --通过背包重量判断是否成功
    if true then
        return false,'无效的传送命令'
    end
    local bag_weight = item_unit.get_bag_weight()
    map_unit.teleport_to_obj(map_id, teleport_id)
    for i = 1, 10 do
        if bag_weight ~= item_unit.get_bag_weight() then
            return true, '使用跳跃之牌成功'
        end
        decider.sleep(500)
    end
    return false, '使用跳跃之牌超时'
end

---------------------------------------------------------------------
-- [行为] 传送柱传送
--
-- @tparam          integer      map_transfer_id         地图传送id
-- @treturn         boolean
-- @usage
-- move_ent.transfer(地图传送id)
---------------------------------------------------------------------
function move_ent.transfer(map_transfer_id)
    --通过铜钱变化判断是否成功
    local money = item_unit.get_money_byid(2)
    game_unit.transfer(map_transfer_id)
    for i = 1, 10 do
        if money ~= item_unit.get_money_byid(2) then
            return true, '传送成功'
        end
        decider.sleep(500)
    end
    return true, '传送失败'
end

--------------------------------------------------------------------------------
-- [行为] 移动到指定地图(内部使用)
--
-- @static
-- @tparam      integer     map_id      地图id
-- @tparam      integer     teleport_id 传送对象id(nil值,无法传送到指定对象位置)
-- @tparam      integer     x           x坐标(用于判断与传送对象距离，近距离不传送)
-- @tparam      integer     y           y坐标(用于判断与传送对象距离，近距离不传送)
-- @tparam      string      move_type   移动输出控制台类型(nil值,默认为'')
-- @tparam      function    func        移动中调用的方法(nil值,不调用方法)
-- @usage
-- move_ent.move_map(地图id,传送对象id,x,y,'移动输出控制台类型',移动中调用的方法)
--------------------------------------------------------------------------------
move_ent.move_map = function(map_id, teleport_id, x, y, move_type, func)
    local ret_b = false
    local ret_s = '未能到达指定地图'
    move_type = move_type or ''
    while decider.is_working() do
        --TODO:死亡判断
        if map_id == actor_unit:map_id() then
            ret_b = true
            ret_s = '已到达指定地图'
            break
        end
        --执行传入方法
        if func and func() then end
        game_ent.close_window()
        if move_ent.move_lag() and move_ent.wi_switch_line() then
        end
        --判断是否移动
        if not local_player:is_move() and game_unit.game_status() == 400 then
            --关闭定点，反击，自动模式
            game_ent.wa_set_fixed_point()
            game_ent.wa_set_counterattack()
            game_ent.wa_set_auto_type()
            move_ent.wa_move_to_obj(map_id)
        end
        trace.output('移动到' .. move_type..'地图')
        decider.sleep(2000)
    end
    return ret_b, ret_s
end

--------------------------------------------------------------------------------
-- [行为] 跳跃之牌传送到地图(内部使用)
--
-- @static
-- @tparam      integer     map_id      地图id
-- @tparam      integer     teleport_id 传送对象id(nil值,无法传送到指定对象位置)
-- @tparam      integer     x           x坐标(用于判断与传送对象距离，近距离不传送)
-- @tparam      integer     y           y坐标(用于判断与传送对象距离，近距离不传送)
-- @usage
-- move_ent.teleport_map(地图id,传送对象id,x,y)
--------------------------------------------------------------------------------
move_ent.teleport_map = function(map_id, teleport_id, x, y)
    local ret_b = false
    if redis_ent['使用传送'] == 0 then
        return ret_b, '用户设置不使用传送'
    end
    --当前地图与传送地图一致退出
    if teleport_id then
        if x and map_id == actor_unit:map_id() and local_player:dist_xy(x, y) < 50000 then
            return ret_b, '近距离不传送'
        end
        if item_unt.get_num_by_red_id(0x0000102B) <= 0 then
            return ret_b, '不存在跳跃之牌'
        end
    else
        if map_id == actor_unit:map_id() then
            return ret_b, '已在当前地图'
        end
    end
    local map_transfer_id = game_unit.get_map_transfer_id(map_id)
    --传送柱未激活退出
    if not actor_unit.teleport_is_active(map_transfer_id) then
        return ret_b, '传送地未激活传送柱'
    end
    if game_unit.game_status_ex() ~= login_res.STATUS_IN_GAME then
        return ret_b, '不在游戏内部'
    end
    local last_map_id = actor_unit:map_id()
    local last_x, last_y = local_player:cx(), local_player:cy()
    --铜钱传送或传送牌传送
    if teleport_id then
        ret_b = move_ent.wa_teleport_to_obj(map_id, teleport_id)
    else
        ret_b = move_ent.wa_transfer(map_transfer_id)
    end
    for i = 1, 30 do
        if teleport_id then
            if local_player:dist_xy(last_x, last_y) > 1000 or last_map_id ~= actor_unit:map_id() then
                break
            elseif not ret_b then
                return ret_b
            end
        elseif last_map_id ~= actor_unit:map_id() then
            break
        elseif not ret_b then
            return ret_b
        end
        decider.sleep(500)
    end
    return ret_b
end

--------------------------------------------------------------------------------
-- [条件] 判断是否卡位置(内部使用)
--
-- @static
-- @tparam      integer      num    在同一位置范围的次数
-- @tparam      integer      dis    在同一位置的范围
-- @treturn     boolean
-- @usage
-- if move_ent.move_lag() then main_ctx:end_game() end
--------------------------------------------------------------------------------
move_ent.move_lag = function(num, dis)
    local ret_b = false
    num = num or 120
    dis = dis or 500
    --记录在同一位置次数
    if not this.check_auto then
        this.check_auto = 0
    end
    if not this.last_x or this.last_x == 0 then
        --记录坐标
        this.last_x = local_player:cx()
        this.last_y = local_player:cy()
    else
        --位置不变记录次数+1，变化位置记录清空
        if local_player:dist_xy(this.last_x, this.last_y) < dis then
            this.check_auto = this.check_auto + 1
        else
            this.last_x = 0
            this.last_y = 0
            this.check_auto = 0
        end
        local status = local_player:status()
        if status == 9 or status == 8 then
            this.last_x = 0
            this.last_y = 0
            this.check_auto = 0
        end
        -- 在同一位置的次数超过次数num 返回true
        if this.check_auto > num then
            ret_b = true
            this.check_auto = 0
        end
    end
    return ret_b
end

---------------------------------------------------------------------
-- [行为] 原地躲避
--
-- @tparam      number      x           X
-- @tparam      number      y           Y
-- @tparam      number      z           Z
-- @tparam      number      radius      半径
---------------------------------------------------------------------
move_ent.evasion_for_recovery = function(radius)
    local ret = false
    local x, y, z, map_id = local_player:cx(), local_player:cy(), local_player:cz(), actor_unit.map_id()
    local points = common_unt.get_point_on_circle(x, y, 999, 4)
    --decider.sleep(1000)
    for k, v in pairs(points) do
        local x, y = table.unpack(v)
        local times = 0
        decider.sleep(1000)
        while decider.is_working() do
            --game_ent.set_counterattack_mode(0)
            game_ent.set_auto_mode(0)
            trace.log_debug(local_player:status() .. '-' .. times)
            if times > 6 then
                break
            end
            if local_player:dist_xy(x, y) < 100 then
                break
            end
            if not common_unt.is_in_list(local_player:status(), { 14, 15 }) then
                --this.wa_auto_move(x, y, z, map_id)
                unit.wa_auto_move(x, y, z, map_id)
            end
            times = times + 1
            decider.sleep(1000)
        end
    end
    --game_ent.set_counterattack_mode(1)
    return ret
end

------------------------------------------------------------------------------------
-- [行为] 逃跑复血
--
-- @treturn     boolean     复血是否成功
------------------------------------------------------------------------------------
move_ent.escape_for_recovery = function(v)
    local hp_percent = v or 40
    local run_time = os.time()
    local out_dis = 400
    local map_id = actor_unit:map_id()
    local x,y,z = move_ent.get_escape_pos(map_id)
    if x == 0 then
        return false, '没有添加坐标'
    end
    while decider.is_working() do

        if game_ent.is_player_dead() then
            return false, '主角已死亡'
        end
        if actor_unit.map_type() == 2 then
            move_ent.evasion_for_recovery()
        end
        if local_player:hp_percent() > hp_percent then
            break
        end
        if os.time() - run_time > 60 then
            return false, '逃跑超时'
        end
        if map_id ~= actor_unit:map_id() then
            return false, '不在逃跑地图'
        end
        trace.output (string.format('逃跑回血%0.0f/100',local_player:hp_percent()))
        if not local_player:is_move() and local_player:dist_xy(x,y) > out_dis then
            game_ent.wa_set_fixed_point()
            game_ent.wa_set_counterattack()
            game_ent.wa_set_auto_type()
            move_ent.wa_auto_move(x, y, z,out_dis)
        end
        decider.sleep(1000)
    end
    game_ent.set_counterattack_mode(1)
    return true
end

-- 获取逃跑坐标
move_ent.get_escape_pos = function(map_id)
    if map_res.ESCAPE_POS[map_id] then
        return map_res.ESCAPE_POS[map_id].x,map_res.ESCAPE_POS[map_id].y,map_res.ESCAPE_POS[map_id].z
    end
    local x, y, z = 0, 0, 0
    local teleport_obj = actor_unit.cur_map_teleport_ptr()
    if teleport_obj ~= 0 then
        local actor_obj = actor_unit:new()
        if actor_obj:init(teleport_obj) then
            local transfer_id = game_unit.get_map_transfer_id(map_id)
            if transfer_id ~= 0 then
                x = actor_obj:cx()
                y = actor_obj:cy()
                z = actor_obj:cz()
            end
        end
        actor_obj:delete()
    end
    return x, y, z
end

---------------------------------------------------------------------
-- [内部] 将对象转换为字符串
--
-- @local
-- @treturn      string                     模块名称
---------------------------------------------------------------------
function move_ent.__tostring()
    return this.MODULE_NAME
end

move_ent.__index = move_ent

---------------------------------------------------------------------
-- [构造] 创建一个新的实例
--
-- @local
-- @tparam       table     args             可选参数，用于初始化新实例
-- @treturn      table                      新创建的实例
---------------------------------------------------------------------
function move_ent:new(args)
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

    return setmetatable(new, move_ent)
end

---------------------------------------------------------------------
-- 返回实例对象
return move_ent:new()
---------------------------------------------------------------------