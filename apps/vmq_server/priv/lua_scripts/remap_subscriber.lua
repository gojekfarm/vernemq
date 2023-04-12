#!lua name=remap_subscriber

--[[
ARGV[1] = mountpoint
ARGV[2] = clientId
ARGV[3] = node name
ARGV[4] = clean session
ARGV[5] = timestamp
]]

local function removeTopicsForRouting(MP, node, clientId, topicsWithQoS)
    for j = 1,#topicsWithQoS,1 do
        local topic, qos = unpack(topicsWithQoS[j])
        local group, sharedTopic = string.match(topic, '^$share/(.-)/(.*)')
        if group == nil then
            local topicKey = cmsgpack.pack({MP, topic})
            redis.call('SREM', topicKey, cmsgpack.pack({node, clientId, qos}))
        else
            local topicKey = cmsgpack.pack({MP, sharedTopic})
            redis.call('SREM', topicKey, cmsgpack.pack({node, group, clientId, qos}))
        end
    end
end

local function updateNodeForRouting(MP, clientId, topicsWithQoS, currNode, newNode)
    for j = 1,#topicsWithQoS,1 do
        local topic, qos = unpack(topicsWithQoS[j])
        local group, sharedTopic = string.match(topic, '^$share/(.-)/(.*)')
        if group == nil then
            local topicKey = cmsgpack.pack({MP, topic})
            redis.call('SREM', topicKey, cmsgpack.pack({currNode, clientId, qos}))
            redis.call('SADD', topicKey, cmsgpack.pack({newNode, clientId, qos}))
        else
            local topicKey = cmsgpack.pack({MP, sharedTopic})
            redis.call('SREM', topicKey, cmsgpack.pack({currNode, group, clientId, qos}))
            redis.call('SADD', topicKey, cmsgpack.pack({newNode, group, clientId, qos}))
        end
    end
end

local function remap_subscriber(_KEYS, ARGV)
    local STALE_REQUEST='stale_request'
    local str_to_bool = { ["true"]=true, ["false"]=false }
    local bool_to_str = { [true]="true", [false]="false" }

    local MP = ARGV[1]
    local clientId = ARGV[2]
    local newNode = ARGV[3]
    local newCleanSession = str_to_bool[ARGV[4]]
    local timestampValue = ARGV[5]

    local subscriberKey = cmsgpack.pack({MP, clientId})
    local nodeField = 'node'
    local cleanSessionField = 'clean_session'
    local topicsField = 'topics_with_qos'
    local timestampField = 'timestamp'

    local currValues = redis.call('HMGET', subscriberKey, nodeField, cleanSessionField, topicsField, timestampField)
    local currNode = currValues[1]
    local currCleanSession = str_to_bool[currValues[2]]
    local packedTopicsWithQoS = currValues[3]
    local T = currValues[4]
    if currNode == nil or T == nil or currNode == false or T == false then
        local subscriptionValue = {newNode, newCleanSession, {}}
        redis.call('HSET', subscriberKey, nodeField, newNode, cleanSessionField, bool_to_str[newCleanSession], topicsField, cmsgpack.pack({}), timestampField, timestampValue)
        redis.call('SADD', newNode, subscriberKey)
        return {false, subscriptionValue, nil}
    elseif tonumber(timestampValue) > tonumber(T) and newCleanSession == true then
        local subscriptionValue = {newNode, true, {}}
        redis.call('HSET', subscriberKey, nodeField, newNode, cleanSessionField, bool_to_str[newCleanSession], topicsField, cmsgpack.pack({}), timestampField, timestampValue)
        local topicsWithQoS = cmsgpack.unpack(packedTopicsWithQoS)
        removeTopicsForRouting(MP, currNode, clientId, topicsWithQoS)
        if currNode ~= newNode then
            redis.call('SMOVE', currNode, newNode, subscriberKey)
            return {true, subscriptionValue, currNode}
        end
        return {true, subscriptionValue, nil}
    elseif tonumber(timestampValue) > tonumber(T) and newCleanSession == false and currCleanSession == true then
        local topicsWithQoS = cmsgpack.unpack(packedTopicsWithQoS)
        removeTopicsForRouting(MP, currNode, clientId, topicsWithQoS)
        redis.call('HSET', subscriberKey, nodeField, newNode, cleanSessionField, bool_to_str[newCleanSession], topicsField, cmsgpack.pack({}), timestampField, timestampValue)
        local subscriptionValue = {newNode, false, {}}
        if currNode ~= newNode then
            redis.call('SMOVE', currNode, newNode, subscriberKey)
        end
        return {false, subscriptionValue, nil}
    elseif tonumber(timestampValue) > tonumber(T) and newCleanSession == false then
        local topicsWithQoS = cmsgpack.unpack(packedTopicsWithQoS)
        local subscriptionValue = {newNode, false, topicsWithQoS}
        if currNode ~= newNode then
            redis.call('HSET', subscriberKey, nodeField, newNode, timestampField, timestampValue)
            redis.call('SMOVE', currNode, newNode, subscriberKey)
            updateNodeForRouting(MP, clientId, topicsWithQoS, currNode, newNode)
            return {true, subscriptionValue, currNode}
        end
        redis.call('HSET', subscriberKey, timestampField, timestampValue)
        return {true, subscriptionValue, nil}
    else
        return redis.error_reply(STALE_REQUEST)
    end
end

redis.register_function('remap_subscriber', remap_subscriber)
