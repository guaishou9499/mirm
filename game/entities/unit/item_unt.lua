------------------------------------------------------------------------------------
-- game/entities/item_unt.lua
--
-- 这个模块主要是项目内物品相关功能操作。
--
-- @module      item_unt
-- @author      admin
-- @license     MIT
-- @release     v1.0.0 - 2023-03-22
-- @copyright   2023
-- @usage
-- local item_unt = import('game/entities/item_unt.lua')
------------------------------------------------------------------------------------

-- 模块定义
---@class item_unt
local item_unt = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-03-22 - Initial release',
    -- 模块名称
    MODULE_NAME = 'item_unt module',
    -- 只读模式
    READ_ONLY = false,
}

-- 实例对象
local this = item_unt
-- 日志模块
local trace = trace
-- 决策模块
local decider = decider
---@type item_res
local item_res = import('game/resources/item_res')
------------------------------------------------------------------------------------
-- [事件] 预载函数(重载脚本)
------------------------------------------------------------------------------------
item_unt.super_preload = function()
    item_ctx = item_unit:new()
    this.delete_item = decider.run_action_wrapper('丢弃物品', this.delete_item)
    this.wt_open_box_by_name = decider.run_timeout_wrapper('打开箱子', this.open_box_by_name, 15)
end

--------------------------------------------------------------------------------
-- [读取] 根据物品名称获取物品信息
--
-- @static
-- @tparam       string    args             物品名称
-- @tparam       string    any_key          物品key值
-- @tparam       string    ...              可变参数，需要获取的物品信息
-- @treturn      t                          包含物品选择信息的 table，物品信息包括：
-- @tfield[t]    integer   obj              物品实例对象
-- @tfield[t]    string    name             物品名称
-- @tfield[t]    integer   res_ptr          物品资源指针
-- @tfield[t]    integer   id               物品ID
-- @tfield[t]    integer   type             物品类型
-- @tfield[t]    integer   num              物品数量
-- @tfield[t]    integer   race             物品种族
-- @tfield[t]    integer   level            物品等级
-- @tfield[t]    integer   quality          物品品质
-- @tfield[t]    integer   res_id           物品资源ID
-- @tfield[t]    integer   equip_type       物品装备类型
-- @tfield[t]    integer   equip_pos        物品装备位置
-- @tfield[t]    integer   durability       物品耐久度
-- @tfield[t]    integer   max_durability   物品最大耐久度
-- @usage
-- local info = item_unt.get_item_info('物品名称',物品key值,物品ID,物品资源指针...)
-- print_r(info)
--------------------------------------------------------------------------------
function item_unt.get_item_info(args, any_key, ...)
    local result = { ... }
    local ret_t = {}
    for _, v in ipairs(item_unit.list(0)) do
        if item_ctx:init(v, 0) and item_ctx:num() > 0 and args == item_ctx[any_key](item_ctx) then
            for k, j in ipairs(result) do
                k = item_ctx[j](item_ctx)
                ret_t[j] = k
            end
            break
        end
    end
    return ret_t
end

--------------------------------------------------------------------------------
-- [读取] 根据物品名称获取物品信息
--
-- @static
-- @tparam       string    args             物品名称
-- @tparam       string    any_key          物品key值
-- @tparam       string    ...              可变参数，需要获取的物品信息
-- @treturn      t                          包含物品选择信息的 table，物品信息包括：
-- @tfield[t]    integer   obj              物品实例对象
-- @tfield[t]    string    name             物品名称
-- @tfield[t]    integer   res_ptr          物品资源指针
-- @tfield[t]    integer   id               物品ID
-- @tfield[t]    integer   type             物品类型
-- @tfield[t]    integer   num              物品数量
-- @tfield[t]    integer   race             物品种族
-- @tfield[t]    integer   level            物品等级
-- @tfield[t]    integer   quality          物品品质
-- @tfield[t]    integer   res_id           物品资源ID
-- @tfield[t]    integer   equip_type       物品装备类型
-- @tfield[t]    integer   equip_pos        物品装备位置
-- @tfield[t]    integer   durability       物品耐久度
-- @tfield[t]    integer   max_durability   物品最大耐久度
-- @usage
-- local info = item_unt.get_item_info('物品名称',物品key值,物品ID,物品资源指针...)
-- print_r(info)
function item_unt.select_get_item_info_by_args(args, any_key, ...)
    return item_unt.get_item_info(args, any_key, ...)
