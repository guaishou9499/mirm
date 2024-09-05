-------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @author:   admin
-- @email:    88888@qq.com 
-- @date:     2023-02-14
-- @module:   utils
-- @describe: 实用工具类
-- @version:  v1.0
--

-------------------------------------------------------------------------------------
--
local utils = {  
	VERSION      = '20211016.28',
	AUTHOR_NOTE  = '-[20211016.28]-',
    MODULE_NAME  = 'utils module', 
}

-- 自身模块
local this = utils
-- 文件系统
local lfs = lfs

-------------------------------------------------------------------------------------
-- 重写 table.concat
table.concat = function(t, sep, is_hex)
	local result = ''
	local temp = ''
	for i, v in ipairs(t) do
	   if i > 1 then
		  result = result .. sep
	   end
	   if is_hex and type(v) == 'number' then
		  if math.floor(v) ~= v then
			 temp = string.format('%0.3f', v)
		  else
			 temp = string.format('0x%X', v)
		  end
	   else
		  temp = tostring(v)
	   end
	   result = result .. temp
	end
	return result
end

-------------------------------------------------------------------------------------
-- 增加 table.index_of
table.index_of = function(t, val)
    for i = 1, #t do
        if t[i] == val then
            return i
        end
    end
    return nil
end

-------------------------------------------------------------------------------------
-- table.is_empty(t) 扩展table功能
table.is_empty = function(t)
	return (not t) or (next(t) == nil)
end

-------------------------------------------------------------------------------------
-- 创建目录
utils.create_directory = function(path)
    if not lfs.attributes(path, 'mode') then
        local success, err = lfs.mkdir(path)
        if not success then
            error(string.format('创建目录失败: %s (%s)', path, err))
        end
    end
end

-------------------------------------------------------------------------------------
-- 文件复制
utils.copy_file = function(src, dest)
    local input, err1 = io.open(src, 'rb')
    if not input then
        error(string.format('打开源文件失败: %s (%s)', src, err1))
    end

    local output, err2 = io.open(dest, 'wb')
    if not output then
        input:close()
        error(string.format('打开目标文件失败: %s (%s)', dest, err2))
    end

    local data = input:read('*a')
    output:write(data)

    input:close()
    output:close()
end

-------------------------------------------------------------------------------------
-- 文件复制
utils.copy_directory = function(src, dest)
    this.create_directory(dest)
    for file in lfs.dir(src) do
        if file ~= '.' and file ~= '..' then
            local src_path = src .. '\\' .. file
            local dest_path = dest .. '\\' .. file
            local attr = lfs.attributes(src_path, 'mode')

            if attr == 'directory' then
                this.copy_directory(src_path, dest_path)
            elseif attr == 'file' then
                this.copy_file(src_path, dest_path)
            else
                error(string.format('未知文件类型: %s', src_path))
            end
        end
    end
end

-------------------------------------------------------------------------------------
-- 生成随机字符串
utils.get_random = function(n)
	if n == nil then
	   n = 8
	end
	local t = {
		'0','1','2','3','4','5','6','7','8','9',
		'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
		'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
	} 
	local s = ''
	for i =1, n do
		s = s .. t[math.random(#t)]        
	end
	
	return s
 end

 -------------------------------------------------------------------------------------
-- 实例化新对象

function utils.__tostring()
    return this.MODULE_NAME
 end

 utils.__index = utils

function utils:new(args)
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
   return setmetatable(new, utils)
end

-------------------------------------------------------------------------------------
-- 返回对象
return utils:new()

-------------------------------------------------------------------------------------