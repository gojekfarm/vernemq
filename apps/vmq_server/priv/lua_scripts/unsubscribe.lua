#!lua name=unsubscribe

--[[
ARGV[1] = mountpoint
ARGV[2] = clientId
ARGV[3] = node name
ARGV[4] = timestamp
ARGV[5] = number of topics
ARGV[6] = topic1
ARGV[7] = topic2
.
.
.
]]

local function removeTopicForRouting(MP, node, clientId, topic, qos)
    local group, sharedTopic = string.match(topic, '^$share/(.-)/(.*)')
    if group == nil then
        local topicKey = cmsgpack.pack({MP, topic})
        redis.call('SREM', topicKey, cmsgpack.pack({node, clientId, qos}))
    else
        local topicKey = cmsgpack.pack({MP, sharedTopic})
        redis.call('SREM', topicKey, cmsgpack.pack({node, group, clientId, qos}))
    end
end

local function unsubscribe(_KEYS, ARGV)
    local STALE_REQUEST='stale_request'
    local UNAUTHORIZED='unauthorized'

    local MP = ARGV[1]
    local clientId = ARGV[2]
    local node = ARGV[3]
    local timestampValue = ARGV[4]
    local numOfTopics = tonumber(ARGV[5])

    local subscriberKey = cmsgpack.pack({MP, clientId})
    local nodeField = 'node'
    local topicsField = 'topics_with_qos'
    local timestampField = 'timestamp'

    local currValues = redis.call('HMGET', subscriberKey, nodeField, topicsField, timestampField)
    local currNode = currValues[1]
    local currPackedTopicsWithQoS = currValues[2]
    local T = currValues[3]
    if currNode == nil or T == nil or currNode == false or T == false then
        return true
    elseif tonumber(timestampValue) > tonumber(T) then
        if node == currNode then
            local existingTopicsWithQoS = cmsgpack.unpack(currPackedTopicsWithQoS)
            local newTopicsWithQoS = {}
            local i, j, k = 1, 1, 1
            while (i <= #existingTopicsWithQoS) and (j <= numOfTopics) do
                local topic = ARGV[5 + j]
                if existingTopicsWithQoS[i][1] < topic then
                    newTopicsWithQoS[k] = existingTopicsWithQoS[i]
                    k = k + 1
                    i = i + 1
                elseif topic < existingTopicsWithQoS[i][1] then
                    j = j + 1
                else
                    removeTopicForRouting(MP, node, clientId, topic, existingTopicsWithQoS[i][2])
                    j = j + 1
                    i = i + 1
                end
            end
            while (i <= #existingTopicsWithQoS) do
                newTopicsWithQoS[k] = existingTopicsWithQoS[i]
                k = k + 1
                i = i + 1
            end
            redis.call('HSET', subscriberKey, topicsField, cmsgpack.pack(newTopicsWithQoS), timestampField, timestampValue)
            return true
        end
        return redis.error_reply(UNAUTHORIZED)
    else
        return redis.error_reply(STALE_REQUEST)
    end
end

redis.register_function('unsubscribe', unsubscribe)
