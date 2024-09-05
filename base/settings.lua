-------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
-- 
-- @author:   admin
-- @email:    88888@qq.com 
-- @date:     2023-02-14
-- @module:   settings
-- @describe: 设置模块
-- @version:  v1.0
--

-------------------------------------------------------------------------------------
--
local settings = {
   -- 模块名称
   MODULE_NAME             = 'settings module', 

   -- 日志记录级别(trace(0)、debug(1)、info(2)、warn(3)、error(4)、critical(5))
   log_level               = 0,
   -- 日志类型记录的通道(调试器(1)、日志文件(2)、两者(3))
   log_type_channel        = 3,

   -- 记录函数参数(暂时未使用)
   log_function_params     = false,
   -- 记录函数返回值(暂时未使用)
   log_function_return     = false,
   -- 记灵函数运行次数(暂时未使用)
   log_function_call_count = true,

   -- 异常后继续运行脚本(暂时未使用)
   continue_on_error       = false,
}

local this = settings

-------------------------------------------------------------------------------------
-- 实例化新对象

function settings.__tostring()
    return this.MODULE_NAME
 end

settings.__index = settings

-- 防止动态修改
-- settings.__newindex = function(table, key, value)
--    xxmsg('attempt to modify read-only table')
-- end

function settings:new(args)
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
   return setmetatable(new, settings)
end

-------------------------------------------------------------------------------------
-- 返回对象
return settings:new()

-------------------------------------------------------------------------------------