-------------------------------------------------------------------------------------
-- -*- coding: utf-8 -*-
--
-- @author:   admin
-- @email:    88888@qq.com
-- @date:     2022-06-30
-- @module:   share_res
-- @describe: 公共资源模块
-- @version:  v1.0
--

-------------------------------------------------------------------------------------
-- 采集模块资源
---@class gather_res
local gather_res = {
    --钓鱼资源
    FISHING = {
        { x = 23450.000000, y = 30030.000000, z = 10444.416016, map_id = 0x68, map_name = '比奇野外', danger_level = 2, line_num = 4, max_level = 15, min_level = 10, teleport_id = 0x19B,
          fishing_list = {
              { x = 23450.000000, y = 30030.000000, z = 10444.416016 },
              { x = 23731.826172, y = 30311.222656, z = 10444.416016 },
              { x = 23027.634766, y = 29892.835938, z = 10444.416016 },
              { x = 22899.410156, y = 29759.410156, z = 10444.237305 },
          }
        },

        { x = 13917.238281, y = 15737.323242, z = 10368.865234, map_id = 0x68, map_name = '比奇野外', danger_level = 2, line_num = 4, max_level = 20, min_level = 15, teleport_id = 0x19C,
          fishing_list = {
              { x = 13917.238281, y = 15737.323242, z = 10368.865234 },
              { x = 13639.000000, y = 15602.000000, z = 10371.781250 },
              { x = 13790.826172, y = 15907.222656, z = 10371.781250 },
              { x = 13915.634766, y = 16029.835938, z = 10371.781250 },
          }
        },
        { x = 18270.000000, y = 23030.000000, z = 6451.472168, map_id = 0x66, map_name = '银杏谷野外', danger_level = 1, line_num = 5, max_level = 10, min_level = 5, teleport_id = 0x19A,
          fishing_list = {
              { x = 18270.000000, y = 23030.000000, z = 6451.472168 },
              { x = 18270.000000, y = 23760.783203, z = 6427.520020 },
              { x = 18256.968750, y = 23017.558594, z = 6451.718262 },
              { x = 18269.992188, y = 22313.371094, z = 6451.718262 },
              { x = 18270.031250, y = 22026.140625, z = 6451.721191 },
          }
        },

        { x = 11270.000000, y = 25410.000000, z = 9997.081055, map_id = 0x65, map_name = '银杏谷村庄', danger_level = 1, line_num = 5, max_level = 5, min_level = 1, teleport_id = 0x191,
          fishing_list = {
              { x = 11266.190430, y = 24994.623047, z = 9997.036133 },
              { x = 11104.932617, y = 25430.816406, z = 9997.036133 },
              { x = 11271.923828, y = 25828.076172, z = 9997.036133 },
              { x = 10850.547852, y = 26116.941406, z = 9997.036133 },
              { x = 10408.178711, y = 26411.863281, z = 9995.502930 },
          }
        },
    },
    --挖矿资源
    MINING = {
        --当前等级判断矿区信息

        { x = 17274, y = 3535, z = 13134.698242188, map_id = 101, map_name = '银杏谷村庄1', danger_level = 1, line_num = 5, max_level = 5, min_level = 1, teleport_id = 0x194 }, -- 1-5
        { x = 24981.904297, y = 9598.118164, z = 9284.067383, map_id = 102, map_name = '银杏谷野外1', danger_level = 1, line_num = 5, max_level = 7, min_level = 4, teleport_id = 0x192 }, -- 4-7
        { x = 21897.373047, y = 18543.515625, z = 4883.244629, map_id = 241, map_name = '银杏谷废矿1层1', danger_level = 1, line_num = 4, max_level = 10, min_level = 6, func = function(z)
            return z > 4765
        end, teleport_id = 0x193 }, -- 6-10
        { x = 23725.101562, y = 22077.267578, z = 4319.181152, map_id = 241, map_name = '银杏谷废矿1层2', danger_level = 1, line_num = 4, max_level = 10, min_level = 6, func = function(z)
            return z < 4500
        end, teleport_id = 0x192 }, -- 6-11
        { x = 4830.000000, y = 8890.000000, z = 7496.968750, map_id = 242, map_name = '银杏谷废矿2层1', danger_level = 1, line_num = 3, max_level = 11, min_level = 8, teleport_id = 0x193 }, -- 8-11
        { x = 28068.050781, y = 9157.300781, z = 6459.621094, map_id = 242, map_name = '银杏谷废矿2层2', danger_level = 1, line_num = 3, max_level = 13, min_level = 8, teleport_id = 0x192 }, -- 8-13
        { x = 19670.000000, y = 21770.000000, z = 10747.038086, map_id = 104, map_name = '比奇野外1', danger_level = 2, line_num = 4, max_level = 16, min_level = 10, func = function(z)
            return z == 10629.9
        end, teleport_id = 0x191 }, -- 10-14
    },
    --采摘资源
    PICKING = {
        { x = 3850, y = 20650, z = 11216.846680, map_id = 101, map_name = '银杏谷村庄1', danger_level = 1, line_num = 5, max_level = 5, min_level = 1, teleport_id = 0x193 }, -- 1-5
        { x = 36610, y = 37310, z = 7064.937012, map_id = 102, map_name = '银杏谷野外1', danger_level = 1, line_num = 5, max_level = 8, min_level = 3, teleport_id = 0x193 }, -- 3-8
        { x = 11270, y = 21770, z = 6440.408691, map_id = 102, map_name = '银杏谷野外2', danger_level = 1, line_num = 5, max_level = 8, min_level = 3, teleport_id = 0x191 }, -- 3-8
        { x = 15050, y = 10850, z = 5257.462891, map_id = 242, map_name = '银杏谷废矿1层1', danger_level = 1, line_num = 4, max_level = 11, min_level = 6, teleport_id = 0x191 }, -- 6-11
        { x = 17710, y = 630, z = 5273.531738, map_id = 241, map_name = '银杏谷废矿2层1', danger_level = 1, line_num = 3, max_level = 13, min_level = 8, teleport_id = 0x191 }, -- 8-13
        { x = 20930, y = 17570, z = 11275.944336, map_id = 104, map_name = '比奇野外1', danger_level = 2, line_num = 4, max_level = 16, min_level = 10, func = function(z)
            return z > 10629.9
        end, teleport_id = 0x192 }, -- 10-16
        { x = 1890, y = 2730, z = 11857.194336, map_id = 104, map_name = '比奇野外2', danger_level = 2, line_num = 4, max_level = 16, min_level = 10, teleport_id = 0x193 }, -- 10-16
    },

    TOOL = {
        ['割草'] = { pos = 13, res_id = 0x0000736F },
        ['钓鱼'] = { pos = 14, res_id = 0x0000738D },
        ['挖矿'] = { pos = 12, res_id = 0x00007351 },
    },

}
local this = gather_res
-------------------------------------------------------------------------------------
-- 返回对象
return gather_res

-------------------------------------------------------------------------------------