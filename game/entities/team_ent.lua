------------------------------------------------------------------------------------
-- game/entities/team_ent.lua
--
-- 本模块为team_ent单元
--
-- @module      team_ent
-- @author      Administrator
-- @license     MIT
-- @release     v1.0.0 - 2023-04-04
-- @copyright   2023
-- @usage
-- local team_ent = import('game/entities/team_ent.lua')
------------------------------------------------------------------------------------

-- 模块定义
---@class team_ent
local team_ent = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-04-04 - Initial release',
    -- 模块名称
    MODULE_NAME = 'team_ent module'
}

-- 自身模块
local this = team_ent
-- 框架模块
local settings = settings
local trace = trace
local decider = decider
local common = common

---@type redis_ent
local redis_ent = import('game/entities/redis_ent')
---@type switch_ent
local switch_ent = import('game/entities/switch_ent')
---@type common_unt
local common_unt = import('game/entities/unit/common_unt')

-- 引用模块
---@type unit
local unit = import('game/entities/unit')
---@type pet_res
local pet_res = import('game/resources/pet_res')
---------------------------------------------------------------------
-- [事件] 预载函数(重载脚本时)
---------------------------------------------------------------------
this.super_preload = function()

end

-- 通过场景判断自己是否达到组队要求
function team_ent.conditions(case)
    case = case or '主线'
    local player_level = local_player:level()
    if case == '主线' then
        if player_level >= redis_ent['结束主线等级'] then
            return false
        end
    elseif case == '副本' then
        if not switch_ent.dungeon() then
            return false
        end
    elseif case == '挂机' then

    end
    return true
end

