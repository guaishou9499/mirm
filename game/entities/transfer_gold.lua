------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @author:   core
-- @email:    88888@qq.com
-- @date:     2022-10-30
-- @module:   transfer_gold
-- @describe: 转金模块
-- @version:  v1.0
--
---@class transfer_gold
local transfer_gold = {

    client_money = 1, --统计金币连接redis 对象
    ip = '127.0.0.1', --默认金币统计服务器IP

}

local this = transfer_gold

---@type redis_ent
local redis_ent = import('game/entities/redis_ent')
---@type item_unt
local item_unt = import('game/entities/unit/item_unt')
---@type exchange_ent
local exchange_ent = import('game/entities/exchange_ent')
---@type item_res
local item_res = import('game/resources/item_res')

--------------------------------------------------------------------------------
-- 连接金币统计服务器
--
-- @treturn      bool
-- @usage
-- local bool = redis_ent.connect_redis()
--------------------------------------------------------------------------------
transfer_gold.connect_gold_redis = function()
    local ret_b = false
    local ip = redis_ent.read_ini_computer('本机设置.ini', '连接金币服务器设置', '连接IP')
    if ip == '' then
        redis_ent.write_ini_computer('本机设置.ini', '连接REDIS设置', '机器ID', '1')
    else
        this.IP = ip
    end

    this.CLIENT_MONEY = redis_ctx

    if this.CLIENT_MONEY:connect(this.IP, 6379) then
        ret_b = true
    end
    if type(this.CLIENT_MONEY) == "number" then
    end
    return ret_b
end

-- 小号写入金币
function transfer_gold.小号写入金币()
    if transfer_gold.统计金币开关() == 1 then
        local PATH = '传奇M:金币统计:' .. main_ctx:c_server_name()
        --读取Rides账号金币记录
        local data_r = redis_ent.get_json_redis(PATH, this.CLIENT_MONEY)
        --判断当前账号数据是否存在redis表内
        local indx = transfer_gold.assign_is_exist(data_r)
        --读取当前账号金币数据
        local table_r = {
            name = local_player:name(),
            money = item_unit.get_money_byid(5),
            time = os.time(),
            ip = main_ctx:get_local_ip(),
        }
        --不存在就直接插入数据到Table
        if indx == 0 then
            table.insert(data_r, table_r)
        else
            --存在就修改
            data_r[indx].name = local_player:name()
            data_r[indx].money = item_unit.get_money_byid(5)
            data_r[indx].time = os.time()
            data_r[indx].ip = main_ctx:get_local_ip()
        end
        --把最终List写入Rides
        if #data_r ~= 0 then
            redis_ent.set_json_redis(PATH, data_r, this.CLIENT_MONEY)
        end
    end
end

--判断表指定的内容是否存在
function transfer_gold.assign_is_exist(list)
    local indx = 0
    local name = local_player:name()
    if #list > 0 then
        for i = 1, #list do
            if list[i].name == name then
                indx = i
                break
            end
        end
    end
    return indx
end

--判断客户端是否开启小号写入金币到服务器 --统计金币开关
function transfer_gold.统计金币开关()
    local ret = -1
    local PATH = '传奇M:金币统计:金币统计开关'
    -- 获取用户金币开关设置
    local data_r = redis_ent.get_json_redis(PATH, this.CLIENT_MONEY)
    -- 不存在写入配置
    if table_is_empty(data_r) then
        local ini_r = { ['金币统计开关'] = 0, ['最小金币'] = 500 }
        redis_ent.set_json_redis(PATH, ini_r, this.CLIENT_MONEY)
        -- 金币低于最小金币不统计
    elseif item_unit.get_money_byid(5) < tonumber(data_r['最小金币']) then
        ret = 0
        -- 金币开关为关闭不统计
    elseif tonumber(data_r['金币统计开关']) == 1 then
        ret = 1
    end
    return ret
end

--服务器名称统计金币
--参数1：服务器名称列表
function transfer_gold.服务器名称统计金币(server_list)
    --不是金币服务器上的号不统计金币
    if main_ctx:get_local_ip() == this.IP then
        --在上架中不统计
        local PATH = '传奇M:金币统计:收金号配置'
        local data = redis_ent.get_json_redis(PATH, this.CLIENT_MONEY)
        transfer_gold.初始化收金号配置(data)
        if data['开关'] == 0 then
            if not table_is_empty(server_list) then
                local max_money = 0
                for j = 1, #server_list do
                    local data_r = {}
                    local money_r = 0
                    PATH = '传奇M:金币统计:' .. server_list[j]
                    data_r = redis_ent.get_json_redis(PATH, this.CLIENT_MONEY)
                    if not table_is_empty(data_r) then
                        for i = 1, #data_r do
                            -- 服务器金币
                            money_r = money_r + data_r[i].money
                        end
                    end
                    if money_r > 0 then
                        -- 总金币
                        max_money = max_money + money_r
                    end
                end
            end
        end
    end
