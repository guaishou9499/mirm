------------------------------------------------------------------------------------
-- game/entities/avatar_ent.lua
--
-- 这个模块主要是项目内物品相关功能操作。
--
-- @module      avatar_ent
-- @author      admin
-- @license     MIT
-- @release     v1.0.0 - 2023-03-22
-- @copyright   2023
-- @usage
-- local avatar_ent = import('game/entities/avatar_ent.lua')
------------------------------------------------------------------------------------

-- 模块定义
---@class avatar_ent
local avatar_ent = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-03-22 - Initial release',
    -- 模块名称
    MODULE_NAME = 'avatar_ent module',
    -- 只读模式
    READ_ONLY = false,
}

-- 实例对象
local this = avatar_ent
-- 日志模块
local trace = trace
-- 决策模块
local decider = decider

---@type avatar_res
local avatar_res = import('game/resources/avatar_res')
---@type item_unt
local item_unt = import('game/entities/unit/item_unt')
---@type game_ent
local game_ent = import('game/entities/game_ent')

------------------------------------------------------------------------------------
-- [事件] 预载函数(重载脚本)
------------------------------------------------------------------------------------
avatar_ent.super_preload = function()
    avatar_ent.wc_set_avatar = decider.run_interval_wrapper('设置化身', this.wi_set_avatar, function()
        return local_player:level() > 4
    end)
    avatar_ent.wi_set_avatar = decider.run_interval_wrapper('设置化身', this.set_avatar, 30 * 60 * 1000)
    avatar_ent.wa_equip_avatar = decider.run_action_wrapper('装备化身', this.equip_avatar)
    avatar_ent.wa_add_avatar = decider.run_action_wrapper('添加化身', this.add_avatar)
end

--------------------------------------------------------------------------------
-- [行为] 设置化身(外部调用)
--
-- @static
-- @tparam      string     care         场景（针对采集模块使用，其他模块为nil取最佳品质）
-- @tparam      string     use_type     佩戴类型（针对采集模块使用,类型有减时和等级选择）
-- @usage
-- avatar_ent.set_avatar(场景,佩戴类型)
--------------------------------------------------------------------------------
avatar_ent.set_avatar = function(care, use_type)
    -- 使用化身卷轴
    avatar_ent.use_avatar_reel()
    --背包最优化身和当前装备化身
    local bast_avatar, my_avatar = avatar_ent.get_best_avatar(care, use_type)
    --装备化身
    avatar_ent.wa_equip_avatar(bast_avatar, my_avatar)
    --关闭窗口
    game_ent.wc_close_window()
end

--------------------------------------------------------------------------------
-- [行为] 装备化身
--
-- @static
-- @tparam      table     bast_avatar       最好的化身信息
-- @tparam      table     my_avatar         当前佩戴化身信息
-- @treturn     boolean
-- @usage
-- avatar_ent.equip_avatar(最好的化身信息,当前佩戴化身信息)
--------------------------------------------------------------------------------
avatar_ent.equip_avatar = function(bast_avatar, my_avatar)
    if table_is_empty(bast_avatar) then
        return false, '不存在化身'
    end
    if bast_avatar.id == my_avatar.id then
        return false, '当前穿戴化身是最好化身'
    end
    local my_status = local_player:status()
    if my_status == 8 or my_status == 9 or my_status == 28 or my_status == 29 then
        return false, '当前状态' .. my_status .. '不能装备化身'
    end
    --装备化身命令,通过当前化身id判断是否装备成功
    avatar_unit.equip_avatar(bast_avatar.id)
    for i = 1, 30 do
        local ret_t, my_last_avatar = avatar_ent.get_bag_avatar_info()
        if my_last_avatar.id ~= my_avatar.id then
            return true, '装备化身成功'
        end
        decider.sleep(500)
    end
    return false, '战斗状态不能装备化身'
end

--------------------------------------------------------------------------------
-- [行为] 添加化身
--
-- @tparam      integer     id       化身卷轴id
-- @treturn     boolean
-- @usage
-- avatar_ent.add_avatar(化身卷轴id)
--------------------------------------------------------------------------------
avatar_ent.add_avatar = function(id)
    -- 通过背包重量判断是否使用成功
    local bag_weight = item_unit.get_bag_weight()
    avatar_unit.add_avatar(id)
    for i = 1, 10 do
        if bag_weight ~= item_unit.get_bag_weight() then
            return true, '使用化身卷轴成功'
        end
        decider.sleep(500)
    end
    return false, '使用化身卷轴超时'
end

--------------------------------------------------------------------------------
-- [条件行为] 判断是否有化身卷轴并使用
--
-- @treturn     boolean
-- @usage
-- avatar_ent.use_avatar_reel()
--------------------------------------------------------------------------------
avatar_ent.use_avatar_reel = function()
    local ret_b = false
    --获取化身卷轴信息
    local avatar_reel = avatar_res.AVATAR_REEL
    for i = 1, #avatar_reel do
        local item_info = item_unt.get_item_info_by_res_id(avatar_reel[i].res_id)
        --背包存在化身卷轴使用
        if not table_is_empty(item_info) then
            for j = 1, item_info.num do
                if avatar_ent.wa_add_avatar(item_info.id) then
                    ret_b = true
                    decider.sleep(10 * 1000)
                    game_ent.close_window()
                end
            end
        end
    end
    return ret_b
