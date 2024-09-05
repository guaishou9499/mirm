------------------------------------------------------------------------------------
-- game/entities/exchange_ent.lua
--
-- 这个模块主要是项目内物品相关功能操作。
--
-- @module      exchange_ent
-- @author      admin
-- @license     MIT
-- @release     v1.0.0 - 2023-03-22
-- @copyright   2023
-- @usage
-- local exchange_ent = import('game/entities/exchange_ent.lua')
------------------------------------------------------------------------------------

-- 模块定义
---@class exchange_ent
local exchange_ent = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-03-22 - Initial release',
    -- 模块名称
    MODULE_NAME = 'exchange_ent module',
    -- 只读模式
    READ_ONLY = false,
}

-- 实例对象
local this = exchange_ent
-- 日志模块
local trace = trace
-- 决策模块
local decider = decider


---@type redis_ent
local redis_ent = import('game/entities/redis_ent')
---@type item_unt
local item_unt = import('game/entities/unit/item_unt')
---@type item_res
local item_res = import('game/resources/item_res')
---@type ui_res
local ui_res = import('game/resources/ui_res')
---@type game_ent
local game_ent = import('game/entities/game_ent')
------------------------------------------------------------------------------------
-- [事件] 预载函数(重载脚本)
------------------------------------------------------------------------------------
exchange_ent.super_preload = function()
    exchange_ent.wi_exchange = decider.run_interval_wrapper('交易行模块', this.exchange, 3600 * 1000)
    exchange_ent.wa_buy_item = decider.run_action_wrapper('购买物品', this.buy_item)
    exchange_ent.wa_item_withdraw = decider.run_action_wrapper('领取购买物品', this.item_withdraw)
    exchange_ent.wa_get_item_info_up_item = decider.run_action_wrapper('上架物品', this.get_item_info_up_item)
    exchange_ent.wa_down_item = decider.run_action_wrapper('下架物品', this.down_item)
    exchange_ent.wa_calcul_gold = decider.run_action_wrapper('交易行结算', this.calcul_gold)
end

--------------------------------------------------------------------------------
-- [行为] 交易行通用功能(外部使用)
--
-- @tparam      table       res_id      购买物品res_id(不购买物品不用设置参数)
-- @tparam      integer     level       物品等级(不购买物品不用设置参数)
-- @treturn
-- @usage
-- exchange_ent.exchange(res_id,物品等级)
--------------------------------------------------------------------------------
exchange_ent.exchange = function(res_id,level)
    local exchange_func = {
        {func_name = '下架物品',func = function()
            exchange_ent.take_down()
        end},
        {func_name = '上架物品',func = function()
            exchange_ent.up_item()
        end},
        {func_name = '交易行结算',func = function()
            exchange_ent.settlement()
        end},
        {func_name = '购买物品',func = function(res_id1,level1)
            exchange_ent.buy_item_by_res_id(res_id1,level1)
        end},
        {func_name = '领取购买物品',func = function()
            exchange_ent.receipt()
        end},
    }
    --执行对应方法
    for i = 1, #exchange_func do
        exchange_func[i].func(res_id,level)
    end
    game_ent.wc_close_window()
end

------------------------------------------------------------------------------------
-- [行为] 上架物品
--
-- @tparam      table       item_info       物品信息
-- @tparam      integer     level           物品等级
-- @treturn     boolean
-- @usage
-- exchange_ent.up_item(物品信息,物品等级)
------------------------------------------------------------------------------------
exchange_ent.up_item = function()
    --获取背包物品
   local bag_item_info = item_unt.get_bag_item_info()
    for i = 1, #bag_item_info do
        --通过是否非绑定物品，出售数量大于指定数量判断是否出售
        if item_res.NOT_IS_BIND[bag_item_info[i].res_id] then
            if item_res.NOT_IS_BIND[bag_item_info[i].res_id].sell_num and bag_item_info[i].num >= item_res.NOT_IS_BIND[bag_item_info[i].res_id].sell_num then
                exchange_ent.wa_get_item_info_up_item(bag_item_info[i],0)
            end
        end
    end
end

