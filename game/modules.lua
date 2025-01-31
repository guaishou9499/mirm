-------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @author:   admin
-- @email:    88888@qq.com
-- @date:     2023-02-14
-- @module:   modules
-- @describe: 模块列表(所有引用模块都从这个模块统一载入)
-- @version:  v1.0
--

-------------------------------------------------------------------------------------
-- 公共模块
_G.common =  import('game/entities/common')
-- 回调模块
_G.call_back =  import('game/entities/callback')

-------------------------------------------------------------------------------------
-- 功能模块
local module_list = {
   -- 登陆模块
   import('game/modules/login'),
   -- 任务模块
   import('game/modules/quest'),
   -- 狩猎模块
--   import('game/modules/hunt'),
   -- 采集模块
   import('game/modules/gather'),
}

-------------------------------------------------------------------------------------
-- 返回对象
return module_list

-------------------------------------------------------------------------------------