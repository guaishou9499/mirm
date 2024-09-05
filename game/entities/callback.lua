-------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @author:   admin
-- @email:    88888@qq.com 
-- @date:     2021-10-31
-- @module:   call_back
-- @describe: 精灵
-- @version:  v1.0
--

local VERSION = '20211031' -- version history at end of file
local AUTHOR_NOTE = "-[20211031]-"

local call_back = {  
	VERSION      = VERSION,
	AUTHOR_NOTE  = AUTHOR_NOTE,
	组队次数 = 0,--保存组队触发次数
	GAME_START_VALUE = 0,
}

local this = call_back
local banned_str_tab = {}
banned_str_tab['다수의 계정이 영리 목적으로 게임 내 재화를 축적하여 증여/양도/거래 등을 시도하거나 현금화하는 행위'] = '多数账户以营利为目的，在游戏中积累财物，试图进行赠与/转让/交易或兑换成现金的行为'
banned_str_tab['동일 및 인접한 IP 대역폭에서 다수의 계정을 이용해 유사한 패턴을 띄며 부당 이익을 취하는 행위'] = '在相同或相邻的IP带宽上，利用多个账户显示类似模式，获取不正当利益的行为'
banned_str_tab['다수의 계정이 동일한 패턴(무의미한 캐릭터명/유사한 캐릭터명 등)을 띄며 조직적으로 게임을 이용하는 행위'] = '多数账号使用相同的模式(无意义的角色名/类似的角色名等)有组织地使用游戏的行为'
banned_str_tab['임의로 변조/개작된 프로그램 등을 사용하거나 이를 사용하여 게임 서비스를 비정상적으로 이용하는 행위'] = '使用任意篡改或篡改的程序或非正常地使用游戏服务的行为'
banned_str_tab['조직적 또는 집단적으로 다수의 계정을 이용해 영리 목적을 띄며 불법적으로 게임을 이용하는 행위'] = '有组织或集体使用多个账号以营利为目的非法使用游戏的行为。'
banned_str_tab['다수의 계정이 게임 내 재화를 특정 계정으로 이동시키거나 수집하는 행위'] = '将游戏内的财物移动到特定账号或收集的行为'
banned_str_tab['아이템 및 재화를 현금이나 현물 등으로 거래를 시도하거나 알선하는 행위'] = '试图用现金或实物进行物品及财物交易或牵线搭桥的行为'

-------------------------------------------------------------------------------------
-- 收到组队
call_back.OnInviteParty = function(party_id, leader_id, leader_name)
    local co = coroutine.create(function()
		party_unit.accept(party_id)
		for i = 1,5 do
			if party_unit.has_party() then
				break
			end
			sleep(1000)
		end
    end)
    coroutine.resume(co)
end

-------------------------------------------------------------------------------------
-- 真人验证回调
call_back.OnHumanVerify = function(url)
    local co = coroutine.create(function()   
        xxmsg(url)
		--ShowMsg('资格验证中....')
		if main_ctx:verify_key()  == '' then 
			
			if main_ctx:human_verify(url) then
				xxmsg('验证成功连接游戏')
				--ShowMsg('验证成功连接游戏')
				-- 成功点击进入游戏 0 重新效验
				game_unit.confirm_global_login_pop(1)
			else
				xxmsg("验证失败")
			end
		else
			if main_ctx:human_verify2(url, '') then
					xxmsg('验证成功连接游戏')
					--ShowMsg('验证成功连接游戏')
					-- 成功点击进入游戏 0 重新效验
					game_unit.confirm_global_login_pop(1)
			else
					xxmsg("验证失败")
			end
		end
    end)

    coroutine.resume(co)
end

-------------------------------------------------------------------------------------
-- 过开始游戏界面
function pass_game_start(GameStart_btn)
    xxmsg('过开始游戏界面')
    local last_time = 0
    local count = 0
    while not is_terminated()
    do 
        if game_unit.game_status() ~= 0 then 
            break
        end
		
        if count > 5 then 
			xxmsg('进入游戏失败终止进程')
			main_ctx:end_game()
            break
        end
		
        local cur_time = os.time()
        if cur_time - last_time > 20 then 
			if ui_unit.btn_is_complated(GameStart_btn) then 
				ui_unit.btn_click(GameStart_btn)
			end
            last_time = cur_time
            count = count + 1
        end

        sleep(3000)
    end
end

-------------------------------------------------------------------------------------
-- 进入开始游戏界面回调
call_back.OnShowGameStart = function(GameStart_btn)
    local co = coroutine.create(function()   
		sleep(5000) -- 必须要延时
		if ui_unit.btn_is_complated(GameStart_btn) then
			ui_unit.btn_click(GameStart_btn)
			sleep(2000) -- 必须要延时
		end
    end)
    coroutine.resume(co)
end

-------------------------------------------------------------------------------------
-- 进入开始游戏网络连接失败
call_back.OnShowLocalCommonPop = function(btn_ok)
	--xxmsg(string.format('%X', btn_ok))
	local co = coroutine.create(function()
		sleep(3000)
		main_ctx:set_action('网络连接失败点击重连')
		-- 点击重新连接
		ui_unit.btn_click(btn_ok)
	end
	)
	coroutine.resume(co)
end

-------------------------------------------------------------------------------------
-- UI显示回调
call_back.OnShowMirWindow = function(window, name)
	--xxmsg(window)
	--xxmsg(name)
	if window == 0 then
		return
	end
    local co = coroutine.create(function()   
		--xxmsg(string.format('显示: %X %s', window, name))
		--xxmsg(ui_unit.get_text(window))
        -- 公共弹窗
		local closeList = {'CashShopLimitedPopupWindow_BP_C'}  --'HUDGameEventWindow_BP_C'

        if name == 'MirPopupWindow_BP_C' then
			local text = ui_unit.get_popup_text()
			if text ~= '' then
				xxmsg(text)
			end
			sleep(2000) -- 必须要延时 等控件初使完成
			
			--回到登录界面结束游戏
			if string.find(text,'网络环境不佳，需重新登录') ~= nil then
				xxmsg('监测回到登录界面3秒结束游戏')
				sleep(3000)
				main_ctx:end_game()
			end
			
			--判断封号
			if banned_str_tab[text] ~= nil then
				xxmsg(banned_str_tab[text])
				main_ctx:set_ban_time_ex(os.time(),banned_str_tab[text])
				--删除数据
				party_server_Mir4M.del_player_info_in_redis()
				sleep(3000)
				main_ctx:end_game()
			else
				game_unit.popup_window_click_btn(1)  -- 点击确认
			end
        elseif name =='MainNoticeWindow_BP_C' then 
            sleep(3000)
            game_unit.pass_notice_wnd()
			
		else
			for i = 1,#closeList do
				if name == closeList[i] then
					sleep(5000)
					ui_unit.close_window(window)
					break
				end
			end
        end
    end)
    coroutine.resume(co)
end

-- 收到进入副本请求
call_back.OnRequestEnterDungeon = function(dungeon_id)
    -- 确认进入副本
    xxmsg('确认进入副本..'..dungeon_id)
    if party_unit.get_leader_id() ~= local_player:id() then 
        dungeon_unit.enter_dungeon(dungeon_id)
    end
end
-------------------------------------------------------------------------------------
-- 实例化新对象

function call_back.__tostring()
    return "call_back package"
end

call_back.__index = call_back

function call_back:new(args)
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
   return setmetatable(new, call_back)
end

-------------------------------------------------------------------------------------
-- 返回对象
return call_back:new()

-------------------------------------------------------------------------------------