------------------------------------------------------------------------------------
-- [行为] 通过物品信息上架物品
--
-- @tparam      table       item_info       物品信息
-- @tparam      integer     level           物品等级
-- @treturn     boolean
-- @usage
-- exchange_ent.get_item_info_up_item(物品信息,物品等级)
------------------------------------------------------------------------------------
exchange_ent.get_item_info_up_item = function(item_info,level)
    --获取物品交易行信息
    local exchange_item_info = exchange_ent.get_item_min_price(item_info.res_id, level)
    if table_is_empty(exchange_item_info) then
        return false ,'交易行没有'..item_info.name..'交易信息'
    end
    local sell_price = exchange_item_info[1].price
    --交易行出售价格第一个于第二个相差过大选择第二个价格上架
    if exchange_item_info[2] and exchange_item_info[2].price / sell_price > 1.5 then
        sell_price = exchange_item_info[2].price
    end
    local up_gold = sell_price * item_info.num
    if up_gold < 10 then
        return false ,item_info.name..'上架金额小于10'
    end
    if up_gold * 10 > item_unit.get_money_byid(2) then
        return false ,item_info.name..'铜钱不够上架所需金额'..up_gold * 10
    end
    local bag_weight = item_unit.get_bag_weight()
    exchange_unit.up_item(item_info.id, up_gold, item_info.num)
    for i = 1, 10 do
        if bag_weight ~= item_unit.get_bag_weight() then
            return true, '上架'..item_info.name..'成功'
        end
        decider.sleep(500)
    end
    return false, '上架'..item_info.name..'超时'
end

------------------------------------------------------------------------------------
-- [行为] 购买物品
--
-- @tparam      integer     id              物品ID
-- @tparam      integer     num             物品数量
-- @tparam      integer     total_price     物品总价
-- @treturn     boolean
-- @usage
-- exchange_ent.buy_item(物品ID,物品数量,物品总价)
------------------------------------------------------------------------------------
exchange_ent.buy_item = function(id,num, total_price)
    -- 通过金币判断是否购买成功
    local my_money = item_unit.get_money_byid(5)
    exchange_unit.buy_item(id, num, total_price)
    for i = 1, 20 do
        if my_money ~= item_unit.get_money_byid(5) then
            return true, '购买成功'
        end
        decider.sleep(500)
    end
    return false, '购买超时'
end

------------------------------------------------------------------------------------
-- [行为] 物品下架
--
-- @tparam      integer     id              物品ID
-- @treturn     boolean
-- @usage
-- exchange_ent.down_item(物品ID)
------------------------------------------------------------------------------------
exchange_ent.down_item = function(id)
    --通过重量判断是否下架成功
    local bag_weight = item_unit.get_bag_weight()
    exchange_unit.down_item(id)
    for i = 1, 10 do
        if bag_weight ~= item_unit.get_bag_weight() then
            return true, '下架成功'
        end
        decider.sleep(500)
    end
    return false, '下架超时'
end

------------------------------------------------------------------------------------
-- [行为] 结算交易行
--
-- @treturn     boolean
-- @usage
-- exchange_ent.calcul_gold()
------------------------------------------------------------------------------------
function exchange_ent.calcul_gold()
    --通过交易金币判断是否结算成功
    local my_money = item_unit.get_money_byid(5)
    exchange_unit.calcul_gold()
    for i = 1, 20 do
        if my_money ~= item_unit.get_money_byid(5) then
            return true, '结算成功'
        end
        decider.sleep(500)
    end
    return false, '结算超时'
end

------------------------------------------------------------------------------------
-- [行为] 领取购买物品
--
-- @treturn     boolean
-- @usage
-- exchange_ent.item_withdraw()
------------------------------------------------------------------------------------
function exchange_ent.item_withdraw()
    --通过背包重量判断是否领取成功
    local bag_weight = item_unit.get_bag_weight()
    exchange_unit.item_withdraw()
    for i = 1, 20 do
        if bag_weight ~= item_unit.get_bag_weight() then
            return true, '领取成功'
        end
        decider.sleep(500)
    end
    return false, '领取超时'
end

------------------------------------------------------------------------------------
-- [条件] 判断物品是否需要下架
--
-- @treturn     boolean
-- @usage
-- exchange_ent.take_down()
------------------------------------------------------------------------------------
exchange_ent.take_down = function()
    local ret_b = false
    --获取上架物品信息
    local sell_list = exchange_ent.get_sell_list()
    for i = 1, #sell_list do
        local down_item = false
        local ret1 = sell_list[i]
        if ret1.sale_status == 1 then
            --通过上架时间判断是否下架
            if ret1.over_time - os.time() <= 300 then
                down_item = true
            end
        end
        if down_item or ret1.sale_status == 3 then
            ret_b = exchange_ent.wa_down_item (ret1.id)
        end
    end
    return ret_b
