-------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @author:   admin
-- @email:    88888@qq.com 
-- @date:     2023-02-14
-- @module:   decider
-- @describe: 决策模块
-- @version:  v1.0
--

-------------------------------------------------------------------------------------
---@class decider
local decider = {  
	VERSION      = '20211016.28',
	AUTHOR_NOTE  = '-[decider module - 20211016.28]-',
	MODULE_NAME  = 'decider module',
	-- 包装函数列表
	wrapped_funcs = {},
    -- 堆栈函数列表
    coroutine_stack_functions = {},
}

-- 自身模块
local this = decider
-- 设置模块
local settings = settings
-- 日志模块
local trace = trace

-------------------------------------------------------------------------------------
-- 设置上下文
decider.set_curr_context = function(context)
	-- 设置当前模块
	this.current_context = context
	-- 清零进入时间
	context.entry_time = 0
	-- 重置超时标识
	context.timeout_state = false
end

-------------------------------------------------------------------------------------
-- 是否工作
decider.is_working = function()
	-- 系统中断标志
	if not is_working() then
		return false
	end
	-- 效验函数中断
	if this.interrupt_guard() then
		return false
	end
    -- 本地化使用
    local context = this.current_context
    local eval_ifs = context.eval_ifs
    local curr_state = game_unit:game_status_ex()
    -- 效验超时
	if eval_ifs.time_out and eval_ifs.time_out ~= 0 then
		local entry_time = context.entry_time
		if entry_time ~= 0 then
			if os.time() - entry_time > eval_ifs.time_out then
				context.timeout_state = true
				return false
			end
		end
	end
	-- 效验 [启用] 游戏状态列表
	local check_ok = false
	if #eval_ifs.yes_game_state > 0 then
		for k,v in ipairs(eval_ifs.yes_game_state)
		do
			if v == curr_state then
			--if v & curr_state ~= 0 then
				check_ok = true
				break
			end
		end
		if not check_ok then return false end	
	end
	-- 效验 [禁用] 游戏状态列表
	check_ok = true
	for k,v in ipairs(eval_ifs.not_game_state)
	do	
		--if v & curr_state ~= 0 then
		if v == curr_state then
			check_ok = false
			break
		end
	end
	if not check_ok then  return false end
	-- 效验 [启用] 配置开关列表
	for k,v in ipairs(eval_ifs.yes_config)
	do
		if not ini_ctx:get_bool(v) then
			return false
		end
	end
	-- 效验 [禁用] 配置开关列表
	for k,v in ipairs(eval_ifs.not_config)
	do
		if ini_ctx:get_bool(v) then
			return false
		end
	end
	-- 其它条件
	return not eval_ifs.is_working or eval_ifs.is_working()
end

-------------------------------------------------------------------------------------
-- 执行功能函数前置效验
decider.is_execute = function()
	local ret = true
	local eval_ifs = this.current_context.eval_ifs
	if eval_ifs.is_execute then
		ret = eval_ifs.is_execute()
	end
	return ret
end

