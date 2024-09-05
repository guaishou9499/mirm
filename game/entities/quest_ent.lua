------------------------------------------------------------------------------------
-- game/entities/quest_ent
--
-- 本模块为任务模块
--
-- @module      quest
-- @author      admin
-- @license     MIT
-- @release     v1.0.0 - 2023-03-22
-- @copyright   2023
------------------------------------------------------------------------------------

-- 模块定义
---@class quest_ent
local quest_ent = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-03-22 - Initial release',
    -- 模块名称
    MODULE_NAME = "quest module",

    auto_check = {}
}

-- 自身模块
local this = quest_ent
-- 框架模块
local settings = settings
local trace = trace
local decider = decider
-- 引用模块
---@type unit
local unit = import('game/entities/unit')
---@type quest_res
local quest_res = import('game/resources/quest_res')
---@type redis_ent
local redis_ent = import('game/entities/redis_ent')
---@type team_ent
local team_ent = import('game/entities/team_ent')
---@type move_ent
local move_ent = import('game/entities/move_ent')
---@type game_ent
local game_ent = import('game/entities/game_ent')
---@type common_unt
local common_unt = import('game/entities/unit/common_unt')
------------------------------------------------------------------------------------
-- [事件] 预载函数(重载脚本时)
this.super_preload = function()
    quest_ent.wc_auto_quest = decider.run_action_wrapper('自动任务', this.auto_quest, function(quest_id)
        return not quest_unit.is_cur_auto_quest(quest_id)
    end)


end

------------------------------------------------------------------------------------
-- [读取] 获取当前任务信息
--
-- @tparam   string    ...      可变参数，需要获取的字段
-- @treturn  table              含需要获取字段的表及分支ID表 或者 空表
------------------------------------------------------------------------------------
this.get_main_quest_info = function(fields)
    local ret = {}
    local cur_map_id = actor_unit.map_id()
    if common_unt.is_in_list(cur_map_id, quest_res.scenario_maps) then
        ret = this.get_quest_info({ { 'status', 3, unit.lt }, { 'map_id', cur_map_id, unit.eq }, }, fields)
    else
        ret = this.get_quest_info({ { 'status', 3, unit.lt }, { 'main_type', 0, unit.eq } }, fields)
    end
    return ret
end

------------------------------------------------------------------------------------
-- [读取] 通过任务ID获取当前任务信息
--
-- @tparam   integer    id      integer      任务ID
-- @tparam   string     ...     可变参数，需要获取的字段
-- @treturn  table              含需要获取字段的表及分支ID表 或者 空表
-- @usage
-- local info = this.get_quest_info_by_id(branches[i], 'is_finish')
-- print_r(info)
------------------------------------------------------------------------------------
this.get_quest_info_by_id = function(id, fields)
    return this.get_quest_info({ { 'id', id, unit.eq } }, fields)
end

------------------------------------------------------------------------------------
-- [读取] 通过任务任意字段获取当前任务信息
--
-- @tparam   any        value   值
-- @tparam   string     field   键
-- @tparam   string     ...     可变参数，需要获取的字段
-- @treturn  table              含需要获取字段的表 或者 空表
-- @usage
-- local info = this.get_quest_info('quest_name', name, 'is_finish')
-- print_r(info)
------------------------------------------------------------------------------------
this.get_quest_info = function(cond, fields)
    --return this.get_quest_info_ex(quest_unit, cond, ...)
    return unit.get_info(quest_unit, cond, fields, false, {})
end

------------------------------------------------------------------------------------
-- [行为] 执行任务
--
-- @todo 部分任务前有剧情介绍 此时自动任务会出现菜单bug 没有识别条件 采取配置任务ID的方式解决
------------------------------------------------------------------------------------
this.do_quest = function()
    --获取任务信息
    local quest_info = this.get_main_quest_info({ 'id', 'branch_num', 'name','map_id','tar_type' })
    if table_is_empty(quest_info[1]) then
        return false
    end
    if not quest_ent.sync_quest(quest_info[1]) then
        return false
    end
    local quest_obj = quest_info[1].obj
    local quest_id, quest_name = quest_info[1].id, quest_info[1].name
    local branch_num = quest_info[1].branch_num
    quest_id = quest_ent.quset_branch_judgment(quest_obj, branch_num, quest_id)
    if not this.auto_check[quest_id] then
        this.auto_check[quest_id] = {
            check = 0,
            time = 0,
            start_time = os.time(),
        }
    end
    trace.output(string.format('自动任务[%s]时长[%s]', quest_id, os.time() - this.auto_check[quest_id].start_time))
    quest_ent.wc_auto_quest(quest_id)
end

