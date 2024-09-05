------------------------------------------------------------------------------------
-- game/entities/shop_ent.lua
--
-- 本模块为shop_ent_ex单元
--
-- @module      shop_ent
-- @author      Administrator
-- @license     MIT
-- @release     v1.0.0 - 2023-04-06
-- @copyright   2023
-- @usage
-- local shop_ent_ex = import('game/entities/shop_ent.lua')
------------------------------------------------------------------------------------

-- 模块定义
---@class shop_ent
local shop_ent = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-04-06 - Initial release',
    -- 模块名称
    MODULE_NAME = 'shop_ent module'
}

-- 自身模块
local this = shop_ent
-- 框架模块
local settings = settings
local trace = trace
local decider = decider
local common = common
-- 引用模块
---@type unit
local unit = import('game/entities/unit')
---@type move_ent
local move_ent = import('game/entities/move_ent')
---@type shop_res
local shop_res = import('game/resources/shop_res')
---@type redis_ent
local redis_ent = import('game/entities/redis_ent')
---@type common_unt
local common_unt = import('game/entities/unit/common_unt')
---@type item_unt
local item_unt = import('game/entities/unit/item_unt')
---@type actor_unt
local actor_unt = import('game/entities/unit/actor_unt')
---------------------------------------------------------------------
-- [事件] 预载函数(重载脚本时)
---------------------------------------------------------------------
this.super_preload = function()
    --[外部调用]
    this.wi_auto_shop_dungeon = decider.run_interval_wrapper('副本自动商店', this.auto_shop_ex, 300 * 1000)
    this.wi_auto_shop_gather = decider.run_interval_wrapper('采集自动商店', this.auto_shop_ex, 300 * 1000)
    --[执行行为]
    this.wa_execute_buy_item = decider.run_action_wrapper('购买物品', this.execute_buy_item)
    this.wa_execute_repair = decider.run_action_wrapper('维修装备', this.execute_repair)
    this.wa_execute_sell = decider.run_action_wrapper('出售物品', this.execute_sell)
    --[判断行为]
    this.wn_execute_buy = decider.run_normal_wrapper('交易npc', this.execute_buy)
    this.do_sell = decider.run_action_wrapper('是否出售物品', this.do_sell)
    this.do_buy_tool = decider.run_action_wrapper('是否购买工具', this.do_buy_tool)
    this.do_repair = decider.run_action_wrapper('是否维修', this.do_repair)
    this.do_buy_hp = decider.run_action_wrapper('是否买红', this.do_buy_hp)
    this.do_buy_mp = decider.run_action_wrapper('是否买蓝', this.do_buy_mp)
end

-- [行为] 通过购买场景自动判断与npc交易(外部调用)
--
-- @tparam       string      case        购买场景
-- @usage
-- shop_ent.auto_shop(购买场景)
--------------------------------------------------------------------------------
shop_ent.auto_shop_ex = function(case)
    if local_player:level() < 5 then
        return false, '角色等级小于5级'
    end
    if not shop_res.BUY_INFO[case] then
        return false, '不存在的场景'
    end
    local is_buy = false
    local buy_info = shop_res.BUY_INFO[case]
    --执行2遍，如果第1遍没有购买过只执行1遍
    --第1遍判断条件严格，第2遍判断宽松
    --如果第1遍执行过，执行第2遍,否则执行一遍
    for i = 1, 2 do
        local trad_list = shop_ent.do_trad()
        for k, v in pairs(trad_list) do
            if v.func(buy_info, is_buy) then
                shop_ent.wn_execute_buy(buy_info, v.npc_type, k)
                is_buy = true
            end
        end
        if not is_buy then
            break
        end
        decider.sleep(2000)
    end
    return is_buy
end