-------------------------------------------------------------------------------------
-- 效验函数中断
decider.interrupt_guard = function()
	-- 获取函数对象
	local id = coroutine.running()
	local stack_functions = this.coroutine_stack_functions[id]
	if stack_functions == nil or #stack_functions == 0 then
		return false
	end
	-- 效验函数是否设置超时
	local fn_info = stack_functions[#stack_functions]
	if fn_info.timeout == 0 or fn_info.start_time == 0 then
		return false
	end
	-- 效验超时
	if os.clock() - fn_info.start_time < fn_info.timeout then
		return false
	end
	-- 确定已超时
	fn_info.is_timeout = true
	return true	
end

-------------------------------------------------------------------------------------
-- 进入函数
decider.enter_function = function(fn_info)
	local id = coroutine.running()
	if not this.coroutine_stack_functions[id] then
		this.coroutine_stack_functions[id] = {}
	end
	local stack_functions = this.coroutine_stack_functions[id]
	table.insert(stack_functions, fn_info)
	trace.enter_function(stack_functions, fn_info)
end
 
 -------------------------------------------------------------------------------------
 -- 离开函数
decider.leave_function = function()
	local id = coroutine.running()
	local stack_functions = this.coroutine_stack_functions[id]
	local fn_info = stack_functions[#stack_functions]
	trace.leave_function(fn_info)
	table.remove(stack_functions)
end

-------------------------------------------------------------------------------------
-- 函数包装器(带日志)
decider.function_wrapper = function(action_name, action_func, func_prop)
	-- 断言效验
	assert(action_name ~= nil, '行为名称不能为空')
	assert(action_func ~= nil, '行为函数不能为NIL')
	-- 函数缓存key
	local func_key = xxhash('function_wrapper_'..action_name..tostring(action_func))
	-- 生成函数
	if not this.wrapped_funcs[func_key] then
		-- 函数信息对象
		local fn_info       = {}
		-- 函数属性对象
		local func_prop     = func_prop or {}
		-- 行为名称
		fn_info.action_name = action_name
		-- 目标函数
		fn_info.action_func = action_func
		-- 前置条件函数
		fn_info.cond_func   = func_prop.cond_func
		-- 超时时间
		fn_info.timeout     = func_prop.timeout or 0
		-- 普通函数(0) 行为函数(1)
		fn_info.func_type	= func_prop.func_type or 0	
		-- 运行计次
		fn_info.call_count	= 0
		-- 构建函数
		this.wrapped_funcs[func_key] = function(...)
			-- 效验工作状态
			if not this.is_working() then
				return false, 'decider.is_working equal false'
			end
			-- 效验可执行状态
			if fn_info.func_type == 1 and not this.is_execute() then
				return false, 'decider.is_execute equal false'
			end
			-- 重置默认返回值
			fn_info.result = {false}
			-- 效验前置条件
			if not fn_info.cond_func or fn_info.cond_func(...) then
				-- 参数列表
				fn_info.params      = {...}
				-- 开始时间
				fn_info.start_time  = os.clock()
				--重置超时
				fn_info.is_timeout	= false
				-- 累加运行次数
				fn_info.call_count  = fn_info.call_count + 1	
				-- 记录函数进入
				this.enter_function(fn_info)
				-- 调用目标函数
				fn_info.result      = {fn_info.action_func(...)}
				-- 记录函数离开
				this.leave_function()
			end
			-- 返回结果
			return table.unpack(fn_info.result)
		end
	end
	-- 返回函数
	return this.wrapped_funcs[func_key]
end

-------------------------------------------------------------------------------------
-- 函数包装器(普通函数)
decider.run_normal_wrapper = function(action_name, action_func, cond_func)
	return this.function_wrapper(action_name, action_func, {cond_func = cond_func})
end

-------------------------------------------------------------------------------------
-- 函数包装器(带前置条件)
decider.run_condition_wrapper = function(action_name, action_func, cond_func)
	return this.function_wrapper(action_name, action_func, {cond_func = cond_func})
end

-------------------------------------------------------------------------------------
-- 函数包装器(带超时功能)
decider.run_timeout_wrapper = function(action_name, action_func, timeout, cond_func)
	return this.function_wrapper(action_name, action_func, {cond_func = cond_func, timeout = timeout})
end

-------------------------------------------------------------------------------------
-- 函数包装器(行为类函数)
decider.run_action_wrapper = function(action_name, action_func, cond_func)
	return this.function_wrapper(action_name, action_func, {cond_func = cond_func, func_type = 1})
end

-------------------------------------------------------------------------------------
-- 包装间隔运行
decider.run_interval_wrapper = function(action_name, action_func, intv_time)
	-- 函数缓存key
	local func_key = xxhash('run_interval_wrapper_'..action_name..tostring(action_func))
	-- 生成函数
	if not this.wrapped_funcs[func_key] then
		this.wrapped_funcs[func_key] = function(...)
			-- 未设置就是立即执行
			if intv_time == nil then
				intv_time = 0
			end
			-- 读取运行信号
			if not get_run_signal(action_func, intv_time) then
				return false, 'no run signal'
			end
			-- 调用目标函数
			local fn = this.function_wrapper(action_name, action_func)
			return fn(...)
		end
	end
	-- 返回函数
	return this.wrapped_funcs[func_key]
end

-------------------------------------------------------------------------------------
-- 包装只运行一次
decider.run_once_wrapper = function(action_name, action_func)
	return this.run_interval_wrapper(action_name, action_func, 0xFFFFFFFF)
end

-------------------------------------------------------------------------------------
-- 包装运行到条件满足
decider.run_until_wrapper = function(action_func, condition, timeout)
	-- 函数缓存key
	local func_key = xxhash('run_until_wrapper_'..tostring(action_func)..tostring(condition)..tostring(timeout))
	-- 生成函数
	if not this.wrapped_funcs[func_key] then
		this.wrapped_funcs[func_key] = function(...)
			local result = false
			local start_time = os.clock()
			while this.is_working()
			do
				if timeout and os.clock() - start_time > timeout then
					break
				end
				if condition(...) then
					result = true
					break			
				end
				action_func(...) -- 调用目标函数
			end
			return result
		end
	end
	-- 返回函数
	return this.wrapped_funcs[func_key] 
end

-------------------------------------------------------------------------------------
-- 进入模块
decider.entry = function()
	-- 本地化使用
	local context = this.current_context
	-- 记录进入时间
	context.entry_time = os.time()	
	-- 日志跟踪进入
	trace.enter_module(context.MODULE_NAME)
	-- 函数进入前处理
	if context.pre_enter then context.pre_enter() end
	-- 调用目标函数
	context.entry()
	-- 函数离开处理
	if context.post_enter then context.post_enter() end
	-- 记录离开时间
	context.leave_time = os.time()
	-- 模块超时处理
	if context.on_timeout and context.timeout_state then
		context.on_timeout()		
	end	
	-- 日志跟踪离开
	trace.leave_module()
end

-------------------------------------------------------------------------------------
-- 轮循功能入口
decider.looping = function()
   local context = this.current_context
   if context.looping then
      context.looping()
   end
end

-------------------------------------------------------------------------------------
-- 切片sleep 大延时用这个
decider.sleep = function(ms)
	if ms == 0 then	return end
	-- 分割大小
	local slice = 500
	-- 计算需要分割的次数
	local n = ms // slice  
	-- 计算最后一次分割的时间
	local mod = ms % slice 
	for i = 1, n do
		if this.is_working() then
			sleep(slice)
		end
	end
	if mod > 0 then	sleep(mod) end
end

-------------------------------------------------------------------------------------
-- 实例化新对象

function decider.__tostring()
    return this.MODULE_NAME
end

decider.__index = decider

function decider:new(args)
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
   return setmetatable(new, decider)
end

-------------------------------------------------------------------------------------
-- 返回对象
return decider:new()

-------------------------------------------------------------------------------------