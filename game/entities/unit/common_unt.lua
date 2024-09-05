-------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @author:   admin
-- @email:    88888@qq.com
-- @date:     2022-06-30
-- @module:   common_unt
-- @describe: 公共模块
-- @version:  v1.0
--

-------------------------------------------------------------------------------------

---@class common_unt
local common_unt = {
	VERSION      = '20211016.28',
	AUTHOR_NOTE  = '-[common_unt module - 20211016.28]-',
	MODULE_NAME  = '公共模块', 
}

-- 自身模块
local this = common_unt
-- 日志模块
local trace = trace
-- 决策模块
local decider = decider

------------------------------------------------------------------------------------
-- 预载函数(重载脚本时)
common_unt.super_preload = function()
    -- xxmsg('item.super_preload') 
end

--------------------------------------------------------------------------------
-- [功能] 切割字符串
--
-- @tparam       string     str      		待分割的字符串
-- @tparam       string     split_char		分割段
-- @treturn      table						字符串分割表
-- @usage
-- local str_t = common_unt.split('待分割的字符串', '分割段')
-- print_t(str_t)
--------------------------------------------------------------------------------
common_unt.split = function(str, split_char)
	if str == nil or str == "" or str == " " or type(str) == "table" then
		return {}
	end
	local g_char_sp = ','
	if split_char ~= nil then
		g_char_sp = split_char
	end
	local sub_str_tab = {}
	while true do
		local pos = string.find(str, g_char_sp)
		if (not pos) then
			sub_str_tab[#sub_str_tab + 1] = str
			break
		end
		local sub_str = string.sub(str, 1, pos - 1)
		sub_str_tab[#sub_str_tab + 1] = sub_str
		str = string.sub(str, pos + 1, #str)
	end
	return sub_str_tab
end

--------------------------------------------------------------------------------
-- [功能] 判断一个点是否在以(x1,y1)为圆心，R为半径的圆内
--
-- @tparam		number		x			目标点的x坐标
-- @tparam		number		y			目标点的y坐标
-- @tparam      number		x1			圆心的x坐标
-- @tparam      number		y1			圆心的y坐标
-- @tparam      number		r			圆的半径
-- @treturn		boolean  				是否在圆内
-- @usage
-- local bool = common_unt.is_rang_by_point(目标点的x坐标,,目标点的y坐标,圆心的x坐标,圆心的y坐标,圆的半径)
--------------------------------------------------------------------------------
common_unt.is_rang_by_point = function(x, y, x1, y1, R)
    --
    local x2, y2 = x1 - R, y1
    local dist = this.get_dis_by_two_point(x1, y1, x2, y2) --  即把B坐标比作圆心，与C坐标的距离比作轴距

    local target = this.get_dis_by_two_point(x, y, x1, y1) --即 A坐标 与B坐标的距离，用于判断 是否在映射范围内
    if target < dist then
        --  即 A坐标  在 B与C 的范围内  卡路时  先寻C 再寻A
        return true
    end
    return false
end

--------------------------------------------------------------------------------
-- [功能] 计算两个点之间的距离
--
-- @tparam		number		x			第一个点的x坐标
-- @tparam		number		y			第一个点的y坐标
-- @tparam      number		x1			第二个点的x坐标
-- @tparam      number		y1			第二个点的y坐标
-- @treturn		number  				两个点之间的距离
-- @usage
-- local number = common_unt.get_dis_by_two_point(第一个点的x坐标,,第一个点的y坐标,第二个点的x坐标,第二个点的y坐标)
--------------------------------------------------------------------------------
common_unt.get_dis_by_two_point = function(x, y, x1, y1)
    local jx = math.abs(x - x1)
    local jy = math.abs(y - y1)
    local distance = math.sqrt(jx * jx + jy * jy)
    if distance <= 0 then
        return math.ceil(distance)
    end
    if math.ceil(distance) == distance then
        distance = math.ceil(distance)
    else
        distance = math.ceil(distance) - 1
    end
    return distance
end

--------------------------------------------------------------------------------
-- [功能] 返回年
--
-- @treturn      number  年
-- @usage
-- local year = common_unt.get_time_year()
--------------------------------------------------------------------------------
common_unt.get_time_year = function()
	return tonumber(os.date("%Y"))
end

--------------------------------------------------------------------------------
-- [功能] 返回月份
--
-- @treturn      number  月份
-- @usage
-- local mon = common_unt.get_time_mon()
--------------------------------------------------------------------------------
common_unt.get_time_mon = function()
	return tonumber(os.date("%m"))
end

--------------------------------------------------------------------------------
-- [功能] 返回当日
--
-- @treturn      number  当日
-- @usage
-- local day = common_unt.get_time_day()
--------------------------------------------------------------------------------
common_unt.get_time_day = function()
	return tonumber(os.date("%d"))
end

--------------------------------------------------------------------------------
-- [功能] 返回当前时
--
-- @treturn      number  当前时
-- @usage
-- local h = common_unt.get_time_h()
--------------------------------------------------------------------------------
common_unt.get_time_h = function()
	return tonumber(os.date("%H"))
end


--------------------------------------------------------------------------------
-- [功能] 返回当前分
--
-- @treturn      number  当前分
-- @usage
-- local m = common_unt.get_time_m()
--------------------------------------------------------------------------------
common_unt.get_time_m = function()
	return tonumber(os.date("%M"))
end

--------------------------------------------------------------------------------
-- [功能] 返回当前秒
--
-- @treturn      number  当前秒
-- @usage
-- local s = common_unt.get_time_s()
--------------------------------------------------------------------------------
common_unt.get_time_s = function()
	return tonumber(os.date("%S"))
end


--------------------------------------------------------------------------------
-- [功能] 返回星期
--
-- @treturn      number  星期
-- @usage
-- local w = common_unt.get_time_w()
--------------------------------------------------------------------------------
common_unt.get_time_w = function()
	return tonumber(os.date("%w"))
end

--------------------------------------------------------------------------------
-- [功能] 返回第二天6点时间
--
-- @treturn      number  第二天6点时间
-- @usage
-- local time = common_unt.get_day_sixh()
--------------------------------------------------------------------------------
common_unt.get_day_sixh = function()
	local thishour = tonumber(os.date("%H"))
	local thisM = tonumber(os.date("%M"))
	local thisS = tonumber(os.date("%S"))
	return os.time() - thishour * 60 * 60 - thisM * 60 - thisS +  30 * 60 * 60
end

--------------------------------------------------------------------------------
-- [功能] 判断比较值是否在值区间
--
-- @tparam       number		num			比较值
-- @tparam       number		max_num		最大区间
-- @treturn      number		min_num		最小区间
-- @treturn      boolean
-- @usage
-- local bool = common_unt.between(比较值,最大区间,最小区间)
--------------------------------------------------------------------------------
common_unt.between = function(num, max_num, min_num)
	if num < min_num then
		return false
	end
	if num > max_num then
		return false
	end
	return true
end

------------------------------------------------------------------------------------
-- [功能] 计算最大购买数
--
-- @tparam      int		max_num		最大值
-- @tparam      int		price		单价
-- @tparam      int		save        保留金额
-- @return      int		num   		最大购买数
-- @usage
-- local num = common_unt.calc_num(最大值,单价,最大购买数)
--------------------------------------------------------------------------------
common_unt.calc_num = function(max_num, price,save)
	if max_num <= 0 then
		return 0
	end
	save = save or 12000
	local money = item_unit.get_money_byid(2) - save
	if money <= price then
		return 0
	end
	if money < (max_num * price) then
		max_num = money / price
	end
	return math.floor(max_num)
end

--------------------------------------------------------------------------------
-- [功能] 判断目标是否在列表中
--
-- @tparam      any         target      目标
-- @tparam      table       list        列表
-- @return      boolean
-- @usage
-- local bool = common_unt.is_in_list(目标,列表)
--------------------------------------------------------------------------------
this.is_in_list = function(target, list)
	for i = 1, #list do
		if list[i] == target then
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------------
-- [功能] 合并两个表
--
-- @tparam      table       t1      表1
-- @tparam      table       t2      表2
-- @return      table
-- @usage
-- local table = common_unt.merge_table(表1,表2)
--------------------------------------------------------------------------------
this.merge_table = function(t1, t2)
	for i = 1, #t2 do
		t1[#t1 + 1] = t2[i]
	end
	return t1
end

--------------------------------------------------------------------------------
-- [功能] 判断目标是否在表中
--
-- @tparam      any             target      目标
-- @tparam      table           list        列表
-- @tparam      string          field       字段
-- @return      boolean
-- @usage
-- local bool = common_unt.is_in_table(目标,列表,'字段')
--------------------------------------------------------------------------------
this.is_in_table = function(target, table, field)
	for i = 1, #table do
		if table[i][field] == target then
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------------
-- [功能] 扩展表
--
-- @tparam      table           table       表
-- @tparam      string          field       字段
-- @return      table
-- @usage
-- local table = common_unt.expand_table(表,'字段')
--------------------------------------------------------------------------------
this.expand_table = function(table, field)
	local list = {}
	for i = 1, #table do
		list[#list + 1] = table[i][field]
	end
	return list
end

--------------------------------------------------------------------------------
-- [功能] 获取圆上均匀分布的点
--
-- @tparam      number          center_x        圆心x坐标
-- @tparam      number          center_y        圆心y坐标
-- @tparam      number          radius          半径
-- @tparam      number          num_points      点的数量
-- @return      table
-- @usage
-- local table = common_unt.get_point_on_circle(圆心x坐标,圆心y坐标,半径,点的数量)
--------------------------------------------------------------------------------
this.get_point_on_circle = function(center_x, center_y, radius, num_points)
	local angle_step = 2 * math.pi / num_points
	local points = {}
	for i = 1, num_points do
		local angle = angle_step * i
		local x = center_x + radius * math.cos(angle)
		local y = center_y + radius * math.sin(angle)
		table.insert(points, {x, y})
	end
	return points
end

--------------------------------------------------------------------------------
-- [功能] 打印表（用于调试）
--
-- @tparam      table       tbl             表
-- @tparam      number      level           层级
-- @tparam      boolean     filter_default  是否过滤关键字
--------------------------------------------------------------------------------
this.print_t = function(tbl, level, filter_default)
	if type(tbl) ~= 'table' then
		return
	end
	local msg = ""
	filter_default = filter_default or true --默认过滤关键字（DeleteMe, _class_type）
	level = level or 1
	local indent_str = ""
	for i = 1, level do
		indent_str = indent_str .. "  "
	end

	xxmsg(indent_str .. "{")
	for k, v in pairs(tbl) do
		if filter_default then
			if k ~= "_class_type" and k ~= "DeleteMe" then
				local item_str = string.format("%s%s = %s", indent_str .. " ", tostring(k), tostring(v))
				xxmsg(item_str)
				if type(v) == "table" then
					this.print_t(v, level + 1)
				end
			end
		else
			local item_str = string.format("%s%s = %s", indent_str .. " ", tostring(k), tostring(v))
			xxmsg(item_str)
			if type(v) == "table" then
				print_t(v, level + 1)
			end
		end
	end
	xxmsg(indent_str .. "}")
end

-------------------------------------------------------------------------------------
-- 实例化新对象

function common_unt.__tostring()
	return this.MODULE_NAME
end

common_unt.__index = common_unt

function common_unt:new(args)
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
	return setmetatable(new, common_unt)
end

-------------------------------------------------------------------------------------
-- 返回对象
return common_unt:new()

-------------------------------------------------------------------------------------