end

--------------------------------------------------------------------------------
-- [读取] 获取当前装备化身id
--
-- @treturn         integer          id       当前装备化身信息,包含:
-- @usage
-- local id = avatar_ent.get_equip_avatar_id()
--------------------------------------------------------------------------------
avatar_ent.get_equip_avatar_id = function()
    local id = 0
    local avatar_obj = avatar_unit:new()
    local list = avatar_unit.list()
    for i = 1, #list do
        local obj = list[i]
        if avatar_obj:init(obj) and avatar_obj:is_used() then
            id = avatar_obj:id()
            break
        end
    end
    avatar_obj:delete()
    return id
end

--------------------------------------------------------------------------------
-- [读取] 获取化身信息
--
-- @treturn         table       ret_t           背包所有化身信息表
-- @treturn         t           my_avatar       当前装备化身信息,包含:
-- @tfield[t]       integer     obj             化身实例对象
-- @tfield[t]       integer     id              化身ID
-- @tfield[t]       integer     quality         化身品质
-- @tfield[t]       string      name            化身名称
-- @tfield[t]       integer     gender          化身性别
-- @tfield[t]       boolean     is_used         化身是否佩戴
-- @usage
-- local avatar_info, my_avatar = avatar_ent.get_bag_avatar_info()
-- print_r(avatar_info) 背包所有化身信息表
-- print_r(my_avatar)   当前装备化身信息
--------------------------------------------------------------------------------
avatar_ent.get_bag_avatar_info = function()
    local ret_t = {}
    local my_avatar = {}
    local avatar_obj = avatar_unit:new()
    local list = avatar_unit.list()
    for i = 1, #list do
        local obj = list[i]
        if avatar_obj:init(obj) then
            --判断是否使用
            local is_used = avatar_obj:is_used()
            local ret = {
                obj = obj,
                id = avatar_obj:id(),
                quality = avatar_obj:quality(),
                gender = avatar_obj:gender(),
                is_used = is_used,
                --name = avatar_obj:name(),
            }
            -- 如果化身是装备中就写入输出
            if is_used then
                my_avatar = ret
            end
            table.insert(ret_t, ret)
        end
    end
    avatar_obj:delete()
    return ret_t, my_avatar
end

--------------------------------------------------------------------------------
-- [读取] 通过使用场景和佩戴类型获取化身信息
--
-- @tparam          string      care            场景（针对采集模块使用，其他模块为nil取最佳品质）
-- @tparam          string      use_type        佩戴类型（针对采集模块使用,类型有减时和等级选择）
-- @treturn         t           bast_avatar     场景和佩戴类型下最好的化身信息,包含:
-- @tfield[t]       integer     obj             化身实例对象
-- @tfield[t]       integer     id              化身ID
-- @tfield[t]       integer     quality         化身品质
-- @tfield[t]       string      name            化身名称
-- @tfield[t]       integer     gender          化身性别
-- @tfield[t]       boolean     is_used         化身是否佩戴
-- @treturn         t           my_avatar       当前装备化身信息,包含:
-- @tfield[t]       integer     obj             化身实例对象
-- @tfield[t]       integer     id              化身ID
-- @tfield[t]       integer     quality         化身品质
-- @tfield[t]       string      name            化身名称
-- @tfield[t]       integer     gender          化身性别
-- @tfield[t]       boolean     is_used         化身是否佩戴
-- @usage
-- local bast_avatar, my_avatar = avatar_ent.get_best_avatar(场景, 佩戴类型)
-- print_r(bast_avatar)
-- print_r(my_avatar)
--------------------------------------------------------------------------------
avatar_ent.get_best_avatar = function(care, use_type)
    --获取背包中所有化身信息和自己的化身信息
    local avatar_info, my_avatar = avatar_ent.get_bag_avatar_info()
    local bast_avatar = {}
    if care then
        --通过场景判断优先级高的选项
        if use_type == '等级' then
            bast_avatar = avatar_ent.contrast_up_level(care, avatar_info)
        elseif use_type == '减时' then
            bast_avatar = avatar_ent.contrast_down_time(care, avatar_info)
        end
    else
        --获取品质最优的化身
        bast_avatar = avatar_ent.contrast_quality(avatar_info)
    end
    return bast_avatar, my_avatar
end

