local VERSION = "2023-3-27"
local AUTHOR_NOTE = "Administrator"

---@class item_res
local item_res = {
    VERSION = VERSION,
    AUTHOR_NOTE = AUTHOR_NOTE,
    MODULE_NAME = "item_res",
}

local this = item_res

this.should_use_item = {
    --'中型魔力药水箱子',
    '공격속도 물약 (중)', --'攻击速度药水（中）',
    --'공격속도 물약 (소)',--'攻击速度药水（小）',
    --'生命回复药水（中）',
    --'生命回复药水（小）',
}

this.box_list = {
    '中型生命药水箱子',
    '中型魔力药水箱子',

}

this.destroy_item_list = {
    [20] = { '목검', '청동투구' },
    [30] = {
        '체력 회복약(소)', '마력 회복약(소)', --药水
        '목검', '오목검', '청동검', '아리수옥검', --剑
        '청동투구', '사슬투구', '녹슨투구', --头盔
        '모피허리띠', '가죽허리띠', --腰带
        '경갑옷', '철갑옷', --铠甲
        '가죽신발', '모피신발', --鞋
        '팔각반지', '구리반지', --戒指
        '초롱목걸이', '금장팔찌', '금목걸이'-- 链条
        --[['生命回复药水（小）', '魔力回复药水（小）',]]
    }
}

this.skill_item_list = { '火焰掌秘籍', '强击秘籍', '爆裂火焰秘籍', '地炎术秘籍',
                         '화염장 비급', '폭열파 비급', '강격 비급', '술사 무공서',
}

this.vehicle_item_list = { '黄虎', '红耳猪', '银耳猪', '金耳猪' ,
                           '황호',
}

this.force_item_list = { '心眼', '飞燕', '必中之击', '移形换位' }