end

--------------------------------------------------------------------------------
-- [读取] 根据物品资源ID获取物品信息
--
-- @static
-- @tparam       integer   res_id           物品资源ID
-- @treturn      t                          包含物品信息的 table，包括：
-- @tfield[t]    integer   obj              物品实例对象
-- @tfield[t]    string    name             物品名称
-- @tfield[t]    integer   res_ptr          物品资源指针
-- @tfield[t]    integer   id               物品ID
-- @tfield[t]    integer   type             物品类型
-- @tfield[t]    integer   num              物品数量
-- @tfield[t]    integer   race             物品种族
-- @tfield[t]    integer   level            物品等级
-- @tfield[t]    integer   quality          物品品质
-- @tfield[t]    integer   res_id           物品资源ID
-- @tfield[t]    integer   equip_type       物品装备类型
-- @tfield[t]    integer   equip_pos        物品装备位置
-- @tfield[t]    integer   durability       物品耐久度
-- @tfield[t]    integer   max_durability   物品最大耐久度
-- @usage
-- local info = item_unt.get_item_info_by_res_id('物品资源ID')
-- print_r(info)
--------------------------------------------------------------------------------
function item_unt.get_item_info_by_res_id(res_id)
    local result = {}
    for _, v in ipairs(item_unit.list(0)) do
        if item_ctx:init(v, 0) and item_ctx:res_id() == res_id then
            result = {
                obj = v,
                name = item_ctx:name(),
                res_ptr = item_ctx:res_ptr(),
                id = item_ctx:id(),
                type = item_ctx:type(),
                num = item_ctx:num(),
                race = item_ctx:race(),
                level = item_ctx:level(),
                quality = item_ctx:quality(),
                res_id = res_id,
                equip_type = item_ctx:equip_type(),
                equip_pos = item_ctx:equip_pos(),
                durability = item_ctx:durability(),
                max_durability = item_ctx:max_durability()
            }
            break
        end
    end
    return result
end

--------------------------------------------------------------------------------
-- [读取] 获取背包中所有物品信息
--
-- @treturn      t                          包含物品信息的 table，包括：
-- @tfield[t]    integer   obj              物品实例对象
-- @tfield[t]    string    name             物品名称
-- @tfield[t]    integer   res_ptr          物品资源指针
-- @tfield[t]    integer   id               物品ID
-- @tfield[t]    integer   type             物品类型
-- @tfield[t]    integer   num              物品数量
-- @tfield[t]    integer   race             物品种族
-- @tfield[t]    integer   level            物品等级
-- @tfield[t]    integer   quality          物品品质
-- @tfield[t]    integer   res_id           物品资源ID
-- @tfield[t]    integer   equip_type       物品装备类型
-- @tfield[t]    integer   equip_pos        物品装备位置
-- @tfield[t]    integer   durability       物品耐久度
-- @tfield[t]    integer   max_durability   物品最大耐久度
-- @usage
-- local info = item_unt.get_item_info_by_res_id('物品资源ID')
-- print_r(info)
--------------------------------------------------------------------------------
function item_unt.get_bag_item_info()
    local result = {}
    for _, v in ipairs(item_unit.list(0)) do
        if item_ctx:init(v, 0) then
            local result1 = {
                obj = v,
                name = item_ctx:name(),
                res_ptr = item_ctx:res_ptr(),
                id = item_ctx:id(),
                type = item_ctx:type(),
                num = item_ctx:num(),
                race = item_ctx:race(),
                level = item_ctx:level(),
                quality = item_ctx:quality(),
                res_id = res_id,
                equip_type = item_ctx:equip_type(),
                equip_pos = item_ctx:equip_pos(),
                durability = item_ctx:durability(),
                max_durability = item_ctx:max_durability()
            }
            table.insert(result,result1)
        end
    end
    return result