--------------------------------------------------------------------------------
-- [行为] 移动到购买信息对应的npc处执行交易动作(内部调用)
--
-- @tparam       table      buy_info        购买信息
-- @tparam       string     npc_type        npc类型
-- @treturn      string     buy_type        购买动作
-- @usage
-- shop_ent.execute_buy(购买信息,'npc类型','购买动作')
--------------------------------------------------------------------------------
shop_ent.execute_buy = function(buy_info, npc_type, buy_type)
    local npc_info = shop_res.MERCHANT[101][npc_type].npc_pos
    local map_id, x, y, z, teleport_id = npc_info.map_id, npc_info.x, npc_info.y, npc_info.z, npc_info.teleport_id
    local out_dis = 400
    local item_id_list = {
        ['购买红药'] = shop_res.MERCHANT[101][npc_type].sell_item[buy_info['红药名']],
        ['购买蓝药'] = shop_res.MERCHANT[101][npc_type].sell_item[buy_info['蓝药名']],
        ['购买工具'] = shop_res.MERCHANT[101][npc_type].sell_item[buy_info['工具类型']],
    }
    while decider.is_working() do
        if map_id == actor_unit:map_id() then
            if local_player:dist_xy(x, y) < out_dis then
                if not shop_ent.do_trad()[buy_type].func(buy_info, true) then
                    break
                end
                local npc_id = 0
                for i = 1, 30 do
                    --获取周围npc信息
                    local npc_data = actor_unt.get_npc_info_by_pos(x, y, npc_info.rand)
                    if not table_is_empty(npc_data) then
                        npc_id = npc_data.id
                        break
                    end
                    decider.sleep(1000)
                end
                if npc_id ~= 0 then
                    buy_info.npc_id = npc_id
                    for i, v in pairs(shop_ent.execute()) do
                        if string.find(buy_type, i) then
                            v.execute(buy_info, buy_type, item_id_list[buy_type])
                            break
                        end
                    end
                    decider.sleep(2000)
                else
                    move_ent.wi_switch_line()
                end
            else
                move_ent.wn_move_map_xy(map_id, x, y, z, teleport_id, '购买红药', out_dis)
            end
        else
            move_ent.wn_move_map_xy(map_id, x, y, z, teleport_id, '购买红药', out_dis)
        end
        decider.sleep(2000)
    end
end

---------------------------------------------------------------------
-- [行为] 执行与npc对应的交易动作(内部调用)
--
-- @treturn      table
-- @usage
-- local ret_t = shop_ent.execute()
---------------------------------------------------------------------
shop_ent.execute = function()
    local execute_list = {
        ['购买'] = {
            execute = function(info, buy_type, item_res)
                shop_ent.wa_execute_buy_item(info, buy_type, item_res)
            end
        },
        ['维修'] = {
            execute = function(info, buy_type)
                shop_ent.wa_execute_repair(info, buy_type)
            end
        },
        ['出售'] = {
            execute = function(info)
                shop_ent.wa_execute_sell(info)
            end
        },
    }
    return execute_list
end
---------------------------------------------------------------------
-- [行为] 执行购买操作
--
-- @tparam       table      info            交易资源
-- @tfield[t]    integer    npc_id          交易npc的id
-- @tfield[t]    integer    ['购买工具']      工具res_id
-- @tparam       string     buy_type        购买类型
-- @tparam       table      item_res        购买物品资源
-- @tfield[t]    integer    id              物品id
-- @usage
-- shop_ent.execute_buy_item(交易资源, 购买类型,购买物品资源)
---------------------------------------------------------------------
function shop_ent.execute_buy_item(info, buy_type, item_res)
    local buy_num_lisy = {
        ['购买工具'] = 1,
        ['购买红药'] = common_unt.calc_num((info['买红数'] or 0) - item_unt.get_num_by_red_id(0x00000FA2), 65, redis_ent['保留铜钱']),
        ['购买蓝药'] = common_unt.calc_num((info['买蓝数'] or 0) - item_unt.get_num_by_red_id(0x00000FA9), 65, redis_ent['保留铜钱']),
    }
    local my_money = item_unit.get_money_byid(2)
    item_unit.buy_item(info.npc_id, item_res.id, buy_num_lisy[buy_type])
    decider.sleep(1000)
    for i = 1, 30 do
        if my_money ~= item_unit.get_money_byid(2) then
            return true, '购买成功'
        end
        decider.sleep(500)
    end
    return false, '购买失败'
end

