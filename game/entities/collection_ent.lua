------------------------------------------------------------------------------------
-- game/entities/collection_ent.lua
--
-- 本模块为collection_ent单元
--
-- @module      collection_ent
-- @author      Administrator
-- @license     MIT
-- @release     v1.0.0 - 2023-04-13
-- @copyright   2023
-- @usage
-- local collection_ent = import('game/entities/collection_ent.lua')
------------------------------------------------------------------------------------

-- 模块定义
---@class collection_ent
local collection_ent = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-04-13 - Initial release',
    -- 模块名称
    MODULE_NAME = 'collection_ent ent'
}

-- 自身模块
local this = collection_ent
-- 框架模块
local settings = settings
local trace = trace
local decider = decider
local common = common
-- 引用模块

---@type move_ent
local move_ent = import('game/entities/move_ent')
---@type gather_res
local gather_res = import('game/resources/gather_res')
---@type redis_ent
local redis_ent = import('game/entities/redis_ent')
---@type common_unt
local common_unt = import('game/entities/unit/common_unt')
---@type item_unt
local item_unt = import('game/entities/unit/item_unt')
---@type avatar_ent
local avatar_ent = import('game/entities/avatar_ent')
---@type game_ent
local game_ent = import('game/entities/game_ent')

---------------------------------------------------------------------
-- [事件] 预载函数(重载脚本时)
---------------------------------------------------------------------
this.super_preload = function()
    -- 行为
    collection_ent.wa_use_tool = decider.run_action_wrapper('更换工具', this.use_tool)
    collection_ent.wa_gather_item = decider.run_action_wrapper('采集', this.gather_item)
    collection_ent.wi_set_redis_gather = decider.run_interval_wrapper('写入矿区信息', this.set_redis_gather, 120 * 1000)
    collection_ent.w_fishing = decider.function_wrapper('执行钓鱼', this.fishing)
end

--------------------------------------------------------------------------------
-- [行为] 记录当前采集区域采集信息
--
-- @tparam       string         map_name        地图名
-- @tparam       boolean        bool            采集信息（是否在采集）
-- @usage
-- collection_ent.set_redis_gather(地图名,采集信息)
--------------------------------------------------------------------------------
collection_ent.set_redis_gather = function(map_name,bool)
    local PATH = '传奇M:内置数据:采集数据:'..main_ctx:c_server_name()..':'..map_name
    local data = {
        can_gather = bool
    }
    redis_ent.set_json_redis(PATH, data)
end

--------------------------------------------------------------------------------
-- [行为] 移动到矿点
--
-- @tparam          table           regional            矿区信息
-- @treturn         boolean
-- @usage
-- local bool = collection_ent.execute_gather(矿区信息)
--------------------------------------------------------------------------------
collection_ent.move_regional = function(regional)
    local out_dist = 400
    local map_id = regional.map_id
    local x, y, z = regional.x, regional.y, regional.z
    local teleport_id = regional.teleport_id
    while decider.is_working() do
        if map_id == actor_unit.map_id() then
            if local_player:dist_xy(x, y) <= out_dist then
                return true
            else
                move_ent.wn_move_map_xy(map_id, x, y, z, teleport_id, '采集', out_dist)
            end
        else
            move_ent.wn_move_map_xy(map_id, x, y, z, teleport_id, '采集', out_dist)
        end
        decider.sleep(2000)
    end
    return false
end

---------------------------------------------------------------------
-- [行为] 更换工具
--
-- @tparam      integer     tool_id         使用工具id
-- @tparam      integer     tool_pos        使用工具位置
-- @treturn     boolean
-- @usage
-- collection_ent.use_tool(使用工具id,使用工具位置)
---------------------------------------------------------------------
function collection_ent.use_tool(tool_id, tool_pos)
    local equip_info = item_unt.get_bag_equip_info_bypos(tool_pos)
    item_unit.use_equip(tool_id, tool_pos, 0)
    for i = 1, 20 do
        if equip_info.id ~= item_unt.get_bag_equip_info_bypos(tool_pos).id then
            return true, '更换成功'
        end
        decider.sleep(500)
    end
    return false, '更换超时'
end

