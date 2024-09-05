-------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @author:   admin
-- @email:    88888@qq.com
-- @date:     2022-06-30
-- @module:   ui_res
-- @describe: 公共资源模块
-- @version:  v1.0
--

-------------------------------------------------------------------------------------
-- ui模块资源
---@class ui_res
local ui_res = {
    WIN = {
        ['幻象秘境'] = { win_name = 'IllusionDungeonEntryWindow_BP_C', win_open = function()
            dungeon_unit.open_dungeon_wnd()
        end, },
        ['交易所'] = { win_name = 'ExchangeWindow_BP_C', win_open = function()
            exchange_unit.open_exchange()
        end,},
        ['曼陀罗'] = { win_name = 'Mandala_SkillWindow_BP_C',win_open = function()
            mandala_unit.open_mandala_wnd()
        end,},
        ['邮件'] = { win_name = 'MirMailWindow_BP_C', win_open = function()
            mail_unit.open_mail_wnd()
        end, },
        ['冒险'] = { win_name = 'UserTitleWindow_BP_C', win_open = function()
            achieve_unit.open_user_title_wnd()
        end },
        ['宝鉴'] = { win_name = 'CollectionWindow_BP_C', win_open = function()
            collection_unit.open_collection_wnd()
        end, },
        ['签到'] = { win_name = 'HUDGameEventWindow_BP_C', win_open = function()
            --sign_unit.open_sign_wnd()
        end },
        ['死亡'] = { win_name = 'MirDeathWindows_BP_C', },
        ['任务'] = { win_name = 'QuestWindow_BP_C', },
        ['培育'] = { win_name = 'AutoGuideWindow_BP_C', },
        ['装备'] = { win_name = 'IntensionWindow_re_BP_C', },
        ['武功'] = { win_name = 'New_SkillWindow_BP_C', },
        ['化身'] = { win_name = 'ReflectionWindow_BP_C', },
        ['坐骑'] = { win_name = 'VehicleWindow_BP_C', },
        ['灵宠'] = { win_name = 'PetWindow_BP_C', },
        ['制作'] = { win_name = 'ProfesionWindow_BP_C', },
        ['门派'] = { win_name = 'GuildMakeAndRegisterWindow_BP_C', },
        ['商店'] = { win_name = 'CashShopWindow_BP_C', },
        ['首领'] = { win_name = 'WorldBossWindow_BP_C', },
        ['组队副本'] = { win_name = 'PartyDungeonEntryWindow_BP_C', },
        ['修罗大战'] = { win_name = 'ArenaWindow_BP_C', },
        ['师徒'] = { win_name = 'MIrMentorWindow_BP_C', },
        ['灵宠召唤'] = {win_name = 'SpawnableEventWindow_BP_C'},
        --有游戏主窗口ui
        ['奖励结果'] = { win_name = 'MirPopupWindow_BP_C'},
        ['NPC对话'] = { win_name = 'TalkboxWindow_BP_C', win_close = function()
            game_unit.pass_talk_box()
        end },
        ['接受任务'] = { win_name = 'QuestCompleteWindow_BP_C', win_close = function()
            quest_unit.process_event()
        end },
    }
}

local this = ui_res

-------------------------------------------------------------------------------------
--


-------------------------------------------------------------------------------------
-- 返回对象
return ui_res

-------------------------------------------------------------------------------------