--------------------------------------------------------------------------------
-- [读取] 获取提升等级最好的化身
--
-- @tparam          string      care            场景（针对采集模块使用，其他模块为nil取最佳品质）
-- @tparam          table       my_avatar       背包化身信息表
-- @treturn         t           bast_avatar     提升等级最好的化身,包含:
-- @tfield[t]       integer     obj             化身实例对象
-- @tfield[t]       integer     id              化身ID
-- @tfield[t]       integer     quality         化身品质
-- @tfield[t]       string      name            化身名称
-- @tfield[t]       integer     gender          化身性别
-- @tfield[t]       boolean     is_used         化身是否佩戴
-- @usage
-- local bast_avatar = avatar_ent.contrast_up_level(场景, 背包化身信息表)
-- print_r(bast_avatar)
--------------------------------------------------------------------------------
avatar_ent.contrast_up_level = function(care, my_avatar)
    local down_time, up_level = 0, 0
    local bast_avatar = {}
    for i, v in pairs(avatar_res.AVATAR_INFO) do
        if v[care] then
            --判断等级
            if v[care].up_level and v[care].up_level >= up_level then
                local read = true
                if v[care].up_level == up_level then
                    --判断减时
                    if not v[care].down_time then
                        read = false
                    elseif v[care].down_time <= down_time then
                        read = false
                    end
                end
                if read then
                    for j = 1, #my_avatar do
                        if my_avatar[j].id == i then
                            up_level = v[care].up_level or 0
                            down_time = v[care].down_time or 0
                            bast_avatar = my_avatar[j]
                        end
                    end
                end
            end
        end
    end
    return bast_avatar
end

--------------------------------------------------------------------------------
-- [读取] 获取减少时间最好的化身
--
-- @tparam          string      care            场景（针对采集模块使用，其他模块为nil取最佳品质）
-- @tparam          table       my_avatar       背包化身信息表
-- @treturn         t           bast_avatar     最好的减少时间化身,包含:
-- @tfield[t]       integer     obj             化身实例对象
-- @tfield[t]       integer     id              化身ID
-- @tfield[t]       integer     quality         化身品质
-- @tfield[t]       string      name            化身名称
-- @tfield[t]       integer     gender          化身性别
-- @tfield[t]       boolean     is_used         化身是否佩戴
-- @usage
-- local bast_avatar = avatar_ent.contrast_down_time(场景, 背包化身信息表)
-- print_r(bast_avatar)
--------------------------------------------------------------------------------
avatar_ent.contrast_down_time = function(care, my_avatar)
    local down_time, up_level = 0, 0
    local bast_avatar = {}
    for i, v in pairs(avatar_res.AVATAR_INFO) do
        if v[care] then
            --判断减时
            if v[care].down_time and v[care].down_time >= down_time then
                local read = true
                if v[care].down_time == down_time then
                    --判断等级
                    if not v[care].up_level then
                        read = false
                    elseif v[care].up_level <= up_level then
                        read = false
                    end
                end
                if read then
                    for j = 1, #my_avatar do
                        if my_avatar[j].id == i then
                            up_level = v[care].up_level or 0
                            down_time = v[care].down_time or 0
                            bast_avatar = my_avatar[j]
                        end
                    end
                end
            end
        end
    end
    return bast_avatar
end

--------------------------------------------------------------------------------
-- [读取] 获取品质最好的化身
--
-- @tparam          table       my_avatar       背包化身信息表
-- @treturn         t           bast_avatar     最好的减少时间化身,包含:
-- @tfield[t]       integer     obj             化身实例对象
-- @tfield[t]       integer     id              化身ID
-- @tfield[t]       integer     quality         化身品质
-- @tfield[t]       string      name            化身名称
-- @tfield[t]       integer     gender          化身性别
-- @tfield[t]       boolean     is_used         化身是否佩戴
-- @usage
-- local bast_avatar = avatar_ent.contrast_quality(背包化身信息表)
-- print_r(bast_avatar)
--------------------------------------------------------------------------------
avatar_ent.contrast_quality = function(my_avatar)
    local bast_avatar = {}
    local bast_quality = 0
    for j = 1, #my_avatar do
        --判断品质
        if my_avatar[j].quality > bast_quality then
            bast_quality = my_avatar[j].quality
            bast_avatar = my_avatar[j]
        end
    end
    return bast_avatar
end

--------------------------------------------------------------------------------
-- [读取] 获取化身增加采集等级
--------------------------------------------------------------------------------
avatar_ent.get_avatar_add_level = function(avatar_info,gather_type)
    local add_level = 0
    local avatar_id = avatar_info
    if type(avatar_info) == 'table' then
        avatar_id = avatar_info.id
    end
    if not avatar_res.AVATAR_INFO[avatar_id] then
        return add_level
    end
    if not avatar_res.AVATAR_INFO[avatar_id][gather_type] then
        return add_level
    end
    add_level = avatar_res.AVATAR_INFO[avatar_id][gather_type].up_level or 0
    return add_level
end

------------------------------------------------------------------------------------
-- [内部] 将对象转换为字符串
--
-- @local
-- @treturn      string                     模块名称
------------------------------------------------------------------------------------
function avatar_ent.__tostring()
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
avatar_ent.__newindex = function(t, k, v)
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
avatar_ent.__index = avatar_ent

------------------------------------------------------------------------------------
-- [构造] 创建一个新的实例
--
-- @local
-- @tparam       table     args             可选参数，用于初始化新实例
-- @treturn      table                      新创建的实例
------------------------------------------------------------------------------------
function avatar_ent:new(args)
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
    return setmetatable(new, avatar_ent)
end

-------------------------------------------------------------------------------------
-- 返回实例对象
-------------------------------------------------------------------------------------
return avatar_ent:new()

-------------------------------------------------------------------------------------