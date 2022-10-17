#!lua name=enqueue_msg

--[[
ARGV[1] = Node
ARGV[2] = SubscriberId
ARGV[3] = SubInfo&Msg
]]

local function enqueue_msg(_KEYS, ARGV)
    local node = ARGV[1]
    local subscriberId = ARGV[2]
    local msg = ARGV[3]

    local mainQKey = 'mainQueue'.. '::'.. node
    local t = redis.call('TIME')
    return redis.call("LPUSH", mainQKey, cmsgpack.pack({subscriberId, msg, t[1], t[2]}))
end

redis.register_function('enqueue_msg', enqueue_msg)