this.IS_BIND = {
    --采矿材料
    [0x000009D0] = '铜原石',
    [0x000009D5] = '中级铜原石',
    [0x000009D1] = '铜矿原石',
    [0x000009D6] = '中级铜矿原石',
    [0x000009D2] = '铁矿原石',
    [0x000009D7] = '中级铁矿原石',
    [0x000009D3] = '银矿原石',
    [0x000009D8] = '中级银矿原石',
    [0x000009D4] = '金矿原石',
    [0x000009D9] = '中级金矿原石',
    [0x00000AC1] = '矿石',
    --TODO:缺少绑定中级矿石数据
    [0x00000A07] = '铁矿铸锭',
    --割草材料
    [0x000009E4] = '野花',
    [0x000009DB] = '中级野花',
    [0x000009E5] = '果实',
    [0x000009DC] = '中级果实',
    [0x000009E6] = '根茎',
    [0x000009DD] = '中级根茎',
    [0x000009E7] = '树枝',
    [0x000009E9] = '中等树枝',
    [0x000009E3] = '青苔',
    --TODO:缺少绑定中级青苔数据
    [0x00000A98] = '蘑菇',
    [0x00000A9B] = '中级蘑菇',
    [0x000009DE] = '野花粉',
    --钓鱼材料
    [0x000009ED] = '人面鱼',
    [0x000009EB] = '中级人鱼',
    [0x000009E8] = '鲫鱼',
    [0x000009EA] = '中级鲫鱼',
    [0x000009F1] = '鲤鱼',
    [0x000009EF] = '中级鲤鱼',
    [0x00000A99] = '香鱼',
    [0x000009EC] = '中级香鱼',
    [0x000009F4] = '珍珠',
    [0x000009F0] = '中级珍珠',
    [0x00000A9A] = '蛤蜊',
    [0x00000A9C] = '中级蛤蜊',
    [0x000032CA] = '女人石像',
    [0x000032CB] = '神龙人锤子',
    [0x00001DC0] = '银杏遗失物',
    [0x000032C9] = '银杏谷村庄神物',
    --怪物材料

    --箱子
    [0x00001E91] = '中型生命药水箱子',
    [0x00001E92] = '中型魔力药水箱子',
    [0x0000CB6A] = '曼陀罗选择箱子',
    [0x00001D5F] = '坐骑装备箱子',
    [0x00001D61] = '铜钱箱子',
    [0x00001DBE] = '凤玉箱子',
    [0x00002093] = '高级坐骑分解荷包',
    [0x00002092] = '普通坐骑分解荷包',
    [0x00002020] = '银杏谷龙玉荷包I',
    --药水
    [0x00000FA1] = '生命回复药水（小）',
    [0x00000FA2] = '生命回复药水（中）',
    [0x00000FA8] = '魔力回复药水（小）',
    [0x00000FA9] = '魔力回复药水（中）',
    [0x00000FC0] = '攻击速度药水（小）',
    [0x00000FC1] = '攻击速度药水（中）',
    [0x00000FCC] = '法术防御药水（小）',
    [0x00000FC8] = '防御药水（小）',
    [0x00000FBC] = '法术药水（小）',
    [0x00000FB8] = '破坏药水（小）',
    [0x00000FB0] = '暴击药水（小）',
    [0x00000FB5] = '命中药水（中）',
    [0x0000CBCE] = '【限定】成长秘药（10）',
    [0x0000CBDC] = '【限定】成长秘药（10）', -- 会掉落
    [0x0000CB9B] = '【限定】成长秘药（20）',
    --通用物品
    [0x000009C5] = '古老的银币',
    [0x00001B5F] = '灵宠召唤券',
    [0x000002D7] = '忘天丹', -- 重置曼陀罗穴位道具
    [0x000002CE] = '龙玉', -- 曼陀罗激活道具
    [0x0000025A] = '凤玉', -- 曼陀罗激活道具
    [0x00000AA3] = '玉碎片', -- 制作龙凤玉
    [0x00000AA2] = '玉残片', -- 制作玉碎片
    [0x00000386] = '普通强化石纯度+1', -- 装备强化
    [0x00000387] = '普通强化石纯度+2', -- 装备强化
    [0x00000388] = '普通强化石纯度+3', -- 装备强化
    [0x00000389] = '普通强化石纯度+4', -- 装备强化
    [0x0000038A] = '普通强化石纯度+5', -- 装备强化
    [0x00000259] = '祝福之油', -- 装备祝福
    [0x00000385] = '再炼石', -- 装备鉴定
    [0x0000039F] = '龙灵神铁', -- 解锁装备凹槽
    [0x00000AD6] = '龙灵神铁碎片', -- 制作龙灵神铁
    [0x0000029F] = '心眼', -- 技能书（内功）
    [0x000002CC] = '内功秘籍碎片', -- 技能书制作
    [0x000002CB] = '武功秘籍碎片', -- 技能书制作
    [0x00000296] = '绿柱石残片', -- 技能书制作
    [0x00000297] = '绿柱石碎片', -- 技能书制作
    [0x0000102B] = '跳跃之牌', --传送牌
    [0x000009CF] = '沃玛教主的角', -- 创建帮派使用
    --其他物品
    [0x00001048] = '【回城卷轴】银杏谷村庄',
    [0x00001049] = '【回城卷轴】比奇',
    [0x00001053] = '据点卷轴',
    [0x00000FAD] = '普通饲料',
    [0x00000FAE] = '高级饲料',
    [0x000000D4] = '封印之塔充值石',
    [0x000000D6] = '梦幻秘境补充石',
    [0x000000D4] = '封印之塔补充石',
    [0x0000CBD3] = '罗刹信物', -- 活动副本产出道具，用于制作或出售100铜/个
    [0x000000CF] = '副本讨伐入场券',
    [0x00000FE0] = '银杏秘闻录第1章', -- 接【银杏秘1章】任务道具
    --装备
    [0x00007351] = '疵痕镐', --equip_pos:12   equip_type:12
    [0x0000736F] = '疵痕镰刀', --equip_pos:13  equip_type:13
    [0x0000738D] = '疵痕鱼竿', --equip_pos:14  equip_type:11

}
this.NOT_IS_BIND = {
    --采矿材料
    [0x000007DC] = { name = '铜原石', sell_num = 1000 },
    [0x000007E1] = { name = '中级铜原石', sell_num = 5 },
    [0x000007DD] = { name = '铜矿原石', sell_num = 1000 },
    [0x000007E2] = { name = '中级铜矿原石', sell_num = 5 },
    [0x000007DE] = { name = '铁矿原石', sell_num = 1000 },
    [0x000007E3] = { name = '中级铁矿原石', sell_num = 5 },
    [0x000007DF] = { name = '银矿原石', sell_num = 1000 },
    [0x000007E4] = { name = '中级银矿原石', sell_num = 5 },
    [0x000007E0] = { name = '金矿原石', sell_num = 1000 },
    [0x000007E5] = { name = '中级金矿原石', sell_num = 5 },
    [0x000008CD] = { name = '矿石', sell_num = 1000 },
    [0x000008CE] = { name = '中级矿石', sell_num = 5 },
    --采集材料
    [0x000007F0] = { name = '野花', sell_num = 1000 },
    [0x000007E7] = { name = '中级野花', sell_num = 5 },
    [0x000007F1] = { name = '果实', sell_num = 1000 },
    [0x000007E8] = { name = '中级果实', sell_num = 5 },
    [0x000007F2] = { name = '根茎', sell_num = 1000 },
    [0x000007E9] = { name = '中级根茎', sell_num = 5 },
    [0x000007F3] = { name = '树枝', sell_num = 1000 },
    [0x000007F5] = { name = '中等树枝', sell_num = 5 },
    [0x000007EF] = { name = '青苔', sell_num = 1000 },
    [0x000008A3] = { name = '中级青苔', sell_num = 5 },
    [0x000008A4] = { name = '蘑菇', sell_num = 1000 },
    [0x000008A7] = { name = '中级蘑菇', sell_num = 5 },
    --钓鱼材料
    [0x000007F4] = { name = '鲫鱼', sell_num = 1000 },
    [0x000007F6] = { name = '中级鲫鱼', sell_num = 5 },
    [0x000007FD] = { name = '鲤鱼', sell_num = 1000 },
    [0x000007FB] = { name = '中级鲤鱼', sell_num = 5 },
    [0x00000800] = { name = '珍珠', sell_num = 1000 },
    [0x000007FC] = { name = '中级珍珠', sell_num = 5 },
    [0x000008A6] = { name = '蛤蜊', sell_num = 1000 },
    [0x000008A8] = { name = '中级蛤蜊', sell_num = 5 },
    [0x000007F9] = { name = '人面鱼', sell_num = 1000 },
    [0x000007F7] = { name = '中级人面鱼', sell_num = 5 },
    [0x000008A5] = { name = '香鱼', sell_num = 1000 },
    [0x000007F8] = { name = '中级香鱼', sell_num = 5 },
    --怪物材料
    [0x00000898] = { name = '毒液', sell_num = 1000 },
    [0x00000899] = { name = '灰色毒粉', sell_num = 1000 },
    [0x0000088B] = { name = '黄色毒粉', sell_num = 1000 },
    [0x0000088D] = { name = '坛子残片', sell_num = 1000 },
    [0x00000891] = { name = '净化剂', sell_num = 1000 },
    [0x0000088C] = { name = '进化剂', sell_num = 1000 },
    [0x00000895] = { name = '黄铜牛蹄', sell_num = 1000 },
    [0x00000894] = { name = '坚硬的牛角', sell_num = 1000 },
    [0x00000890] = { name = '生锈的武器', sell_num = 1000 },
    --通用材料
    [0x000001A2] = { name = '龙玉', sell_num = 2 },
    [0x0000012E] = { name = '凤玉', sell_num = 2 },
    [0x000008AF] = { name = '玉碎片', sell_num = 200 },
    [0x000008AE] = { name = '玉残片', sell_num = 200 },
    [0x00000C66] = { name = '【瞬移卷轴】梦幻秘境牛魔神殿' }, -- 进入梦幻秘境二层必要道具
    [0x000008D0] = { name = '武魂碎片', sell_num = 200 }, -- 制作蓝装材料
    [0x000007D1] = { name = '古老的银币', sell_num = 20 },
    [0x000001F6] = { name = '普通强化石纯度+1', sell_num = 50 },
    [0x000001F7] = { name = '普通强化石纯度+2', sell_num = 50 },
    [0x0000012D] = { name = '祝福油', sell_num = 5 },
    [0x000001F5] = { name = '再炼石', sell_num = 200 },
    [0x0000019F] = { name = '武功秘籍碎片', sell_num = 5 },
    [0x00000BC5] = { name = '普通饲料', sell_num = 50 },
    [0x00000072] = { name = '梦幻秘境补充石', sell_num = 2 },
    [0x00002EE1] = { name = '银杏谷村庄神物', sell_num = 200 }, -- 银杏谷遗物
    [0x00002EE3] = { name = '神龙人锤子', sell_num = 200 }, -- 银杏谷遗物
    --装备
    [0x00005237] = { name = '丝绸剑', sell_num = 3 },
    [0x000059E3] = { name = '白金头盔', sell_num = 3 },
    [0x000055FB] = { name = '白金甲胄', sell_num = 3 },
    [0x000061B3] = { name = '白金腰带', sell_num = 3 },
    [0x00005DCB] = { name = '白金靴', sell_num = 3 },
    [0x00006599] = { name = '铁指环', sell_num = 3 },
    --不知名物品
    [0x000008D7] = { name = '青麻耳石碎片' },
    [0x000001A0] = { name = '内务公署雕塑' },
}
-- 出售绑定物品
this.SELL_BIND = {
    [0x000009C5] = '古老的银币',
    [0x0000CBD3] = '罗刹信物', -- 活动副本产出道具，用于制作或出售100铜/个
    [0x00001053] = '据点卷轴',
    --采矿材料
    [0x000009D0] = '铜原石',
    [0x000009D5] = '中级铜原石',
    [0x000009D1] = '铜矿原石',
    [0x000009D6] = '中级铜矿原石',
    [0x000009D2] = '铁矿原石',
    [0x000009D7] = '中级铁矿原石',
    [0x000009D3] = '银矿原石',
    [0x000009D8] = '中级银矿原石',
    [0x000009D4] = '金矿原石',
    [0x000009D9] = '中级金矿原石',
    [0x00000AC1] = '矿石',
    --TODO:缺少绑定中级矿石数据
    [0x00000A07] = '铁矿铸锭',
    --割草材料
    [0x000009E4] = '野花',
    [0x000009DB] = '中级野花',
    [0x000009E5] = '果实',
    [0x000009DC] = '中级果实',
    [0x000009E6] = '根茎',
    [0x000009DD] = '中级根茎',
    [0x000009E7] = '树枝',
    [0x000009E9] = '中等树枝',
    [0x000009E3] = '青苔',
    --TODO:缺少绑定中级青苔数据
    [0x00000A98] = '蘑菇',
    [0x00000A9B] = '中级蘑菇',
    [0x000009DE] = '野花粉',
    --钓鱼材料
    [0x000009ED] = '人面鱼',
    [0x000009EB] = '中级人鱼',
    [0x000009E8] = '鲫鱼',
    [0x000009EA] = '中级鲫鱼',
    [0x000009F1] = '鲤鱼',
    [0x000009EF] = '中级鲤鱼',
    [0x00000A99] = '香鱼',
    [0x000009EC] = '中级香鱼',
    [0x000009F4] = '珍珠',
    [0x000009F0] = '中级珍珠',
    [0x00000A9A] = '蛤蜊',
    [0x00000A9C] = '中级蛤蜊',
    [0x000032CA] = '女人石像',
    [0x000032CB] = '神龙人锤子',
    [0x00001DC0] = '银杏遗失物',
    [0x000032C9] = '银杏谷村庄神物',
}


-------------------------------------------------------------------------------------
-- 返回对象
return item_res