--------------------------------------------------------------------------------
-- [行为] 采集物品
--
-- @tparam      table          gather_list       可采集采集物列表
-- @tparam      integer        map_id            地图id
-- @treturn     boolean
-- @usage
-- collection_ent.gather_item(可采集矿区地图列表,地图id)
--------------------------------------------------------------------------------
collection_ent.gather_item = function(gather_list,map_id)
    local obj = gather_list[1].obj
    local my_id = local_player:id()
    local actor_obj = actor_ctx
    local out_dist = 300
    if actor_obj:init(obj) then
        local gather_num = 0
        local gather_time = os.time()
        while decider.is_working() do
            --TODO:死亡退出
            if game_ent.is_player_dead() then
                return false, '死亡退出'
            end
            local x,y,z = actor_obj:cx(),actor_obj:cy(),actor_obj:cz()
            if local_player:dist_xy(x,y) > out_dist then
                if not local_player:is_move() then
                    move_ent.auto_move_ex(x, y, z,out_dist)
                end
            else
                gather_num = gather_num + 1
                actor_unit.gather(obj)
                decider.sleep(1000)
            end
            if not actor_obj:can_gather() then
                return false, '不可采集'
            end
            if actor_obj:gather_life() < 1 then -- 可采集数量为0
                return false, '可采集数量为0'
            end
            local gather_player_id = actor_obj:gather_player_id()
            if gather_player_id ~= 0 and gather_player_id ~= my_id then --已被采集
                return false, '已被采集'
            end
            if local_player:status() == 29 then --正在采集
                break
            end
            if actor_unit.map_id() ~= map_id then
                return false, '不在采集地图'
            end
            if gather_num > 2 then --采集次数超2次
                return false, '采集次数超时'
            end
            if os.time() - gather_time >= 30 then --采集超时30s
                return false, '采集超时'
            end
            decider.sleep(30)
        end
    end
    return true
end

---------------------------------------------------------------------
-- [条件] 钓鱼
--
-- @tparam      table     regional        采集地图信息
-- @treturn     boolean
-- @usage
-- collection_ent.fishing(采集地图信息)
---------------------------------------------------------------------
function collection_ent.fishing(regional)
    local pos_list = regional.fishing_list
    while decider.is_working() do
        -- 循环来回移动到钓鱼坐标直到可以钓鱼执行钓鱼后结束
        for i = 1, #pos_list do
            local move_time = os.time()
            while decider.is_working() do
                --判断是否可以钓鱼
                if actor_unit.can_fishing() then
                    actor_unit.start_fishing()
                    decider.sleep(2000)
                end
                -- 钓鱼状态退出
                if local_player:status() == 30 then
                    return true
                end
                -- 移动超时切换到下一个钓鱼点
                if os.time() - move_time > 30 then
                    break
                end
                -- 移动到指定点钓鱼
                if not local_player:is_move() then
                    move_ent.wa_auto_move(pos_list[i].x, pos_list[i].y, pos_list[i].z,100)
                end
                decider.sleep(30)
            end
        end
        decider.sleep(2000)
    end
    return false,'钓鱼超时'
end

---------------------------------------------------------------------
-- [条件] 判断是否跟换工具
--
-- @tparam      integer     tool_pos        工具位置
-- @tparam      integer     tool_res_id     工具资源id
-- @treturn     boolean
-- @usage
-- collection_ent.switch_tool(工具位置,工具资源id)
---------------------------------------------------------------------
function collection_ent.switch_tool(tool_pos, tool_res_id)
    local equip_info = item_unt.get_bag_equip_info_bypos(tool_pos)
    if not table_is_empty(equip_info) and equip_info.durability > 5 then
        return false, '工具耐久大于5不切换'
    end
    local best_tool = item_unt.get_best_tool_info(tool_res_id)
    if table_is_empty(best_tool) then
        return false, '背包不存在工具'
    end
    if best_tool.durability < 5 then
        return false, '背包不存高耐久工具'
    end
    collection_ent.wa_use_tool(best_tool.id, tool_pos)
    return true, '切换'
end

