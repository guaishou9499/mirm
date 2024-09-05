------------------------------------------------------------------------------------
-- game/entities/mail_ent.lua
--
-- 这个模块主要是项目内物品相关功能操作。
--
-- @module      mail_ent
-- @author      admin
-- @license     MIT
-- @release     v1.0.0 - 2023-03-22
-- @copyright   2023
-- @usage
-- local mail_ent = import('game/entities/mail_ent.lua')
------------------------------------------------------------------------------------

-- 模块定义
---@class mail_ent
local mail_ent = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-03-22 - Initial release',
    -- 模块名称
    MODULE_NAME = 'mail_ent module',
    -- 只读模式
    READ_ONLY = false,
}

-- 实例对象
local this = mail_ent
-- 日志模块
local trace = trace
-- 决策模块
local decider = decider
---@type ui_res
local ui_res = import('game/resources/ui_res')
---@type redis_ent
local redis_ent = import('game/entities/redis_ent')
---@type game_ent
local game_ent = import('game/entities/game_ent')
------------------------------------------------------------------------------------
-- [事件] 预载函数(重载脚本)
------------------------------------------------------------------------------------
mail_ent.super_preload = function()
    -- 模块入口
    mail_ent.wc_daily_mail = decider.run_condition_wrapper('检查邮件', this.daily_mail, function()
        if local_player:level() < 18 then
            return false
        end
     return redis_ent.read_ini_user_today(main_ctx:c_server_name()..'每日领取',local_player:name()..'每日邮件') == ''
    end)
    -- 行为
    mail_ent.receive_mail = decider.run_action_wrapper('领取邮件', this.receive_mail)
end

------------------------------------------------------------------------------------
-- [行为] 每日邮件(外部调用)
--
-- @treturn      boolean
-- @usage
-- mail_ent.daily_mail()
------------------------------------------------------------------------------------
mail_ent.daily_mail = function()
    --邮箱的3种类型
    for i = 0, 2 do
        -- 打开邮件窗口
        game_ent.open_win_by_name('邮件')
        -- 获取邮箱信息
        mail_unit.request_mail_list(i)
        decider.sleep(2000)
        -- 判断邮箱是否可领取
        if mail_unit.has_reward() then
            -- 领取
            mail_ent.receive_mail()
        end
    end
    -- 记录每日领取邮箱次数
    redis_ent.write_day_ini_user(main_ctx:c_server_name()..'每日领取',local_player:name()..'每日邮件',1)
    -- 关闭窗口
    game_ent.close_window()
    return true, '邮件领取完毕'
end

------------------------------------------------------------------------------------
-- [行为] 领取邮件物品
--
-- @treturn      boolean
-- @usage
-- mail_ent.receive_mail()
------------------------------------------------------------------------------------
mail_ent.receive_mail = function()
    --通过邮件是否可领判断成功
    mail_unit.get_mail_reward()
    decider.sleep(500)
    for i = 1, 30 do
        if ui_unit.get_parent_window(ui_res.WIN['邮件'].win_name, true) == 0 then
            return false, '邮件窗口已关闭'
        end
        if not mail_unit.has_reward() then
            return true, '领取邮箱'
        end
        decider.sleep(500)
    end
    return false, '领取邮箱超时'
end

------------------------------------------------------------------------------------
-- [内部] 将对象转换为字符串
--
-- @local
-- @treturn      string                     模块名称
------------------------------------------------------------------------------------
function mail_ent.__tostring()
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
mail_ent.__newindex = function(t, k, v)
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
mail_ent.__index = mail_ent

------------------------------------------------------------------------------------
-- [构造] 创建一个新的实例
--
-- @local
-- @tparam       table     args             可选参数，用于初始化新实例
-- @treturn      table                      新创建的实例
------------------------------------------------------------------------------------
function mail_ent:new(args)
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
    return setmetatable(new, mail_ent)
end

-------------------------------------------------------------------------------------
-- 返回实例对象
-------------------------------------------------------------------------------------
return mail_ent:new()

-------------------------------------------------------------------------------------