---------------------------------------------------------------------
-- [行为] 执行维修操作
--
-- @tparam       table      info            交易资源
-- @tfield[t]    integer    npc_id          交易npc的id
-- @tfield[t]    integer    ['购买工具']      工具res_id
-- @tparam       string     buy_type         购买类型
-- @usage
-- shop_ent.execute_repair(交易资源, 购买类型)
---------------------------------------------------------------------
function shop_ent.execute_repair(info, buy_type)
    local Price = shop_ent.repair_Price()
    local repair_id = -1
    if Price > 0 then
        repair_id = 0
    elseif buy_type == '维修工具' then
        repair_id = item_unt.get_bag_equip_repea(info['购买工具'])
    end
    if repair_id > -1 then
        local my_money = item_unit.get_money_byid(2)
        item_unit.repair_equip(info.npc_id, repair_id)
        decider.sleep(1000)
        for i = 1, 10 do
            if my_money ~= item_unit.get_money_byid(2) then
                return true, '修理成功'
            end
            decider.sleep(500)
        end
        return false, '修理失败'
    end
    return false, '无修理物品'
end

---------------------------------------------------------------------
-- [行为] 执行出售操作
--
-- @tparam       table      info        交易资源
-- @tfield[t]    integer    npc_id      交易npc的id
-- @usage
-- shop_ent.execute_sell(购买资源)
---------------------------------------------------------------------
function shop_ent.execute_sell(info)
    local sell_list = item_unt.get_sell_list()
    if #sell_list > 0 then
        local my_money = item_unit.get_money_byid(2)
        item_unit.sell_item(info.npc_id, sell_list)
        decider.sleep(1000)
        for i = 1, 10 do
            if my_money ~= item_unit.get_money_byid(2) then
                return true, '出售成功'
            end
            decider.sleep(500)
        end
        return false, '出售失败'
    end
    return false, '无可出售物品'
end

---------------------------------------------------------------------
-- [逻辑] 与npc交易前返回是否交易
--
-- @treturn      table
-- @usage
-- local ret_t = shop_ent.do_trad()
---------------------------------------------------------------------
shop_ent.do_trad = function()
    local trad_list = {
        ['出售物品'] = {
            func = function(info, mode)
                return shop_ent.do_sell(info, mode)
            end,
            npc_type = '杂货商人',
        },
        ['购买工具'] = {
            func = function(info)
                return shop_ent.do_buy_tool(info)
            end,
            npc_type = '杂货商人',
        },
        ['维修装备'] = { func = function(info, mode)
            return shop_ent.do_repair(info, mode)
        end, npc_type = '武器商人',
        },
        ['维修工具'] = {
            func = function(info, mode)
                return shop_ent.do_repair(info, mode)
            end,
            npc_type = '武器商人',
        },
        ['购买红药'] = {
            func = function(info, mode)
                return shop_ent.do_buy_hp(info, mode)
            end,
            npc_type = '药水商人',
        },
        ['购买蓝药'] = {
            func = function(info, mode)
                return shop_ent.do_buy_mp(info, mode)
            end,
            npc_type = '药水商人',
        },
    }
    return trad_list
end

---------------------------------------------------------------------
-- [条件] 是否出售物品
--
-- @tparam       table      info            购买资源
-- @tfield[t]    boolean   ['不售物品']       判断是否出售
-- @treturn      boolean
-- @usage
-- local bool = shop_ent.do_sell(购买资源)
---------------------------------------------------------------------
shop_ent.do_sell = function(info, mode)
    --获取可出售物品数量
    if info['不售物品'] then
        return false, info['场景'] .. '不出售物品'
    end
    local sell_list = item_unt.get_sell_list()
    if mode then
        if #sell_list < 1 then
            return false, '无可出售的物品'
        end
    else
        if #sell_list < redis_ent['最低出售数量'] then
            return false, '出售物品数量低于最低出售数量'
        end
        local str = ''
        if item_unit.get_bag_weight() * 100 / item_unit.get_bag_max_weight() < 90 and item_unit.get_bag_space() - item_unit.get_bag_max_space() < 5 then
            return false, '背包剩余空间大于等于5,且负重低于90%'
        end
    end
    return true, '可出售物品'
end