end

------------------------------------------------------------------------------------
-- [条件] 是否有可领取的购买物品
--
-- @treturn     boolean
-- @usage
-- exchange_ent.receipt()
------------------------------------------------------------------------------------
exchange_ent.receipt = function()
    local ret_b = false
    game_ent.open_win_by_name('交易所')
    exchange_unit.request_receipt_list()--  -- 请求金币结算列表 要延时
    decider.sleep(2000)
    --是否有可领取的购买物品
    if exchange_unit.has_buy_item() then
        ret_b = exchange_ent.wa_item_withdraw()
    end
    return ret_b
end

------------------------------------------------------------------------------------
-- [条件] 是否可结算
--
-- @treturn     boolean
-- @usage
-- exchange_ent.settlement()
------------------------------------------------------------------------------------
exchange_ent.settlement = function()
    local ret_b = false
    game_ent.open_win_by_name('交易所')
    exchange_unit.request_calcul_list() --  -- 请求金币结算列表 要延时
    decider.sleep(2000)
    --是否可结算
    if exchange_unit.has_calcul_gold() then
        ret_b = exchange_ent.wa_calcul_gold()
    end
    return ret_b
end

------------------------------------------------------------------------------------
-- [条件] 判断物品是否能购买
--
-- @tparam      integer     res_id      物品res_id
-- @tparam      integer     level       物品等级
-- @treturn     boolean
-- @usage
-- exchange_ent.buy_item_by_res_id(res_id,物品等级)
------------------------------------------------------------------------------------
exchange_ent.buy_item_by_res_id = function(res_id,level)
    local ret_b = false
    level = level or 0
    if not res_id then
        return ret_b
    end
    game_ent.open_win_by_name('交易所')
    decider.sleep(2000)
    --搜索物品
    exchange_unit.search_item(res_id)
    decider.sleep(2000)
    --打开物品详情
    exchange_unit.get_next_page(res_id, level)
    decider.sleep(2000)
    for i = 1, exchange_unit.get_max_page() - 1 do
        -- 遍历每一页
        exchange_unit.get_next_page(res_id, level)
        decider.sleep(2000)
    end
    local exchange_obj = exchange_unit:new()
    local search_list = exchange_unit.search_item_list()
    for i = 1, #search_list do
        local obj = search_list[i]
        if exchange_obj:init(obj) then
            local num = exchange_obj:num()
            local total_price = exchange_obj:total_price()
            local price = total_price / num
            --判断物品价格是否低于最低购买，金币是否大于购买价格
            if price < redis_ent['最低购买'] and item_unit.get_money_byid(5) > total_price  then
                ret_b = exchange_ent.wa_buy_item(exchange_obj:id(), num, total_price)
                break
            end
        end
    end
    exchange_obj:delete()
    return ret_b
end

------------------------------------------------------------------------------------
-- [读取] 获取物品价格信息表
--
-- @tparam      integer     res_id              物品信息
-- @tparam      integer     level               物品等级
-- @treturn     t
-- @tfield[t]   integer     obj                 物品实例对象
-- @tfield[t]   integer     id                  物品ID
-- @tfield[t]   integer     sale_player_id      卖家Id
-- @tfield[t]   integer     res_ptr             物品资源指针
-- @tfield[t]   integer     total_price         总价
-- @tfield[t]   integer     num                 物品数量
-- @tfield[t]   integer     price               单价
-- @tfield[t]   integer     expire_time         到期时间
-- @usage
-- local info = exchange_ent.get_item_min_price(物品信息,物品等级)
-- print_r(info)
------------------------------------------------------------------------------------
exchange_ent.get_item_min_price = function(res_id, level)
    local exchange_item_info = {}
    level = level or 0
    game_ent.open_win_by_name('交易所')
    decider.sleep(2000)
    --搜索物品
    exchange_unit.search_item(res_id)
    decider.sleep(2000)
    --打开物品详情
    exchange_unit.get_next_page(res_id, level)
    decider.sleep(2000)
    for i = 1, exchange_unit.get_max_page() - 1 do
        -- 遍历每一页
        exchange_unit.get_next_page(res_id, level)
        decider.sleep(2000)
    end
    -- 获取交易行价格信息表
    exchange_item_info = exchange_ent.exchange_item_info()
    return exchange_item_info