--------------------------------------------------------------------------------
-- [条件] 判断是否切换矿点
--
-- @tparam      table           regional            矿区信息
-- @tparam      table           map_list            地图名列表
-- @tparam      integer         proficiency_id      熟练度id
-- @tparam      integer         my_gather_level     熟练度等级
-- @treturn      t              regional            包含采集地图信息 table，包括：
-- @tfield[t]    integer        x                   x坐标
-- @tfield[t]    integer        y                   y坐标
-- @tfield[t]    integer        z                   z坐标
-- @tfield[t]    integer        map_id              地图id
-- @tfield[t]    string         map_name            地图名
-- @tfield[t]    integer        danger_level        危险等级
-- @tfield[t]    integer        line_num            频道数量
-- @tfield[t]    integer        max_level           最大采集等级
-- @tfield[t]    integer        min_level           最小采集等级
-- @tfield[t]    integer        teleport_id         采集点传送id
-- @treturn      t              map_list            包含可采集的地图名 table，包括：
-- @tfield[t]    string         map_name            地图名[1]
-- @tfield[t]    string         map_name            地图名[2]
-- @tfield[t]    string         map_name            ...
-- @usage
-- local regional, map_list = collection_ent.switch_regional(矿区信息,地图名列表,熟练度id,熟练度等级)
--------------------------------------------------------------------------------
collection_ent.switch_regional = function(regional, map_list, proficiency_id, my_gather_level)
    --如果角色采集等级发生变化，切换矿点
    if my_gather_level ~= actor_unit.get_proficiency_lv(proficiency_id) then
        local new_regional, new_map_list = collection_ent.compliant_regional()
        if #map_list ~= #new_map_list then
            --初始化切换矿点记录
            this.switch_num = 0
            this.chick_switch_num = 0
            regional = new_regional
            map_list = new_map_list
        end
    elseif this.switch_num and this.switch_num >= 10 then
        this.switch_num = 0
        this.chick_switch_num = 0
        local map_name = collection_ent.get_switch_map_name(map_list)
        if map_name == '' then
            return regional, map_list
        end
        local gather_map_res = collection_ent.get_gather_type_info().gather_res -- 获取采集类型信息
        local idx = 0
        for i = 1, #gather_map_res do
            if gather_map_res[i].map_name == map_name then
                idx = i
                break
            end
        end
        if idx ~= 0 then
            regional = gather_map_res[idx]
        end
    end
    return regional, map_list
end

--------------------------------------------------------------------------------
-- [条件] 判断是否切换频道
--
-- @treturn      boolean
-- @usage
-- collection_ent.switch_line()
--------------------------------------------------------------------------------
collection_ent.switch_line = function()
    local ret_b = false
    if not this.chick_switch_num then
        this.chick_switch_num = 0
    end
    this.chick_switch_num = this.chick_switch_num + 1
    if this.chick_switch_num >= 120 then
        this.switch_num = this.switch_num + 1
        this.chick_switch_num = 0
        ret_b = true
    end
    return ret_b
end

--------------------------------------------------------------------------------
-- [读取] 获取采集类型信息
--
-- @treturn      t          ret_t               采集信息 table，包括：
-- @tfield[t]    table      gather_res          采集资源表
-- @tfield[t]    integer    proficiency_id      熟练度id
-- @tfield[t]    string     gather_type         采集类型
-- @usage
-- local info = collection_ent.get_gather_type_info()
--------------------------------------------------------------------------------
collection_ent.get_gather_type_info = function()
    local ret_t = {}
    -- 采集类型
    local gather_type_list = {
        ['执行割草'] = { gather_res = gather_res.PICKING, proficiency_id = 0x3, gather_type = '割草' },
        ['执行挖矿'] = { gather_res = gather_res.MINING, proficiency_id = 0x4, gather_type = '挖矿' },
        ['执行钓鱼'] = { gather_res = gather_res.FISHING, proficiency_id = 0x6, gather_type = '钓鱼' },
    }
    for k, v in pairs(gather_type_list) do
        if redis_ent[k] == 1 then
            ret_t = v
            break
        end
    end
    return ret_t
end