---------------------------------------------------------------------
-- [条件] 是否购买工具
--
-- @tparam       table      info            购买资源
-- @tfield[t]    boolean   ['购买工具']       购买工具的res_id
-- @tfield[t]    integer   ['工具数量']       购买工具的数量
-- @treturn      boolean
-- @usage
-- local bool = shop_ent.do_buy_tool(购买资源)
---------------------------------------------------------------------
shop_ent.do_buy_tool = function(info)
    if not info['购买工具'] then
        return false, info['场景'] .. '不购买工具'
    end
    if item_unt.get_num_by_red_id(info['购买工具']) >= info['工具数量'] then
        return false, '背包工具足够'
    end
    local money = item_unit.get_money_byid(2) - redis_ent['保留铜钱']
    if money < 4000 then
        return false, '铜钱不够（减设置保留）'
    end
    return true, '可购买工具'
end

---------------------------------------------------------------------
-- [条件] 是否维修装备
--
-- @tparam       table      info           购买资源
-- @tfield[t]    boolean   ['不维修']       判断是否维修
-- @tfield[t]    integer   ['维修装备']     触发维修装备的耐久
-- @treturn      boolean
-- @usage
-- local bool = shop_ent.do_repair(购买资源)
---------------------------------------------------------------------
shop_ent.do_repair = function(info, mode)
    if info['不维修'] then
        return false, info['场景'] .. '不维修'
    end
    --判断身上物品修理装备总价格和装备耐久度是否低于指定值
    local price, is_repair = shop_ent.repair_Price(info['维修装备'])
    local my_money = item_unit.get_money_byid(2)
    if my_money - redis_ent['保留铜钱'] < price then
        return false, '铜钱不够维修身上装备（减设置保留）'
    end
    if mode then
        if info['购买工具'] then
            price = shop_ent.repair_bag_price(info['购买工具'])
            if my_money - redis_ent['保留铜钱'] < price then
                return false, '铜钱不够维修背包工具（减设置保留）'
            end
        end
    else
        -- 所有装备耐久度百分比高于指定值
        if not is_repair then
            return false, '身上无装备耐久低于指定值'
        end
    end
    if price <= 0 then
        return false, '身上无可维修装备'
    end
    return true, '可维修装备'
end

---------------------------------------------------------------------
-- [条件] 判断是否购买红药水
--
-- @tparam       table      info           购买资源
-- @tfield[t]    boolean   ['不买红']       判断是否买红药
-- @tfield[t]    integer   ['触发买红数']     触发购买红药的数量
-- @tfield[t]    integer   ['买红数']       红药最大购买量
-- @treturn      boolean
-- @usage
-- local bool = shop_ent.do_buy_hp(购买资源)
---------------------------------------------------------------------
shop_ent.do_buy_hp = function(info, mode)
    -- 是否购买红药
    if info['不买红'] then
        return false, info['场景'] .. '不买红药水'
    end
    -- 背包红药是否低于指定数量
    local res_id = 0x00000FA2
    if info['红药名'] == '生命回复药水（小）' then
        res_id = 0x00000FA1
    end
    local hp_num = item_unt.get_num_by_red_id(res_id)
    local min_num = 10
    if not mode then
        min_num = 50
        if hp_num > info['触发买红数'] then
            return false, '背包红药数大于' .. info['触发买红数']
        end
    end
    local buy_hp_num = info['买红数'] - hp_num
    local can_buy_num = common_unt.calc_num(buy_hp_num, 65, redis_ent['保留铜钱'])
    if can_buy_num < min_num then
        return false, '可买红' .. can_buy_num .. ',数量低于' .. min_num
    end
    return true, '可购买红药'
end

