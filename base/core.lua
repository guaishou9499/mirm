-------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @author:   admin
-- @email:    88888@qq.com 
-- @date:     2023-02-14
-- @module:   core
-- @describe: 核心模块
-- @version:  v1.0
--

-------------------------------------------------------------------------------------
---@class core
local core = {  
	VERSION      = '20211016.28',
	AUTHOR_NOTE  = '-[core module - 20211016.28]-',
   MODULE_NAME  = 'core module', 
}

local this = core

-------------------------------------------------------------------------------------
-- 轮循计时器ID
this.CIRCULAR_TIMER_ID = 88888
-- 轮循间隔10秒
this.CIRCULAR_TIMER_DELAY = 10000 

-------------------------------------------------------------------------------------
-- 全局设置
_G.settings = import('base/settings')
-- 杂项模块
_G.utils = import('base/utils')
-- 日志模块
_G.trace = import('base/trace')
-- 决策模块
_G.decider = import('base/decider')
-- 模块列表
core.module_list = import('game/modules')

-------------------------------------------------------------------------------------
-- 预载函数(重载脚本时)
core.super_preload = function()
   -- 关闭自动重启
   main_ctx:auto_restart(false)
end

-------------------------------------------------------------------------------------
-- 预载处理(脚本运行时)
core.preload = function()
   -- 这个必须保留
   sleep(100) 
   -- 开启自动重启
   main_ctx:auto_restart(true)
   -- 初始化所有模块
   for k,v in ipairs(this.module_list)
   do
      -- 调用功能
      if v.preload then
         -- v.preload()
         xpcall(v.preload, this.error_handler)
      end
   end
   -- 安装轮循计时器
   -- settimer(this.CIRCULAR_TIMER_ID, this.CIRCULAR_TIMER_DELAY)
end

-------------------------------------------------------------------------------------
-- 入口函数
core.entry = function()
   -- 设置随机数种子
   math.randomseed(os.clock()) 
   -- 优化使用
   local decider = decider
   -- 模块调用
   for k,v in ipairs(this.module_list) 
   do
      -- 中断检测
      if not is_working() then
         break     
      end
      -- 设置当前上下文
      decider.set_curr_context(v)
      -- 调用功能入口函数
      if v.entry and decider.is_working() then
         -- 进入模块
         -- decider.entry()
         xpcall(decider.entry, this.error_handler)
      end
      -- 清空当前上下文
      decider.set_curr_context(this)
   end
end

-------------------------------------------------------------------------------------
-- 定时回调
core.on_timer = function(timer_id)
   for k,v in ipairs(this.module_list)
   do
      -- 中断检测
      if not is_working() then
         break     
      end
      -- 调用功能
      if v.on_timer then
         --v.on_timer(timer_id)
         xpcall(v.on_timer, this.error_handler, timer_id)
      end
   end
end

-------------------------------------------------------------------------------------
-- 卸载处理
core.unload = function()
   -- 卸载轮循计时器
   killtimer(this.CIRCULAR_TIMER_ID)
   -- 关闭自动重启
   main_ctx:auto_restart(false)
   -- 卸载所有模块
   for k,v in ipairs(this.module_list)
   do
      -- 调用功能
      if v.unload then
         -- v.unload()
         xpcall(v.unload, this.error_handler)
      end
   end
end

-------------------------------------------------------------------------------------
-- 异常捕获函数
core.error_handler = function(err)
   -- 设置脚本终止标志
   if not settings.continue_on_error then
      set_exit_state(true) 
   end 
   trace.log_error(debug.traceback('error: ' .. tostring(err), 2))
end

-------------------------------------------------------------------------------------
-- 打包脚本
core.build_script = function()
   -- 文件列表
   local files = {
      -- 需要加密文件列表
      'core.lua',
      'trace.lua',
      'decider.lua',
   }
   local directorys = {
      'base',
      'game',
   }
   -- 生成路径
   local path = main_ctx:c_fz_path()
   -- 复制目录
   for _,v in ipairs(directorys)
   do
      local source = path .. [[\Script\]] .. v
      local destination = path .. [[\RScript\]] .. v
      local success, err = pcall(function()
         utils.copy_directory(source, destination)
      end)
      if success then
         xxxmsg(2, '复制目录成功: ' .. source)
      else
         xxxmsg(2, '复制目录成功: ' .. source)
      end
   end
   -- 加密文件
   local dest_path = path .. [[\RScript\\base\]]
   for _,v in ipairs(files)
   do
      local success = _encrypt_script(dest_path .. v)
      if success then
         xxxmsg(2, '加密文件成功: ' .. v)
      else
         xxxmsg(4, '加密文件失败: ' .. v)
      end    
   end
end

-------------------------------------------------------------------------------------
-- 实例化新对象

function core.__tostring()
   return this.MODULE_NAME
end

core.__index = core

function core:new(args)
   local new = { }

   -- 预载函数(重载脚本时)
   if this.super_preload then
      this.super_preload()
   end

   if args then
      for key, val in pairs(args) do
         new[key] = val
      end
   end

   -- 设置元表
   return setmetatable(new, core)
end

-------------------------------------------------------------------------------------
-- 返回对象
return core:new()

-------------------------------------------------------------------------------------