end

--初始化收金号配置
function transfer_gold.初始化收金号配置(data)
    if table_is_empty(data) then
        local PATH = '传奇M:金币统计:收金号配置'
        -- 初始化收金号配置
        local data_r = { ['开关'] = 0, ['角色名称'] = '', ['金币'] = 0, ['区服'] = '', ['进行中'] = 0 }
        redis_ent.set_json_redis(PATH, data_r, this.CLIENT_MONEY)
    end
end

--收金号上架拍卖物品
--参数1：角色名称
--参数2：服务器名称
--参数3：买家订单金额
function transfer_gold.收金号上架拍卖物品()
    --判断当前机器是否为金币服务器
    if main_ctx:get_local_ip() == this.IP then
        --取收金号配置信息
        local PATH = '传奇M:金币统计:收金号配置'
        local data_r = redis_ent.get_json_redis(PATH, this.CLIENT_MONEY)
        --没有取到收金号配置信息
        if table_is_empty(data_r) then
            return
        end
        --判断当前角色是否为收金号
        if data_r['开关'] ~= 1 then
            return
        end
        if data_r['进行中'] ~= 1 then
            return
        end
        if local_player:name() == data_r['角色名称'] then
            return
        end
        if main_ctx:c_server_name() == data_r['区服'] then
            return
        end
        --订单分配
        local money_list, data_list = transfer_gold.订单金额分配(data_r['区服'], data_r['金币'])
        -- 获取信息列表
        if not table_is_empty(data_list) then
            for i = 1, #data_list do
                -- 取可上架物品
                local item_info = transfer_gold.取可上架物品()
                if not table_is_empty(item_info) then
                    local num = math.random(5, 15)
                    -- 随机5~15个物品上架
                    exchange_unit.up_item(item_info[1].id, data_list[i].money, num)
                    sleep(2000)
                    -- 通过物品变化判断上架是否成功
                    if item_unt.get_num_by_red_id(item_info[1].res_id) < item_info[1].num then
                        -- 写入redis记录
                        transfer_gold.上架成功后写入Rides(data_list[i], money_list)
                        xxmsg('上架物品[' .. item_info[1].name .. '    数量：' .. num .. '   金币：' .. data_list[i].money .. ']成功')

                    else
                        xxmsg('上架物品[' .. item_info[1].name .. '    数量：' .. num .. '   金币：' .. data_list[i].money .. ']失败')
                    end
                end
            end
        end
    end
end

--根据订单金额分配上架笔数，返回上架金额列表
--参数1：服务器名称
--参数2：买家订单金额
function transfer_gold.订单金额分配(server_name, money)
    local ret = {}
    -- 未填写服务器
    if server_name == '' or not server_name then
        return ret
    end
    --判断铜币是否够上架
    if item_unit.get_money_byid(2) < money * 10 then
        return ret
    end
    local data_r = {}
    --判断当前机器是否为金币服务器
    if main_ctx:get_local_ip() == this.IP then
        --加上手续费
        local max_money = money + money * 0.06
        local money_r = 0
        local PATH = '传奇M:金币统计:' .. server_name
        --取指定大区金币表数据
        data_r = transfer_gold.根据IP地址排序(redis_ent.get_json_redis(PATH, this.CLIENT_MONEY))
        --没有取得数据，没库存了
        if not table_is_empty(data_r) then
            for i = 1, #data_r do
                if i >= 30 then
                    xxmsg(server_name .. "订单金额分配失败...订单数量不能超过30个，请减少金币后重试")
                    ret = {}
                    break
                end
                --累计金币
                money_r = money_r + data_r[i].money
                --写入分配表
                table.insert(ret, data_r[i])
                --判断金币是否达到订单金额
                if money_r >= max_money then
                    xxmsg(server_name .. "订单金额分配成功：" .. server_name .. '(' .. i .. '个账号' .. money_r .. '金币' .. ')')
                    break
                end

                --订单金额分配上架失败
                if i >= #data_r and money_r < max_money then
                    xxmsg(server_name .. "订单金额分配失败：" .. server_name .. '(' .. '库存金币:' .. money_r .. '小于：' .. max_money .. ')')
                    ret = {}
                end
            end
        else
            xxmsg(server_name .. "订单金额分配失败：金币不足,请检查库存")
        end
    end
    return data_r, ret
end

--取可上架物品
function transfer_gold.取可上架物品()
    local ret = {}
    local itme_list = transfer_gold.获取可出售物品list()
    if not table_is_empty(itme_list) then
        for i = 1, #itme_list do
            if itme_list[i].num >= 15 then
                table.insert(ret, itme_list[i])
                break
            end
        end
    else
        xxmsg('获取可出售物品list失败')
    end
    return ret
end