---------------------------------------------------------------------
-- [条件] 是否购买蓝药水
--
-- @tparam       table      info           购买资源
-- @tfield[t]    boolean   ['不买蓝']       判断是否买蓝药
-- @tfield[t]    integer   ['触发买蓝数']     触发购买蓝药的数量
-- @tfield[t]    integer   ['买蓝数']       蓝药最大购买量
-- @treturn      boolean
-- @usage
-- local bool = shop_ent.do_buy_mp(购买资源)
---------------------------------------------------------------------
shop_ent.do_buy_mp = function(info, mode)
    -- 是否购买红药
    if info['不买蓝'] then
        return false, info['场景'] .. '不买蓝药水'
    end
    -- 背包蓝药是否低于指定数量
    local res_id = 0x00000FA9
    if info['蓝药名'] == '魔力回复药水（小）' then
        res_id = 0x00000FA8
    end
    local mp_num = item_unt.get_num_by_red_id(res_id)
    local min_num = 10
    if not mode then
        min_num = 50
        if mp_num > info['触发买蓝数'] then
            return false, '背包蓝药数大于' .. info['触发买蓝数']
        end
    end
    local buy_mp_num = info['买蓝数'] - mp_num
    local can_buy_num = common_unt.calc_num(buy_mp_num, 65, redis_ent['保留铜钱'])
    if can_buy_num < min_num then
        return false, '可买蓝' .. can_buy_num .. ',数量低于' .. min_num
    end
    return true, '可购买蓝药'
end

---------------------------------------------------------------------
-- [条件] 判断装备耐久是否低于指定耐久
--
-- @tparam      integer      durable_v      触发维修装备的耐久
-- @tparam      integer      durable        装备当前耐久
-- @treturn     integer      max_durable    装备最大耐久
-- @treturn     boolean                     判断装备是否达到触发维修
-- @usage
-- local bool = shop_ent.reach_repair_v(触发维修装备的耐久,装备当前耐久,装备最大耐久)
---------------------------------------------------------------------
shop_ent.reach_repair_v = function(durable_v, durable, max_durable)
    local ret_b = false
    if not durable_v then
        return ret_b
    end
    if durable_v >= 1 then
        if durable <= durable_v then
            ret_b = true
        end
    elseif durable / max_durable <= durable_v then
        ret_b = true
    end
    return ret_b
end


---------------------------------------------------------------------
-- [读取] 修理装备总价格
--
-- @tparam      integer      durability     触发维修装备的耐久
-- @treturn     integer      price          维修装备的总价
-- @treturn     boolean      need_repair    判断是否有装备达到触发维修
-- @usage
-- local price, bool = shop_ent.repair_Price(触发维修装备的耐久)
---------------------------------------------------------------------
shop_ent.repair_Price = function(durability)
    local need_repair = false
    local total_durability = 0 --维修总耐久
    for i = 0, 15 do
        local equip_info = item_unt.get_bag_equip_info_bypos(i)
        if not table_is_empty(equip_info) then
            if equip_info.durability < equip_info.max_durability then
                total_durability = total_durability + (equip_info.max_durability - equip_info.durability)
                if not need_repair then
                    need_repair = shop_ent.reach_repair_v(durability, equip_info.durability, equip_info.max_durability)
                end
            end
        end
    end
    local price = total_durability * 30 --总耐久价格
    return price, need_repair
end

---------------------------------------------------------------------
-- [读取] 修理背包装备总价格
--
-- @tparam      integer      durability     触发维修装备的耐久
-- @treturn     integer      price          维修装备的总价
-- @treturn     boolean      need_repair    判断是否有装备达到触发维修
-- @usage
-- local price, bool = shop_ent.repair_Price(触发维修装备的耐久)
---------------------------------------------------------------------
shop_ent.repair_bag_price = function(res_id)
    local durability = 0
    local item_ctx = item_unit:new()
    for _, v in ipairs(item_unit.list(0)) do
        if item_ctx:init(v, 0) and item_ctx:res_id() == res_id then
            local durab = item_ctx:max_durability() - item_ctx:durability()
            durability = durability + durab
        end
    end
    local price = durability * 20
    item_ctx:delete()
    return price
end

---------------------------------------------------------------------
-- [内部] 将对象转换为字符串
--
-- @local
-- @treturn      string                     模块名称
---------------------------------------------------------------------
function shop_ent.__tostring()
    return this.MODULE_NAME
end

shop_ent.__index = shop_ent

---------------------------------------------------------------------
-- [构造] 创建一个新的实例
--
-- @local
-- @tparam       table     args             可选参数，用于初始化新实例
-- @treturn      table                      新创建的实例
---------------------------------------------------------------------
function shop_ent:new(args)
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

    return setmetatable(new, shop_ent)
end

---------------------------------------------------------------------
-- 返回实例对象
return shop_ent:new()
---------------------------------------------------------------------
