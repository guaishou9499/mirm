------------------------------------------------------------------------------------
-- game/entities/redis_ent.lua
--
-- 这个模块主要是redis读写相关功能操作。
--
-- @module      redis_ent
-- @author      admin
-- @license     MIT
-- @release     v1.0.0 - 2023-03-22
-- @copyright   2023
-- @usage
-- local redis_ent = import('game/entities/redis_ent.lua')
------------------------------------------------------------------------------------

-- 模块定义
---@class redis_ent
local redis_ent = {
    -- 模块版本 (主版本.次版本.修订版本)
    VERSION = '1.0.0',
    -- 作者备注 (更新日期 - 更新内容简述)
    AUTHOR_NOTE = '2023-03-22 - Initial release',
    -- 模块名称
    MODULE_NAME = 'redis_ent module',
    -- 只读模式
    READ_ONLY = false,
}

-- 实例对象
local this = redis_ent
-- 日志模块
local trace = trace
-- 决策模块
local decider = decider
-- 全局设置
local settings = settings
--默认机器ID
redis_ent.COMPUTER_ID = 1
--默认redis对象
redis_ent.REDIS_OBJ = 1
--默认连接ip
redis_ent.IP = '127.0.0.1'
---@type common_unt
local common_unt = import('game/entities/unit/common_unt')
------------------------------------------------------------------------------------
-- [事件] 预载函数(重载脚本)
------------------------------------------------------------------------------------
redis_ent.super_preload = function()
    redis_ent.wi_get_user_info = decider.run_interval_wrapper('读写用户设置',redis_ent.get_user_info,60 * 1000)
end

--------------------------------------------------------------------------------
-- 向本地用户写入
--
-- @tparam       string     session      区块
-- @tparam       string     key          键
-- @tparam       any        str          值
-- @treturn      bool
-- @usage
-- redis_ent.write_ini_user('区块','键','值')
--------------------------------------------------------------------------------
redis_ent.write_ini_user = function(session, key, str)
    if this.read_ini_user(session, key) == str then
        return false
    end
    local session1 = main_ctx:utf8_to_ansi(session)
    local key1 = main_ctx:utf8_to_ansi(key)
    local str1 = main_ctx:utf8_to_ansi(str)
    return WriteString(session1, key1, str1)
end

--------------------------------------------------------------------------------
-- 向本地用户写入当天
--
-- @tparam       string     session      区块
-- @tparam       string     key          键
-- @tparam       any        str          值
-- @treturn      bool
-- @usage
-- redis_ent.write_ini_user('区块','键','值')
--------------------------------------------------------------------------------
redis_ent.write_day_ini_user = function(session, key, str)
    this.write_ini_user(session, key, str .. ',' .. os.date('%m%d'))
end
--------------------------------------------------------------------------------
-- 向本地用户写入（每天凌晨6点-时间）
--
-- @tparam       string     session      区块
-- @tparam       string     key          键
-- @tparam       any        str          值
-- @treturn      bool
-- @usage
-- redis_ent.write_sixh_ini_user('区块','键','值')
--------------------------------------------------------------------------------
redis_ent.write_sixh_ini_user = function(session, key, str)
    local ret = this.read_to_ini_user_time(session, key)
    if ret ~= str then
        this.write_ini_user(session, key, str .. ',' .. tostring(common_unt.get_day_sixh()))
    end
end

--------------------------------------------------------------------------------
-- 向本地用户写入（每周5-时间）
--
-- @tparam       string     session      区块
-- @tparam       string     key          键
-- @tparam       any        str          值
-- @treturn      bool
-- @usage
-- redis_ent.write_fivew_ini_user('区块','键','值')
--------------------------------------------------------------------------------
redis_ent.write_fivew_ini_user = function(session, key, str)
    local ret = this.read_to_ini_user_time(session, key)
    if ret ~= str then
        this.write_ini_user(session, key, str .. ',' .. tostring(func.get_five_week()))
    end
end