end

--------------------------------------------------------------------------------
-- 通过装备位置获取装备信息
--------------------------------------------------------------------------------
function item_unt.get_bag_equip_info_bypos(i)
    local result = {}
    for _, v in ipairs(item_unit.list(1)) do
        if item_ctx:init(v, 1) and item_ctx:equip_pos() == i then
            result = {
                obj = v,
                name = item_ctx:name(),
                res_ptr = item_ctx:res_ptr(),
                id = item_ctx:id(),
                type = item_ctx:type(),
                num = item_ctx:num(),
                race = item_ctx:race(),
                level = item_ctx:level(),
                quality = item_ctx:quality(),
                res_id = item_ctx:res_id(),
                equip_type = item_ctx:equip_type(),
                equip_pos = i,
                durability = item_ctx:durability(),
                max_durability = item_ctx:max_durability()
            }
            break
        end
    end
    return result
end

--------------------------------------------------------------------------------
-- 通过装备res_id获取最高装备耐久
--------------------------------------------------------------------------------
function item_unt.get_best_tool_info(res_id)
    local result = {}
    local durability = 0
    for _, v in ipairs(item_unit.list(0)) do
        if item_ctx:init(v, 0) and item_ctx:res_id() == res_id then
            local item_durability = item_ctx:durability()
            if item_durability > durability then
                durability = item_durability
                result = {
                    obj = v,
                    name = item_ctx:name(),
                    res_ptr = item_ctx:res_ptr(),
                    id = item_ctx:id(),
                    type = item_ctx:type(),
                    num = item_ctx:num(),
                    race = item_ctx:race(),
                    level = item_ctx:level(),
                    quality = item_ctx:quality(),
                    res_id = res_id,
                    equip_type = item_ctx:equip_type(),
                    equip_pos = item_ctx:equip_pos(),
                    durability = item_durability,
                    max_durability = item_ctx:max_durability()
                }
            end
        end
    end
    return result
end

--------------------------------------------------------------------------------
-- 通过装备res_id获取装备维修
--------------------------------------------------------------------------------
function item_unt.get_bag_equip_repea(res_id)
    local ret_n = -1
    for _, v in ipairs(item_unit.list(0)) do
        if item_ctx:init(v, 0) and item_ctx:res_id() == res_id then
            local durab = item_ctx:max_durability() - item_ctx:durability()
            if durab > 0 then
                ret_n = item_ctx:id()
                break
            end
        end
    end
    return ret_n
end

-------------------------------------------------------------------------------
-- [行为] 通过物品名打开指定的箱子(非选择类)
--
-- @tparam    string    name    箱子名字
-- @treturn   boolean           打开箱子成功 true, 否则 false 和错误信息
-- @usage
-- local success, msg = item_unt.open_box_by_name(id1, id2, ...)
-------------------------------------------------------------------------------
function item_unt.open_box_by_name(name)
    --通过物品名字获取物品id和num
    local box_info = item_unt.select_get_item_info_by_args(name, 'name', 'num', 'id')
    local ret_s = ''
    if not table_is_empty(box_info) then
        while decider.is_working() do
            --物品使用前数量
            local box_num = box_info.num
            item_unit.open_box(box_info.id)
            decider.sleep(2000)
            --通过物品名字获取物品id和num，通过物品数量发生变化判断使用成功
            box_info = item_unt.select_get_item_info_by_args(name, 'name', 'num', 'id')
            if table_is_empty(box_info) or box_info.num ~= box_num then
                return true
            end
            decider.sleep(2000)
        end
        ret_s = '打开箱子异常/超时'
    else
        ret_s = '没有可打开的箱子'
    end
    return false, ret_s
end