------------------------------------------------------------------------------------
-- [行为] 点击自动任务
--
-- @treturn      boolean
-- @usage
-- mail_ent.auto_quest()
------------------------------------------------------------------------------------
quest_ent.auto_quest = function(quest_id)
    if quest_unit.is_cur_auto_quest(quest_id) then
        return false, '当前任务为自动任务'
    end
    if this.auto_check[quest_id] then
        if os.time() - this.auto_check[quest_id].time < 30 then
            return false, '当前任务30s内点击过'
        end
        --if this.auto_check[quest_id].check > 10 then
        --    return false, '当前任务点击次数过多'
        --end
    end
    quest_unit.auto_quest(quest_id)
    decider.sleep(500)
    for i = 1, 30 do
        if quest_unit.is_cur_auto_quest(quest_id) then
            if not this.auto_check[quest_id] then
                this.auto_check[quest_id] = {
                    check = 1,
                    time = os.time(),
                }
            end
            return true, '成功点击自动任务'
        end
        decider.sleep(500)
    end
    return false, '点击自动任务超时'
end

-----------------------------------------------------------------------------------------------------------
--执行分支任务判断
quest_ent.quset_branch_judgment = function(obj, branch_num, quest_id)
    if branch_num > 1 then
        local quest_obj = quest_unit:new()
        if quest_obj:init(obj) then
            for j = 0, branch_num - 1 do
                local branch_id = quest_obj:branch_id(j)
                local branch_info = this.get_quest_info_by_id(branch_id, { 'is_finish' })
                if not table_is_empty(branch_info) then
                    if branch_info[1].is_finish == 0 then
                        quest_id = branch_id
                        break
                    end
                end
            end
        end
    end
    return quest_id
end

-----------------------------------------------------------------------------------------------------------
--同步任务
quest_ent.sync_quest = function(quest_info)
    if common_unt.is_in_list(quest_info.map_id, quest_res.scenario_maps) then
        return true
    end
    if quest_info.tar_type ~= 2 and quest_info.tar_type ~= 1 and quest_info.branch_num >= 2 then
        return true
    end
    -- 组队
    local team_info,team_idx,my_idx = team_ent.team_party('主线', quest_info)
    if table_is_empty(team_info) then
       return false
    end
    local help_info = quest_ent.get_need_help_info(team_info)
    if table_is_empty(help_info) then
        return false
    end
    if help_info["角色名"] == local_player:name() then
        quest_ent.up_need_help_info(quest_info, team_idx, my_idx,'主线')
        return true
    else
        quest_ent.help_others(help_info)
        return false
    end
    return false
end

-------------------------------------------------------------------------------------------------------
-- 获取需要帮助的队友信息
quest_ent.get_need_help_info = function(ret)
    local help_info = {}
    local min_task = 999999
    for i = 1, #ret do
        if ret[i]["主线信息"] then
            local task_id = ret[i]["主线信息"]["主线ID"]
            if task_id > 0 and task_id < min_task then
                min_task = task_id
                help_info = ret[i]
            end
        end
    end
    return help_info
end

-- 修改自己的帮助信息
quest_ent.up_need_help_info = function(my_quset_info, team_idx, my_idx,case)
    local pos_data = {}
    if actor_unit.map_id() == my_quset_info.map_id then
        pos_data = {
            ['帮助位置'] = {
                ["主线线路"] = actor_unit.get_channel_id(),
                map_id = actor_unit.map_id(),
                x = local_player:cx(),
                y = local_player:cy(),
                z = local_player:cz()
            } }
    end
    local PATH = '传奇M:内置数据:组队信息:'..main_ctx:c_server_name()..':'..case..':' .. team_idx .. '-' .. my_idx
    redis_ent.add_changes_redis(PATH, pos_data)
end

-- 帮助队员
quest_ent.help_others = function(help_info)
    local help_pos = help_info['帮助位置']
    if not table_is_empty(help_pos) then
        local line = help_pos['主线线路']
        local map_id = help_pos.map_id
        local x, y, z = help_pos.x, help_pos.y, help_pos.z
        if line ~= actor_unit.get_channel_id() then
            move_ent.change_channel(line)
        end
        if actor_unit.map_id() ~= map_id then
            move_ent.wn_move_map_xy(map_id, x, y, z)
        end
        if local_player:dist_xy(x, y) > 1500 then
            move_ent.wn_move_map_xy(map_id, x, y, z)
        end
        if quest_unit.get_cur_auto_quest_id() ~= 0 then
            game_ent.set_auto_type(0)
        end
        trace.log_debug(string.format('帮助任务-[%s]', help_info["主线信息"]["主线ID"]))
        if actor_unit.get_auto_type() ~= 0 then
            game_ent.set_auto_type(0)
        end
    end
end

----------------------------对象-----------------------------------------
function quest_ent.__tostring()
    return this.MODULE_NAME
end

quest_ent.__index = quest_ent

function quest_ent:new(args)
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

    return setmetatable(new, quest_ent)
end

return quest_ent:new()