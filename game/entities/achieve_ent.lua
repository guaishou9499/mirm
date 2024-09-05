------------------------------------------------------------------------------------
-- game/entities/achieve_ent.lua
--
-- 这个模块主要是项目内冒险（成就、见闻录）相关功能操作。
--
-- @module      achieve_ent
-- @author      admin
-- @license     MIT
-- @release     v1.0.0 - 2023-04-21
-- @copyright   2023
-- @usage
-- local achieve_ent = import('game/entities/achieve_ent.lua')
------------------------------------------------------------------------------------

-- 模块定义
---@class achieve_ent
local achieve_ent = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-04-21 - Initial release',
    -- 模块名称
    MODULE_NAME = 'achieve_ent module',
    -- 只读模式
    READ_ONLY = false,
}

-- 实例对象
local this = achieve_ent
-- 日志模块
local trace = trace
-- 决策模块
local decider = decider

-- 引用模块
---@type ui_res
local ui_res = import('game/resources/ui_res')
---@type redis_ent
local redis_ent = import('game/entities/redis_ent')
---@type game_ent
local game_ent = import('game/entities/game_ent')
---@type achieve_res
local achieve_res = import('game/resources/achieve_res')

------------------------------------------------------------------------------------
-- [事件] 预载函数(重载脚本)
------------------------------------------------------------------------------------
achieve_ent.super_preload = function()
    -- 模块入口
    achieve_ent.wc_get_adventure = decider.run_condition_wrapper('每日冒险', this.get_adventure, function()
        if local_player:level() < 18 then
            return false
        end
        -- 判断今日是否检查过冒险窗口
        return redis_ent.read_ini_user_today(main_ctx:c_server_name() .. '每日领取', local_player:name() .. '每日冒险') == ''
    end)
    -- 行为判断
    achieve_ent.wn_get_seeing = decider.run_normal_wrapper('检查见闻录', this.get_seeing)
    achieve_ent.wn_get_achievement = decider.run_normal_wrapper('检查成就', this.get_achievement)
    -- 行为
    achieve_ent.wa_receive_seeing = decider.run_action_wrapper('领取见闻录奖励', this.receive_seeing)
    achieve_ent.wa_receive_achievement = decider.run_action_wrapper('领取成就奖励', this.receive_achievement)
end

---------------------------------------------------------------------
-- [行为] 每日冒险(外部调用)
--
-- @usage
-- achieve_ent.get_adventure()
---------------------------------------------------------------------
achieve_ent.get_adventure = function()
    -- 打开冒险窗口界面，失败退出
    game_ent.open_win_by_name('冒险')
    -- 冒险列表
    local adventure_list = {
        ['见闻录'] = { func = function()
            --achieve_ent.wn_get_seeing()
        end },
        ['成就'] = { func = function()
            achieve_ent.wn_get_achievement()
        end },
    }
    -- 执行冒险列表对应函数
    for i, v in pairs(adventure_list) do
        v.func()
    end
    -- 写入每日冒险打开次数
    redis_ent.write_day_ini_user(main_ctx:c_server_name() .. '每日领取', local_player:name() .. '每日冒险', 1)
    -- 关闭冒险窗口
    game_ent.wc_close_window()
end

---------------------------------------------------------------------
-- [行为] 每日见闻录
--
-- @usage
-- achieve_ent.get_seeing()
---------------------------------------------------------------------
achieve_ent.get_seeing = function()
    local achieve_log = achieve_res.ACHIEVE_LOG
    --领取4种不同的见闻奖励
    for i = 1, 4 do
        --获取见闻录完成度（百分百）
        local c_pre = achieve_unit.get_collection_rate(i)/100
        for k,v in pairs(achieve_log) do
            local c_pre_id = v.c_pre_id
            local c_pre_value = v.c_pre_value
            --完成度达到指定百分比且未领取，领取奖励
            if c_pre >= c_pre_value and not achieve_unit.is_receive_reward(i, c_pre_id) then
                achieve_ent.wa_receive_seeing(i, c_pre_id)
            end
        end
    end
end

---------------------------------------------------------------------
-- [行为] 领取见闻录奖励
--
-- @tparam          integer      id     见闻录id
-- @tparam          integer      idx    序号
-- @treturn         boolean
-- @usage
-- achieve_ent.receive_seeing(见闻录id, 序号)
---------------------------------------------------------------------
achieve_ent.receive_seeing = function(id, idx)
    --通过背包重量判断是否领取成功
    local bag_weight = item_unit.get_bag_weight()
    achieve_unit.receive_reward(id, idx)
    decider.sleep(500)
    for i = 1, 10 do
        if ui_unit.get_parent_window(ui_res.WIN['冒险'].win_name, true) == 0 then
            return false, '冒险窗口已关闭'
        end
        if bag_weight ~= item_unit.get_bag_weight() then
            return true, '领取见闻录奖励成功'
        end
        decider.sleep(500)
    end
    return false, '领取见闻录奖励超时'
end

---------------------------------------------------------------------
-- [行为] 每日成就
--
-- @treturn         boolean
-- @usage
-- achieve_ent.get_achievement()
---------------------------------------------------------------------
achieve_ent.get_achievement = function()
    while decider.is_working() do
        local is_get = false
        --领取5种不同的成就奖励
        for i = 1, 5 do
            achieve_unit.request_achieve(i) --获取成就数据
            decider.sleep(2000)
            --判断可领成就数量大于0，则领取成就
            if achieve_unit.get_finish_achieve_num() > 0 then
                achieve_ent.wa_receive_achievement()
                is_get = true
            end
        end
        if not is_get then
            break
        end
        decider.sleep(500)
    end
end

------------------------------------------------------------------------------------
-- [行为] 领取成就物品
--
-- @treturn      boolean
-- @usage
-- achieve_ent.receive_achievement()
------------------------------------------------------------------------------------
achieve_ent.receive_achievement = function()
    --通过可领成就物品小于0判断领取成功
    achieve_unit.get_achieve_aware()
    decider.sleep(500)
    for i = 1, 30 do
        if ui_unit.get_parent_window(ui_res.WIN['冒险'].win_name, true) == 0 then
            return false, '冒险窗口已关闭'
        end
        if achieve_unit.get_finish_achieve_num() <= 0 then
            return true, '领取成就物品'
        end
        decider.sleep(500)
    end
    return false, '领取成就物品超时'
end

------------------------------------------------------------------------------------
-- [内部] 将对象转换为字符串
--
-- @local
-- @treturn      string                     模块名称
------------------------------------------------------------------------------------
function achieve_ent.__tostring()
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
achieve_ent.__newindex = function(t, k, v)
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
achieve_ent.__index = achieve_ent

------------------------------------------------------------------------------------
-- [构造] 创建一个新的实例
--
-- @local
-- @tparam       table     args             可选参数，用于初始化新实例
-- @treturn      table                      新创建的实例
------------------------------------------------------------------------------------
function achieve_ent:new(args)
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
    return setmetatable(new, achieve_ent)
end

-------------------------------------------------------------------------------------
-- 返回实例对象
-------------------------------------------------------------------------------------
return achieve_ent:new()

-------------------------------------------------------------------------------------