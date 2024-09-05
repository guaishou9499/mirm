-------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @author:   admin
-- @email:    88888@qq.com 
-- @date:     2023-02-14
-- @module:   trace
-- @describe: 日志模块
-- @version:  v1.0
--

-------------------------------------------------------------------------------------
---@class trace
local trace = {  
	VERSION      = '20211016.28',
	AUTHOR_NOTE  = '-[trace module - 20211016.28]-',
   MODULE_NAME  = 'trace module', 
   -- 堆栈函数列表
   coroutine_stack_functions = {}
}

-- 自身模块
local this = trace
-- 设置模块
local settings = settings

-------------------------------------------------------------------------------------
-- 最终输出(调试器)
trace.print = function(level, ...)
   -- 日志输出级别效验
   if level < settings.log_level then
      return
   end
   -- 输出到调试器
   xxxmsg(level, table.concat({...}, ', '))
end

-------------------------------------------------------------------------------------
-- 最终输出(控制台) 
trace.output = function(msg)
   main_ctx:set_action(msg)
end

-------------------------------------------------------------------------------------
-- 最终输出(日志文件)
trace.logger = function(level, ...)
   -- 日志输出级别效验
   if level < settings.log_level then
      return
   end
   -- 打包信息
   local msg = table.concat({...}, ', ')
   -- 输出调试器
   if settings.log_type_channel & 1 then
      xxxmsg(level, msg)
   end
   -- 输出日志文件
   if settings.log_type_channel & 2 then
      main_ctx:trace(msg, level)
   end
end

-------------------------------------------------------------------------------------
-- debug
trace.log_trace = function(...)
   this.logger(0, ...)
end

-------------------------------------------------------------------------------------
-- debug
trace.log_debug = function(...)
   this.logger(1, ...)
end

-------------------------------------------------------------------------------------
-- info
trace.log_info = function(...)
   this.logger(2, ...)
end

-------------------------------------------------------------------------------------
-- warn
trace.log_warn = function(...)
   this.logger(3, ...)
end

-------------------------------------------------------------------------------------
-- error
trace.log_error = function(...)
   this.logger(4, ...)
end

-------------------------------------------------------------------------------------
-- critical
trace.log_critical = function(...)
   this.logger(5, ...)
end

-------------------------------------------------------------------------------------
-- fatal
trace.log_fatal = function(...)
   this.logger(5, ...)
end

-------------------------------------------------------------------------------------
-- 包装行为
trace.wrapper_action = function()
   local result = ''
   local id = coroutine.running()
   local stack_functions = this.coroutine_stack_functions[id]
   if stack_functions ~= nil and #stack_functions > 0 then
      for i, v in ipairs(stack_functions) do
         if i > 1 then
            result = result .. ':'
         end
         result = result .. tostring(v.action_name)
      end
   end
   return result
end

-------------------------------------------------------------------------------------
-- 包装消息
trace.wrapper_message = function(head, ...)
   local msg = table.concat({...}, '-')
   local action = this.wrapper_action()
   local result = '[' .. head .. '] {'.. this.curr_module .. '}'
   if #action > 0 then
      result = result .. ' {' .. action .. '}'
   end
   if #msg > 0 then
      result = result .. ' (' .. msg .. ')'
   end
   return result
end

-------------------------------------------------------------------------------------
-- 行为记录
trace.action = function(head, ...)
   local msg = this.wrapper_message(head, ...)
   this.log_info(msg)
   this.output(msg)
end

-------------------------------------------------------------------------------------
-- 设置控制台信息
trace.message = function(head, ...)
   this.output(this.wrapper_message(head, ...))
end

-------------------------------------------------------------------------------------
-- 进入模块
trace.enter_module = function(name)
   this.curr_module = name
   this.action('进入')
end

-------------------------------------------------------------------------------------
-- 离开模块
trace.leave_module = function()
   this.action('离开')
   this.curr_module = ''
end

-------------------------------------------------------------------------------------
-- 进入函数
trace.enter_function = function(stack_functions, fn_info)
   local id = coroutine.running()
	if not this.coroutine_stack_functions[id] then
		this.coroutine_stack_functions[id] = stack_functions
	end
   if fn_info.func_type == 0 then -- 普通函数
      this.action('进入')
   end
end

-------------------------------------------------------------------------------------
-- 离开函数
trace.leave_function = function(fn_info)
   if fn_info.func_type == 0 then     -- 普通函数
      local timeit = os.clock() - fn_info.start_time
      local temp = fn_info.is_timeout and ', 超时' or ''
      this.action('离开', string.format('耗时%.1f秒%s', timeit, temp))
   elseif fn_info.func_type == 1 then -- 行为函数
      local params = table.concat(fn_info.params, ', ', true)
      local success = false
      local count = #fn_info.result
      if count > 0 then
         success = fn_info.result[1] or false
         -- 返回失败连接错误信息
         if not success and count > 1 then
            params = params .. ' : ' .. fn_info.result[2]
         end
      end
      this.action((success and '成功' or '失败'), params)
   end
end

-----------------------------------------------------------------0--------------------
-- 实例化新对象

function trace.__tostring()
   return this.MODULE_NAME
end

trace.__index = trace

function trace:new(args)
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
   return setmetatable(new, trace)
end

-------------------------------------------------------------------------------------
-- 返回对象
return trace:new()

-------------------------------------------------------------------------------------