--------------------------------------------------------------------------------
-- 向本地角色读取
--
-- @tparam       string     session      区块
-- @tparam       string     key          键
-- @treturn      string                 读取区块中键对应的值
-- @usage
-- local str = redis_ent.read_ini_user('区块','键')
--------------------------------------------------------------------------------
redis_ent.read_ini_user = function(session, key)
    local session1 = main_ctx:utf8_to_ansi(session)
    local key1 = main_ctx:utf8_to_ansi(key)
    return main_ctx:ansi_to_utf8(ReadString(session1, key1))
end

--------------------------------------------------------------------------------
-- 向本地角色读取(天)
--
-- @tparam       string     session      区块
-- @tparam       string     key          键
-- @treturn      string                 读取区块中键对应的值
-- @usage
-- local str = redis_ent.read_ini_user_today('区块','键')
--------------------------------------------------------------------------------
redis_ent.read_ini_user_today = function(session, key)
    local ret = this.read_ini_user(session, key)
    if ret ~= '' then
        if common_unt.split(ret, ',')[2] == os.date('%m%d') then
            return common_unt.split(ret, ',')[1]
        end
    end
    return ''
end

--------------------------------------------------------------------------------
-- 向本地角色读取(时间)
--
-- @tparam       string     session      区块
-- @tparam       string     key          键
-- @treturn      string                 读取区块中键对应的值
-- @usage
-- local str = redis_ent.read_to_ini_user_time('区块','键')
--------------------------------------------------------------------------------
redis_ent.read_to_ini_user_time = function(session, key)
    local ret = this.read_ini_user(session, key)
    if ret ~= '' then
        if tonumber(common_unt.split(ret, ',')[2]) > os.time() then
            return common_unt.split(ret, ',')[1]
        end
    end
    return ''
end

--------------------------------------------------------------------------------
-- 向本机写入
--
-- @tparam       string     txtName      文件名
-- @tparam       string     session      区块
-- @tparam       string     key          键
-- @tparam       any        str          值
-- @treturn      bool
-- @usage
-- redis_ent.write_ini_computer('文件名','区块','键','值')
--------------------------------------------------------------------------------
redis_ent.write_ini_computer = function(txtName, session, key, str)
    if this.read_ini_computer(txtName, session, key) == str then
        return false
    end
    local txtName1 = main_ctx:utf8_to_ansi(txtName)
    local session1 = main_ctx:utf8_to_ansi(session)
    local key1 = main_ctx:utf8_to_ansi(key)
    local str1 = main_ctx:utf8_to_ansi(str)
    return WriteString2(txtName1, session1, key1, str1)
end

--------------------------------------------------------------------------------
-- 向本机读取
--
-- @tparam       string     txtName      文件名
-- @tparam       string     session      区块
-- @tparam       string     key          键
-- @treturn      bool
-- @usage
-- local str = redis_ent.read_ini_computer('文件名','区块','键')
--------------------------------------------------------------------------------
redis_ent.read_ini_computer = function(txtName, session, key)
    local txtName1 = main_ctx:utf8_to_ansi(txtName)
    local session1 = main_ctx:utf8_to_ansi(session)
    local key1 = main_ctx:utf8_to_ansi(key)
    return main_ctx:ansi_to_utf8(ReadString2(txtName1, session1, key1))
end

--------------------------------------------------------------------------------
-- 执行连接redis服务器
--
-- @treturn      bool
-- @usage
-- local bool = redis_ent.connect_redis()
--------------------------------------------------------------------------------
redis_ent.connect_redis = function()
    local ret_b = false
    --设置/读取本机ID和连接IP
    local computer_id = this.read_ini_computer('本机设置.ini', '连接REDIS设置', '机器ID')
    if computer_id == '' then
        this.write_ini_computer('本机设置.ini', '连接REDIS设置', '机器ID', '1')
        this.COMPUTER_ID = 1
    else
        this.COMPUTER_ID = tonumber(computer_id)
    end

    local ip = this.read_ini_computer('本机设置.ini', '连接REDIS设置', '连接IP')
    if ip == '' then
        this.write_ini_computer('本机设置.ini', '连接REDIS设置', '连接IP', '127.0.0.1')
    else
        this.IP = ip
    end
    this.REDIS_OBJ = redis_ctx
    if this.REDIS_OBJ:connect(this.IP, 6379) then
        ret_b = true
    end
    if type(this.REDIS_OBJ) == "number" then
    end
    return ret_b