-------------------------------------------------------------------------------
-- [行为] 丢弃背包中的物品
--
-- @tparam       integer   ...              可变参数，需要丢弃的物品列表
-- @treturn      boolean                    丢弃成功 true, 否则 false 和错误信息
-- @usage
-- local success, msg = item_unt.delete_item(id1, id2, ...)
-------------------------------------------------------------------------------
function item_unt.delete_item(...)
    return true
end

-------------------------------------------------------------------------------
-- [读取] 通用物品res_id获取物品总数量
--
-- @tparam       integer   res_id       物品资源ID
-- @treturn      integer                物品总数量
-- @usage
-- local ret_n = item_unt.get_num_by_red_id(物品资源ID)
-------------------------------------------------------------------------------
function item_unt.get_num_by_red_id(res_id)
    local ret_n = 0
    for _, v in ipairs(item_unit.list(0)) do
        if item_ctx:init(v, 0) and item_ctx:res_id() == res_id then
            ret_n = ret_n + item_ctx:num()
        end
    end
    return ret_n
end

-------------------------------------------------------------------------------
-- [读取] 通用获取可出售物品信息
--
-- @treturn      table
-- @usage
-- local ret_t = item_unt.get_num_by_red_id()
-------------------------------------------------------------------------------
function item_unt.get_sell_list()
    local ret_t = {}
    for _, v in ipairs(item_unit.list(0)) do
        if item_ctx:init(v, 0) then
            if item_res.SELL_BIND[item_ctx:res_id()] then
                ret_t[#ret_t + 1] = item_ctx:id()
            end
        end
    end
    return ret_t
end

---------------------------------------------------------------------
-- [读取] 通用获取信息函数
--
-- @tparam   object     unit        unit对象
-- @tparam   table      cond        筛选条件 {属性, 值, 比较函数}
-- @tparam   string     fields      需要获取的字段
-- @tparam   boolean    records     获取数据个数 false 单个 true 多个
-- @tparam   table      init        初始条件 {类型, 参数}
-- @treturn  table                  需要获取字段的表 或者 空表
-- @usage
-- local info = this.get_info(quest_unit, {{'id', 1, this.eq},}, {'name'}, false, {})
-- print_r(info)
---------------------------------------------------------------------
item_unt.get_info = function(unit, cond, fields, records, init, obj)
    local ret = {}
    local type = nil
    local arg = nil

    if not table_is_empty(init) then
        if init[1] then
            type = init[1]
        end
        if init[2] then
            arg = init[2]
        end
    end
    --xxmsg(type)
    local list = type and unit.list(type) or unit.list()
    --print_t(list)
    local ctx = unit:new()
    for i = 1, #list do
        local obj = obj or list[i]
        if arg and ctx:init(obj, arg) or ctx:init(obj) then
            local filter = true
            for i = 1, #cond do
                local field_value = ctx[cond[i][1]](ctx)
                local eval = function(a, b, op)
                    return op(a, b)
                end
                if not eval(field_value, cond[i][2], cond[i][3]) then
                    filter = false
                    break
                end
            end
            if filter then
                local t = {}
                t.obj = obj
                for j = 1, #fields do
                    t[fields[j]] = ctx[fields[j]](ctx)
                end
                ret[#ret + 1] = t
                if not records then
                    break
                end
            end
        end
    end
    ctx:delete()
    return ret
end

------------------------------------------------------------------------------------
-- [内部] 将对象转换为字符串
--
-- @local
-- @treturn      string                     模块名称
------------------------------------------------------------------------------------
function item_unt.__tostring()
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
item_unt.__newindex = function(t, k, v)
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
item_unt.__index = item_unt

------------------------------------------------------------------------------------
-- [构造] 创建一个新的实例
--
-- @local 
-- @tparam       table     args             可选参数，用于初始化新实例
-- @treturn      table                      新创建的实例
------------------------------------------------------------------------------------
function item_unt:new(args)
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
    return setmetatable(new, item_unt)
end

-------------------------------------------------------------------------------------
-- 返回实例对象
-------------------------------------------------------------------------------------
return item_unt:new()

-------------------------------------------------------------------------------------