--------------------------------------------------------------------------------
-- [读取] 判断装备化身优先项（减时/等级）
--
-- @static
-- @tparam       integer        proficiency_id          熟练度id
-- @tparam       table          gather_map_res          采集地图信息
-- @tparam       string         gather_type             采集类型
-- @treturn      string         use_type                类型
-- @usage
-- local use_type = collection_ent.get_type_by_use(熟练度id,采集地图信息,'采集类型')
--------------------------------------------------------------------------------
collection_ent.get_type_by_use = function(proficiency_id, gather_map_res, gather_type)
    local use_type = '等级'
    -- 获取指定采集场景下最好的等级化身信息
    local bast_avatar = avatar_ent.get_best_avatar(gather_type, '等级')
    -- 获取化身增加的采集等级
    local add_level = avatar_ent.get_avatar_add_level(bast_avatar, gather_type)
    if add_level > 0 then
        -- 获取采集等级
        local gather_level = actor_unit.get_proficiency_lv(proficiency_id)
        -- 获取采集区域
        local add_map_list, add_map_list2 = collection_ent.compliant_regional_by_level(gather_level + add_level, gather_map_res)
        -- 获取采集区域
        local map_list, map_list2 = collection_ent.compliant_regional_by_level(gather_level, gather_map_res)
        -- 等级变化采集区域不变优先佩戴减时化身
        if #add_map_list2 == #map_list2 then
            use_type = '减时'
        end
    end
    return use_type
end