--出售的列表写入Rides
function transfer_gold.上架成功后写入Rides(info, money_list)
    if info == nil or money_list == nil then
        return
    end
    local data_r = {}
    local data = {}
    local info_r = info
    local PATH = '传奇M:金币统计:出售列表:' .. main_ctx:c_server_name()
    data = redis_ent.get_json_redis(PATH, this.CLIENT_MONEY)
    --循环取出拍卖正在出售的列表
    while not is_terminated() do
        data_r = exchange_ent.get_sell_list() --TODO:获取正在出售的列表
        sleep(500)
        if not table_is_empty(data_r) then
            break
        end
    end
    if not table_is_empty(data_r) then
        for k = 1, #data_r do
            if info_r.money == data_r[k].sale_price then
                info_r.id = data_r[k].id
                info_r.res_id = data_r[k].sale_item_res_id
                info_r.time = os.time()
                info_r.num = data_r[k].sale_num
                table.insert(data, info_r)
                break
            end
        end
        --  写入出售列表
        if redis_ent.set_json_redis(PATH, data, this.CLIENT_MONEY) then
            --删除
            for i = 1, #money_list do
                if money_list[i].name == info_r.name then
                    table.remove(money_list, i)
                    redis_ent.set_json_redis('传奇M:金币统计:' .. main_ctx:c_server_name(), money_list, this.CLIENT_MONEY)
                    break
                end
            end
        end
    end
end

--根据IP地址排序（一台机器全部出完）
function transfer_gold.根据IP地址排序(moey_list)
    local ret = {}
    local ip_list = {}
    local ret_list = {}
    --排序IP
    for i = 1, #moey_list do
        local ip = moey_list[i].ip
        if ret[ip] == nil then
            --保存IP后面还原要用
            table.insert(ip_list, ip)
            --创建IP索引表
            ret[ip] = {}
        end
        table.insert(ret[ip], moey_list[i])
    end
    --遍历IP，恢复Table返回
    for j = 1, #ip_list do
        --取IP索引
        for y = 1, #ret[ip_list[j]] do
            --取索引里的值，还原表
            local data = ret[ip_list[j]][y]
            table.insert(ret_list, data)
        end
    end
    return ret_list
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--购买收金号拍卖物品
function transfer_gold.购买收金号拍卖物品()
    local PATH = '传奇M:金币统计:出售列表:' .. main_ctx:c_server_name()
    local data_r = redis_ent.get_json_redis(PATH, this.CLIENT_MONEY)
    if not table_is_empty(data_r) then
        for i = 1, #data_r do
            if data_r[i].ip == main_ctx:get_local_ip() and data_r[i].name == local_player:name() then
                --超时清理上架信息
                if os.time() - data_r[i].time >= 36000 then
                    table.remove(data_r, i)
                    redis_ent.set_json_redis(PATH, data_r, transfer_gold.client_money)

                    --上架时间大于10分钟
                elseif os.time() - data_r[i].time >= 600 then
                    --判断物品是否上架
                    local res_id = data_r[i].res_id
                    local num = data_r[i].num
                    local money = data_r[i].money
                    local list_info = transfer_gold.取交易行指定物品信息(res_id, num, money)
                    if not table_is_empty(list_info) then
                        --购买
                        exchange_unit.buy_item(list_info[1].id, list_info[1].num, list_info[1].total_price)
                        --删除购买数据
                        table.remove(data_r, i)
                        redis_ent.set_json_redis(PATH, data_r, transfer_gold.client_money)
                        break
                    end
                end
            end
        end
    end
end

--取交易行指定物品信息
--参数1：资源ID
--参数2：数量
--参数3：总价
function transfer_gold.取交易行指定物品信息(res_id, num, price)
    local ret = {}
    local item_list = {}
    item_list = exchange_ent.get_item_min_price(res_id)
    if not table_is_empty(item_list) then
        for i = 1, #item_list do
            if item_list[i].num == num and item_list[i].total_price == price then
                table.insert(ret, item_list[i])
                break
            end
        end
    end
    return ret
end

--获取可出售物品list
function transfer_gold.获取可出售物品list()
    local ret = {}
    local items = item_res.NOT_IS_BIND
    for i, v in pairs(items) do
        if v.sell_num then
            local itemRet = item_unt.get_item_info_by_res_id(i)
            if not table_is_empty(itemRet) then
                itemRet.res_id = i
                itemRet.name = v.name
                table.insert(ret, itemRet)
            end
        end
    end
    return ret
end

-------------------------------------------------------------------------------------
-- 实例化新对象
function transfer_gold.__tostring()
    return "mirm transfer_gold package"
end

transfer_gold.__index = transfer_gold

function transfer_gold:new(args)
    local new = { }

    if args then
        for key, val in pairs(args) do
            new[key] = val
        end
    end

    -- 设置元表
    return setmetatable(new, transfer_gold)
end

-------------------------------------------------------------------------------------
-- 返回对象
return transfer_gold:new()

-------------------------------------------------------------------------------------