end

--------------------------------------------------------------------------------
-- 向redis设置指定路径下的数据(string格式)
--
-- @tparam       string     path        路径
-- @tparam       string     session     区块
-- @tparam       string     key         键
-- @tparam       string     value       值
-- @treturn      bool
-- @usage
-- local bool = redis_ent.set_string_redis('路径',区块,键,值)
--------------------------------------------------------------------------------
redis_ent.set_string_redis = function(path, session, key, value)
    local str = this.REDIS_OBJ:get_string(path)
    local session_key = key
    if session ~= nil then
        session_key = session .. ':' .. key
    end
    local ini_obj = ini_unit:new()
    local ret = false
    if ini_obj:parse(str) then
        local r = ini_obj:get_string(session_key)
        if r ~= value then
            ini_obj:set_string(session_key, value)
            local new_string = ini_obj:to_string()
            ret = this.REDIS_OBJ:set_string(path, new_string)
        end
    end
    ini_obj:delete()
    return ret
end

--------------------------------------------------------------------------------
-- 向redis获取指定路径下的数据(string格式)
--
-- @tparam       string     path        路径
-- @tparam       string     session     区块
-- @tparam       string     key         键
-- @treturn      string
-- @usage
-- local str = redis_ent.get_string_redis('路径','区块','键')
--------------------------------------------------------------------------------
redis_ent.get_string_redis = function(path, session, key)
    local str = this.REDIS_OBJ:get_string(path)
    local session_key = key
    if session ~= nil then
        session_key = session .. ':' .. key
    end
    local ini_obj = ini_unit:new()
    local str_r = ''
    if ini_obj:parse(str) then
        str_r = ini_obj:get_string(session_key)
    end
    ini_obj:delete()
    return str_r
end

--------------------------------------------------------------------------------
-- 向redis获取指定路径下的数据(json格式)
--
-- @tparam       string     PATH    路径
-- @tparam       userdata   obj     对象
-- @treturn      table
-- @usage
-- local table = redis_ent.get_json_redis('路径', 对象)
--------------------------------------------------------------------------------
redis_ent.get_json_redis = function(PATH, obj)
    local retT = {}
    obj = obj or main_ctx
    --local server_obj = 0
    --if PATH == nil or PATH == '' then
    --    return {}
    --end
    --if obj == nil then
    --    server_obj = this.REDIS_OBJ
    --else
    --    server_obj = obj
    --end
    --if type(server_obj) ~= 'userdata' then
    --    return {}
    --end
    --if not server_obj:ping() then
    --    this.connect_redis()
    --    return {}
    --end
    local json_text = main_ctx:redis_get_string(PATH)
    if json_text == 'null' or json_text == '' then
        return {}
    end
    if string.len(json_text) > 0 then
        retT = json_unit.decode(json_text)
    end
    return retT
end

--------------------------------------------------------------------------------
-- 向redis设置指定路径下的数据(json格式)
--
-- @tparam       string     PATH    路径
-- @tparam       table     data     写入数据
-- @tparam       userdata   obj     对象
-- @treturn      table
-- @usage
-- local table = redis_ent.set_json_redis('路径',写入数据,对象)
--------------------------------------------------------------------------------
redis_ent.set_json_redis = function(PATH, data, obj)
    local server_obj = 0
    if PATH == nil or PATH == '' then
        return {}
    end
    --if obj == nil then
    --    server_obj = this.REDIS_OBJ
    --else
    --    server_obj = obj
    --end
    --if type(server_obj) ~= 'userdata' then
    --    return {}
    --end
    --if not server_obj:ping() then
    --    this.connectSer()
    --    return {}
    --end
    local nowRead = main_ctx:redis_get_string(PATH)
    if data == '' then
        if nowRead ~= 'null' then
            local xx = main_ctx:redis_set_string(PATH, 'null')
        end
        return {}
    end
    local json_text = json_unit.encode(data)
    if string.len(json_text) > 0 then
        local xx = main_ctx:redis_set_string(PATH, json_text)
        return xx
    end
    return false
end

