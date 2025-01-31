-------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
-- 
-- @author:   admin
-- @email:    88888@qq.com 
-- @date:     2023-02-14
-- @module:   start
-- @describe: 入口文件
-- @version:  v1.0
--

-------------------------------------------------------------------------------------
-- 引入管理对象
---@type core
local core = import('base/core')

-------------------------------------------------------------------------------------
-- LUA入口函数(正式 CTRL+F5)
function main()
    -- 预载处理
    core.preload()
    -- 主循环
    while not is_exit()
    do
        core.entry() -- 入口调用
        sleep(1000)
    end

    -- 卸载处理
    core.unload()
end

-------------------------------------------------------------------------------------
-- 定时器入口
function on_timer(timer_id)
    -- 分发到脚本管理
    core.on_timer(timer_id)
end

-------------------------------------------------------------------------------------
-- LUA入口函数(测试 F5运行)
function main_test()

end