--------------------------------------------------------------------------------
-- [读取] 获取采集地图信息
--
-- @treturn      t          regional            包含采集地图信息 table，包括：
-- @tfield[t]    integer    x                   x坐标
-- @tfield[t]    integer    y                   y坐标
-- @tfield[t]    integer    z                   z坐标
-- @tfield[t]    integer    map_id              地图id
-- @tfield[t]    string     map_name            地图名
-- @tfield[t]    integer    danger_level        危险等级
-- @tfield[t]    integer    line_num            频道数量
-- @tfield[t]    integer    max_level           最大采集等级
-- @tfield[t]    integer    min_level           最小采集等级
-- @tfield[t]    integer    teleport_id         采集点传送id
-- @treturn      t          map_list            包含可采集的地图名 table，包括：
-- @tfield[t]    string     map_name            地图名[1]
-- @tfield[t]    string     map_name            地图名[2]
-- @tfield[t]    string     map_name            ...
-- @treturn      integer    proficiency_id      熟练度id
-- @usage
-- local regional, map_list, proficiency_id = item_ent.compliant_regional()
--------------------------------------------------------------------------------
collection_ent.compliant_regional = function()
    -- 获取采集类型信息
    local gather_info = collection_ent.get_gather_type_info()
    -- 采集类型
    local gather_type = gather_info.gather_type
    -- 采集地图信息
    local gather_map_res = gather_info.gather_res
    -- 熟练度id
    local proficiency_id = gather_info.proficiency_id
    -- 佩戴对应类型化身
    avatar_ent.wc_set_avatar(gather_type, collection_ent.get_type_by_use(proficiency_id, gather_map_res, gather_type))
    --获取化身提升等级
    local add_level = avatar_ent.get_avatar_add_level(avatar_ent.get_equip_avatar_id(), gather_type)
    -- 获取熟练等级
    local my_gather_level = actor_unit.get_proficiency_lv(proficiency_id) + add_level
    -- 通过熟练等级获取符合等级采集区和达到等级的采集区
    local regional_list, regional_list2 = collection_ent.compliant_regional_by_level(my_gather_level, gather_map_res)
    -- 达到等级的采集区地图名字（后续用于当前地图采集困难切换采集地图使用，等级向下兼容）
    local map_list = {}
    -- 将地图名存在map_list列表
    for i = #regional_list2, 1, -1 do
        table.insert(map_list, regional_list2[i].map_name)
    end
    -- 随机一个符合等级采集区序号
    local idx = math.random(1, #regional_list)
    local regional = regional_list[idx]
    return regional, map_list, proficiency_id
end

--------------------------------------------------------------------------------
-- [读取] 获取切换矿区地图名
--
-- @tparam       table          map_name_list       可采集矿区地图列表
-- @treturn      string         map_name            地图名
-- @usage
-- local map_name = collection_ent.get_switch_map_name(可采集矿区地图列表)
--------------------------------------------------------------------------------
collection_ent.get_switch_map_name = function(map_name_list)
    local map_name = ''
    for i = 1, #map_name_list do
        local PATH = '传奇M:内置数据:采集数据:'..main_ctx:c_server_name()..':'..map_name_list[i]
        local map_info = redis_ent.get_json_redis(PATH)
        if map_info.can_gather then
            map_name = map_name_list[i]
            break
        end
    end
    return map_name
end

--------------------------------------------------------------------------------
-- [读取] 获取周围可采矿信息
--
-- @tparam          function        func                条件
-- @treturn         t               gather_list         采集物信息列表 table，包括：
-- @tfield[t]       integer         obj                 采集物指针
-- @tfield[t]       integer         dist                采集物距离
-- @usage
-- local gather_list = collection_ent.get_can_gather_list(矿区信息,地图名列表,熟练度id,熟练度等级)
--------------------------------------------------------------------------------
collection_ent.get_can_gather_list = function(func)
    local gather_list = {}
    local my_id = local_player:id()
    local actor_obj = actor_unit:new()
    local list = actor_unit.list(4)
    for i = 1, #list do
        repeat
            local obj = list[i]
            if actor_obj:init(obj) then
                -- 不可采集
                if not actor_obj:can_gather() then
                    break
                end
                -- 没有数量
                if actor_obj:gather_life() < 0 then
                    break
                end
                -- 采集物品已被采集
                local gather_player_id = actor_obj:gather_player_id()
                if gather_player_id ~= 0 and gather_player_id ~= my_id then
                    break
                end
                --非区域内的采集物
                local cz = actor_obj:cz()
                if func and not func(cz) then
                    break
                end
                --TODO:过滤不能采集的采集物
                local gather_info = {
                    obj = obj,
                    dist = actor_obj:dist(),
                }
                table.insert(gather_list, gather_info)
            end
        until true
    end
    actor_obj:delete()
    table.sort(gather_list, function(a, b)
        return a.dist < b.dist
    end)
    return gather_list
end

---------------------------------------------------------------------
-- [读取] 通过熟练等级获取符合条件区域
--
-- @tparam          integer         level               采集等级
-- @tparam          table           gather_map_res      矿区资源
-- @treturn         t               regional_list       所有符合等级最大-最小的矿区 table，包括：
-- @tfield[t]       integer         x                   x坐标
-- @tfield[t]       integer         y                   y坐标
-- @tfield[t]       integer         z                   z坐标
-- @tfield[t]       integer         map_id              地图id
-- @tfield[t]       string          map_name            地图名
-- @tfield[t]       integer         danger_level        危险等级
-- @tfield[t]       integer         line_num            频道数量
-- @tfield[t]       integer         max_level           最大采集等级
-- @tfield[t]       integer         min_level           最小采集等级
-- @tfield[t]       integer         teleport_id         采集点传送id
-- @treturn         t               regional_list2      所有满足最小等级的矿区 table，包括：
-- @tfield[t]       integer         x                   x坐标
-- @tfield[t]       integer         y                   y坐标
-- @tfield[t]       integer         z                   z坐标
-- @tfield[t]       integer         map_id              地图id
-- @tfield[t]       string          map_name            地图名
-- @tfield[t]       integer         danger_level        危险等级
-- @tfield[t]       integer         line_num            频道数量
-- @tfield[t]       integer         max_level           最大采集等级
-- @tfield[t]       integer         min_level           最小采集等级
-- @tfield[t]       integer         teleport_id         采集点传送id
-- @usage
-- local regional_list, regional_list2 = collection_ent.compliant_regional_by_level(采集等级,矿区资源)
---------------------------------------------------------------------
collection_ent.compliant_regional_by_level = function(level, gather_map_res)
    local regional_list = {}
    local regional_list2 = {}
    for i = 1, #gather_map_res do
        if common_unt.between(level, gather_map_res[i].max_level, gather_map_res[i].min_level) then
            table.insert(regional_list, gather_map_res[i])
        end
        if level >= gather_map_res[i].min_level then
            table.insert(regional_list2, gather_map_res[i])
        end
    end
    return regional_list, regional_list2
end

---------------------------------------------------------------------
-- [内部] 将对象转换为字符串
--
-- @local
-- @treturn      string                     模块名称
---------------------------------------------------------------------
function collection_ent.__tostring()
    return this.MODULE_NAME
end

collection_ent.__index = collection_ent

---------------------------------------------------------------------
-- [构造] 创建一个新的实例
--
-- @local 
-- @tparam       table     args             可选参数，用于初始化新实例
-- @treturn      table                      新创建的实例
---------------------------------------------------------------------
function collection_ent:new(args)
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

    return setmetatable(new, collection_ent)
end

---------------------------------------------------------------------
-- 返回实例对象
return collection_ent:new()
---------------------------------------------------------------------