end

------------------------------------------------------------------------------------
-- [读取] 获取交易行当前页面的物品信息
--
-- @treturn     t
-- @tfield[t]    integer    obj                 物品实例对象
-- @tfield[t]    integer    id                  物品ID
-- @tfield[t]    integer    sale_player_id      卖家Id
-- @tfield[t]    integer    res_ptr             物品资源指针
-- @tfield[t]    integer    total_price         总价
-- @tfield[t]    integer    num                 物品数量
-- @tfield[t]    integer    price               单价
-- @tfield[t]    integer    expire_time         到期时间
-- @usage
-- local info = exchange_ent.exchange_item_info()
-- print_r(info)
------------------------------------------------------------------------------------
function exchange_ent.exchange_item_info()
    local exchange_item_info = {}
    local exchange_obj = exchange_unit:new()
    local search_list = exchange_unit.search_item_list()
    for i = 1, #search_list do
        local obj = search_list[i]
        if exchange_obj:init(obj) then
            local num = exchange_obj:num()
            local total_price = exchange_obj:total_price()
            local info = {
                obj = obj,
                id = exchange_obj:id(),
                sale_player_id = exchange_obj:sale_player_id(), -- 卖家Id
                total_price = exchange_obj:total_price(), -- 总价
                num = exchange_obj:num(), -- 数量
                price = total_price / num,
                expire_time = exchange_obj:expire_time(), -- 到期时间
            }
            table.insert(exchange_item_info, info)
        end
    end
    exchange_obj:delete()
    --排序价格
    table.sort(exchange_item_info, function(a, b) return a.price < b.price end)
    return exchange_item_info
end

------------------------------------------------------------------------------------
-- [读取] 获取正在出售的信息
--
-- @treturn     t
-- @tfield[t]    integer    obj                 物品实例对象
-- @tfield[t]    integer    id                  物品ID
-- @tfield[t]    integer    sale_player_id      卖家Id
-- @tfield[t]    integer    res_ptr             物品资源指针
-- @tfield[t]    integer    total_price         总价
-- @tfield[t]    integer    num                 物品数量
-- @tfield[t]    integer    price               单价
-- @tfield[t]    integer    expire_time         到期时间
-- @usage
-- local info = exchange_ent.get_sell_list()
-- print_r(info)
------------------------------------------------------------------------------------
exchange_ent.get_sell_list = function()
    game_ent.open_win_by_name('交易所')
    local exchange_obj = exchange_unit:new()
    -- 请求出售列表
    exchange_unit.request_sale_list()
    decider.sleep(1500)
    -- 取自己出售物品列表
    local sell_list = exchange_unit.sell_item_list()
    local ret = {}
    for i = 1, #sell_list do
        local obj = sell_list[i]
        if exchange_obj:init(obj) then
            local ret1 = {}
            ret1.obj = obj
            ret1.id = exchange_obj:id()
            ret1.sale_item_res_id = exchange_obj:sale_item_res_id() -- 物品资源ID
            ret1.sale_status = exchange_obj:sale_status()  -- 状态 1 出售中，0审核中
            ret1.over_time = exchange_obj:over_time() -- 结束时间
            ret1.sale_price = exchange_obj:sale_price()  -- 出售价格
            ret1.sale_num = exchange_obj:sale_num() -- 出售数量
            table.insert(ret, ret1)
        end
    end
    exchange_obj:delete()
    return ret
end

------------------------------------------------------------------------------------
-- [内部] 将对象转换为字符串
--
-- @local
-- @treturn      string                     模块名称
------------------------------------------------------------------------------------
function exchange_ent.__tostring()
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
exchange_ent.__newindex = function(t, k, v)
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
exchange_ent.__index = exchange_ent

------------------------------------------------------------------------------------
-- [构造] 创建一个新的实例
--
-- @local
-- @tparam       table     args             可选参数，用于初始化新实例
-- @treturn      table                      新创建的实例
------------------------------------------------------------------------------------
function exchange_ent:new(args)
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
    return setmetatable(new, exchange_ent)
end

-------------------------------------------------------------------------------------
-- 返回实例对象
-------------------------------------------------------------------------------------
return exchange_ent:new()

-------------------------------------------------------------------------------------