--组队  case 场景
function team_ent.team_party(case, cur_main_quest)
    local ret_team_info, ret_team_idx, ret_my_idx = {}, 0, 0

    if not team_ent.conditions(case) then
        return ret_team_info, ret_team_idx, ret_my_idx
    end
    --获取我的信息
    local my_info = team_ent.get_my_info_table()
    --将自己的信息写入到redis中，返回队伍序号，我的序号，需组队人数
    local team_idx, my_idx, team_nums = team_ent.set_my_info_team_redis(my_info,case)
    if team_idx == 0 then
        return  ret_team_info, ret_team_idx, ret_my_idx
    end
    --获取队伍信息和自己的信息
    local team_info_list, my_data = team_ent.get_team_data(team_idx, team_nums,case)
    if case == '主线' then
        team_ent.set_need_help_task(team_idx, my_idx, cur_main_quest,case)
    end
    --判断redis队伍人数是否达到队伍要求人数
    if team_nums == #team_info_list then
        --判断自己是否redis队长
        if team_ent.is_team_leader(team_info_list, my_data, team_idx,case) then
            --队长邀请队员进入队伍
            team_ent.leader_invite_member(team_info_list)
        else
            --队员等待队长邀请组队
            team_ent.member_wait_team(team_idx, my_idx, my_data)
        end
        local game_team_num = party_unit.list()
        --如果游戏队伍人数等于redis队伍人数退出
        if #game_team_num == team_nums then
            return team_info_list, team_idx, my_idx
        else
            trace.output(case .. '组队队员人数不足' .. #game_team_num .. '/' .. team_nums )
        end
    else
        trace.output(case .. '配置队员人数不足' .. team_nums .. '/' .. #team_info_list)

    end
    return ret_team_info, ret_team_idx, ret_my_idx
end

--------------------------------------------------------------------------------
-- [读取] 获取当前角色信息表
--
-- @static
-- @treturn     t                           角色信息，角色信息包括
-- @tfield[t]   integer     ['机器ID']       机器ID
-- @tfield[t]   string      ['角色ID']       角色ID
-- @tfield[t]   string      ['角色名字']      角色名字
-- @tfield[t]   integer     ['角色等级']      角色等级
-- @tfield[t]   string      ['角色职业']      角色职业
-- @tfield[t]   integer     ['写入时间']      写入时间
-- @usage
-- local my_info = team_ent.get_my_info_table()
-- print_r(my_info)
--------------------------------------------------------------------------------
team_ent.get_my_info_table = function()
    local my_info = {
        ['角色ID'] = tostring(local_player:id()),
        ['角色名'] = local_player:name(),
        ['角色等级'] = local_player:level(),
        ['角色职业'] = local_player:race(),
        ['写入时间'] = os.time(), --通过活跃时间 判断当前Redis记录是否失效
    }
    return my_info
end

--获取职业信息表
function team_ent.get_team_job_list()
    local job_list = {}
    local job_info = common_unt.split(redis_ent['组队职业分配'], ',')
    for i = 1, #job_info do
        local job = common_unt.split(job_info[i], '_')
        for j = 1, job[2] do
            job_list[#job_list + 1] = job[1]
        end
    end
    return job_list
end

--------------------------------------------------------------------------------
-- [写入] 将角色信息写入队伍redis
--
-- @static
-- @tparam      tabel       data_r          角色信息表
-- @treturn     integer     team_idx        队伍编号
-- @treturn     integer     my_idx          队员编号
-- @treturn     integer     team_nums       队员总数
-- @usage
-- local team_idx, my_idx, team_nums = team_ent.set_my_info_team_redis()
--------------------------------------------------------------------------------
team_ent.set_my_info_team_redis = function(data_r,case)
    local team_list = team_ent.get_team_job_list()
    local team_nums = #team_list --队伍人数
    local team_idx = 0 --队伍编号
    local my_idx = 0 --队员编号
    local my_name = data_r['角色名']
    local my_id = data_r['角色ID']
    local my_race = data_r['角色职业']
    if my_name == '' then
        return team_idx, my_idx, team_nums
    end
    --遍历100次获取可存入redis的位置
    for i = 1, 100 do
        for j = 1, team_nums do
            local PATH = '传奇M:内置数据:组队信息:'..main_ctx:c_server_name()..':'..case..':' .. i .. '-' .. j
            local data = redis_ent.get_json_redis(PATH)
            if not table_is_empty(data) then
                --判断是否自己占用的位置
                if data['角色ID'] == my_id and data['角色名'] == my_name then
                    team_idx = i
                    my_idx = j
                    break
                end
            else
                --判断是否符合队伍要求职业
                if team_list[j] == '其他' or team_list[j] == my_race then
                    team_idx = i
                    my_idx = j
                    break
                end
            end
        end
        if team_idx > 0 then
            data_r['队伍位置'] = my_idx
            local PATH = '传奇M:内置数据:组队信息:'..main_ctx:c_server_name()..':'..case..':' .. team_idx .. '-' .. my_idx
            redis_ent.add_changes_redis(PATH, data_r) --写入角色信息到组队redis
            break
        end
    end
    return team_idx, my_idx, team_nums
end

--------------------------------------------------------------------------------
-- [读取] 获取redis中队伍队员信息
--
-- @static
-- @tparam      integer     team_idx        队伍编号
-- @treturn     table       team_info_list  所有队员信息
-- @treturn     table       my_data         自己的信息
-- @usage
-- local team_info_list, my_data = team_ent.get_team_data(队伍编号)
-- 打印所有队员信息
-- for i = 1, #team_info_list do
-- print_r(team_info_list[i])
-- end
-- 打印自己的信息
-- print_r(my_data)
--------------------------------------------------------------------------------
team_ent.get_team_data = function(team_idx, team_nums,case)
    local team_info_list = {}
    local my_data = {}
    local my_id = tostring(local_player:id())
    for i = 1, team_nums do
        local PATH = '传奇M:内置数据:组队信息:'..main_ctx:c_server_name()..':'..case..':' .. team_idx .. '-' .. i
        local data = redis_ent.get_json_redis(PATH)
        if not table_is_empty(data) then
            if data['角色ID'] == my_id then
                my_data = data
            end
            table.insert(team_info_list, data)
        end
    end
    return team_info_list, my_data
end

--------------------------------------------------------------------------------
-- [写入] 将当前任务信息写入到组队redis
--
-- @static
-- @tparam      integer     team_idx        队伍编号
-- @tparam      integer     my_idx          队员编号
-- @tparam      table       cur_main_quest  当前任务信息
-- @treturn     boolean                     是否写入成功
-- @usage
-- local ret_b = team_ent.team_ent.set_need_help_task(队伍编号, 队员编号, 当前任务信息)
--------------------------------------------------------------------------------
team_ent.set_need_help_task = function(team_idx, my_idx, cur_main_quest,case)
    local data = {
        ['主线信息'] = {
            ['主线ID'] = cur_main_quest.id,
            ['主线地图ID'] = cur_main_quest.map_id
        }
    }
    local PATH = '传奇M:内置数据:组队信息:'..main_ctx:c_server_name()..':'..case..':' .. team_idx .. '-' .. my_idx
    --向redis指定路径下的数据增加信息
    return redis_ent.add_changes_redis(PATH, data)
end

--------------------------------------------------------------------------------
-- [条件] 判断自己是否为组队redis队长
--
-- @static
-- @tparam      integer     team_idx        队伍编号
-- @tparam      integer     my_idx          队员编号
-- @treturn     boolean                     是否为组队redis队长
-- @usage
-- local ret_b = team_ent.is_team_leader(队伍编号, 队员编号)
--------------------------------------------------------------------------------
team_ent.is_team_leader = function(team_info_list, my_data, team_idx,case)
    local my_name = local_player:name()
    if not my_data['队长名'] then
        --判断职业是否可作为队长
        if team_ent.can_do_leader(my_data['角色职业']) then
            --将队长信息写入所有同队队员信息下
            for i = 1, #team_info_list do

                local data = { ['队长名'] = my_name, }
                local PATH = '传奇M:内置数据:组队信息:'..main_ctx:c_server_name()..':'..case..':' .. team_idx .. '-' .. i
                redis_ent.add_changes_redis(PATH, data)
            end
            --打印所有队员信息
            team_info_list, my_data = team_ent.get_team_data(team_idx,#team_info_list,case)
        end
    end
    if my_data['队长名'] == my_name then
        return true
    end
    return false
end

--------------------------------------------------------------------------------
-- [行为] 队长邀请队员进入队伍
--
-- @static
-- @tparam      table     team_data        所有队员信息
-- @usage
-- team_ent.leader_invite_member(所有队员信息)
--------------------------------------------------------------------------------
team_ent.leader_invite_member = function(team_data)
    --有队伍但队长不是自己，退出队伍
    if party_unit.has_party() and party_unit.get_leader_id() ~= local_player:id() then
        party_unit.leave()
    end
    --没有队伍,创建队伍
    if not party_unit.has_party() then
        party_unit.create(local_player:name())
    end
    --有队伍且队长为自己
    if party_unit.has_party() and party_unit.get_leader_id() == local_player:id() then
        --邀请其他队员组队
        local my_name = local_player:name()
        for i = 1, #team_data do
            if is_terminated() then
                break
            end
            local member_info = team_data[i]
            local name = member_info['角色名']
            local id = member_info['角色ID']
            local idx = member_info['队伍位置']
            local write_time = member_info['写入时间']
            local invited = true
            --不邀请自己
            if my_name == name then
                invited = false
            end
            --在游戏内的队伍不邀请
            if team_ent.in_team_by_name(name) then
                invited = false
            end
            --写入时间小于10秒不邀请
            if os.time() - write_time > 10 then
                invited = false
            end
            if invited then
                party_unit.invite(tonumber(id))
            end
        end
    end
end


--判断是否在游戏队伍中
team_ent.in_team_by_name = function(name)
    local ret_b = false
    local party_obj = party_unit:new()
    local list = party_unit.list()
    for i = 1, #list do
        local obj = list[i]
        if party_obj:init(obj) then
            if name == party_obj:name() then
                ret_b = true
                break
            end
        end
    end

    party_obj:delete()
    return ret_b
end


--------------------------------------------------------------------------------
-- [行为] 队员等待队长邀请组队
--
-- @static
-- @tparam      integer     team_idx        队伍编号
-- @tparam      integer     my_idx          队员编号
-- @tparam      table       team_data       自己的信息
-- @usage
-- team_ent.member_wait_team(队伍编号,队员编号,自己的信息)
--------------------------------------------------------------------------------
team_ent.member_wait_team = function(team_idx, my_idx, my_data)
    if party_unit.has_party() then
        local leader_name = my_data["队长名"]
        local out_team = true
        if leader_name then
            if this.in_team_by_name(leader_name) then
                out_team = false
            end
        end
        if out_team then
            party_unit.leave()
        end
    else
        xxmsg('等待队长邀请')
    end
end

--------------------------------------------------------------------------------
-- [条件] 判断是否在队伍中
--
-- @static
-- @treturn     boolean                     是否在队伍中
-- @usage
-- local ret_b = team_ent.has_team()
--------------------------------------------------------------------------------
function team_ent.has_team()

end

--------------------------------------------------------------------------------
-- [行为] 退出队伍
--
-- @usage
-- team_ent.out_team()
--------------------------------------------------------------------------------
function team_ent.out_team()

end

--------------------------------------------------------------------------------
-- [读取] 获取队长id
--
-- @static
-- @treturn     integer                     队伍队长id
-- @usage
-- local leader_id = team_ent.get_leader_id()
--------------------------------------------------------------------------------
function team_ent.get_leader_id()

end

--------------------------------------------------------------------------------
-- [条件] 判断角色职业是否能作为队长
--
-- @static
-- @tparam      integer     job         角色职业
-- @treturn     boolean                 是否能作为队长
-- @usage
-- local ret_b = team_ent.can_do_leader()
--------------------------------------------------------------------------------
function team_ent.can_do_leader(job)

    local job_list = common_unt.split(redis_ent['队长职业'], ',')
    for i = 1, #job_list do
        if job == job_list[i] or job_list[i] == '其他' then
            return true
        end
    end
    return false
end


























---------------------------------------------------------------------
-- [内部] 将对象转换为字符串
--
-- @local
-- @treturn      string                     模块名称
---------------------------------------------------------------------
function team_ent.__tostring()
    return this.MODULE_NAME
end

team_ent.__index = team_ent

---------------------------------------------------------------------
-- [构造] 创建一个新的实例
--
-- @local
-- @tparam       table     args             可选参数，用于初始化新实例
-- @treturn      table                      新创建的实例
---------------------------------------------------------------------
function team_ent:new(args)
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

    return setmetatable(new, team_ent)
end

---------------------------------------------------------------------
-- 返回实例对象
return team_ent:new()
---------------------------------------------------------------------