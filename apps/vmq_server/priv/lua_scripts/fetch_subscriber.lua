#!lua name=fetch_subscriber

--[[
ARGV[1] = mountpoint
ARGV[2] = clientId
]]

local function fetch_subscriber(_KEYS, ARGV)
    local str_to_bool = { ["true"]=true, ["false"]=false }
    local bool_to_str = { [true]="true", [false]="false" }

    local MP = ARGV[1]
    local clientId = ARGV[2]

    local subscriberKey = cmsgpack.pack({MP, clientId})
    local nodeField = 'node'
    local cleanSessionField = 'clean_session'
    local topicsField = 'topics_with_qos'

    local node, cleanSessionStr, packedTopicsWithQoS = redis.call('HMGET', subscriberKey, nodeField, cleanSessionField, topicsField)
    if node == nil or node == false then
        return {}
    else
        return {node, str_to_bool[cleanSessionStr], cmsgpack.unpack(packedTopicsWithQoS)}
    end
end

redis.register_function('fetch_subscriber', fetch_subscriber)