--------------------------------------------------------------------------------
-- 向redis指定路径下的数据增加或修改
--
-- @tparam       string     PATH    路径
-- @tparam       table      data     写入数据
-- @treturn      bool
-- @usage
-- local bool = redis_ent.set_json_redis('路径',写入数据)
--------------------------------------------------------------------------------
redis_ent.add_changes_redis = function(PATH, data)
    local data_r = ''
    if type(data) == 'table' then
        data_r = data
        local data2 = redis_ent.get_json_redis(PATH)
        if not table_is_empty(data2) then
            for key, val in pairs(data2) do
                local setVal = val
                for key1, val1 in pairs(data) do
                    if key == key1 then
                        setVal = val1
                        break
                    end
                end
                data_r[key] = setVal
            end
        end
    end
    return this.set_json_redis(PATH, data_r)
end

--------------------------------------------------------------------------------
-- 读取(恢复默认)用户设置信息到全局
--
-- @usage
-- redis_ent.get_user_info()
--------------------------------------------------------------------------------
redis_ent.get_user_info = function()
    local global_set = {
        --1开关设置
        { session = '1开关设置', key = '执行主线', value = 1 },
        { session = '1开关设置', key = '执行副本', value = 1 },
        { session = '1开关设置', key = '执行挂机', value = 1 },
        { session = '1开关设置', key = '执行采集', value = 1 },
        { session = '1开关设置', key = '挂机采集', value = 1 },
        { session = '2主线设置', key = '结束主线等级', value = 27 },
        { session = '3副本设置', key = '1封印之塔', value = 1 },
        { session = '3副本设置', key = '2梦幻秘境', value = 1 },
        { session = '3副本设置', key = '3邪灵之塔', value = 0 },
        { session = '3副本设置', key = '4未知秘境', value = 0 },
        { session = '3副本设置', key = '5城主秘境', value = 0 },
        { session = '3副本设置', key = '6活动副本', value = 0 },
        { session = '4挂机设置', key = '挂机升级', value = 1 },
        { session = '4挂机设置', key = '挂机刷铜', value = 0 },
        { session = '4挂机设置', key = '低活力值采集(秒)', value = 7200 },
        { session = '5采集设置', key = '执行割草', value = 1 },
        { session = '5采集设置', key = '执行挖矿', value = 0 },
        { session = '5采集设置', key = '执行钓鱼', value = 0 },
        { session = '6商店设置', key = '最低出售数量', value = 5 },
        { session = '6商店设置', key = '保留铜钱', value = 12000 },
        { session = '7其他设置', key = '使用传送', value = 1 },
        { session = '7其他设置', key = '组队职业分配', value = '其他_5' },
        { session = '7其他设置', key = '队长职业', value = '其他' },


    }
    local PATH = "传奇M:机器[" .. this.COMPUTER_ID .. "]:" .. "用户设置" .. main_ctx:c_server_name()
    for k, v in pairs(global_set) do
        local value = this.get_string_redis(PATH, v.session, v.key)
        if value == '' then
            this.set_string_redis(PATH, v.session, v.key, v.value)
            value = v.value
        end
        if type(v.value) == "number" then
            value = tonumber(value)
        end
        this[v.key] = value
    end
    ini_ctx:parse(this.REDIS_OBJ:get_string(PATH))
end

------------------------------------------------------------------------------------
-- [内部] 防止动态修改(this.READ_ONLY值控制)
--
-- @local
-- @tparam       table     t                被修改的表
-- @tparam       any       k                要修改的键
-- @tparam       any       v                要修改的值
------------------------------------------------------------------------------------
redis_ent.__newindex = function(t, k, v)
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
redis_ent.__index = redis_ent

------------------------------------------------------------------------------------
-- [构造] 创建一个新的实例
--
-- @local 
-- @tparam       table     args             可选参数，用于初始化新实例
-- @treturn      table                      新创建的实例
------------------------------------------------------------------------------------
function redis_ent:new(args)
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
    return setmetatable(new, redis_ent)
end

-------------------------------------------------------------------------------------
-- 返回实例对象
-------------------------------------------------------------------------------------
return redis_ent:new()

-------------------------------------------------------------------------------------