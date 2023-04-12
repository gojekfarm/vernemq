#!lua name=reap_queues

--[[

]]

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

local function reap_queues(KEYS, ARGV)
    local str_to_bool = { ["true"]=true, ["false"]=false }

    local deadNode = KEYS[1]
    local newNode = ARGV[1]

    local nodeField = 'node'
    local cleanSessionField = 'clean_session'
    local topicsField = 'topics_with_qos'

    local subscriberKeys = redis.call('SRANDMEMBER', deadNode, 10)

    if next(subscriberKeys) == nil then
        return nil
    end

    local migratedSubscribers = {}
    local i = 1

    for j = 1,#subscriberKeys,1 do
        local MP, clientId = unpack(cmsgpack.unpack(subscriberKeys[j]))
        local cleanSession = str_to_bool[redis.call('HGET', subscriberKeys[j], cleanSessionField)]
        local topicsWithQoS = cmsgpack.unpack(redis.call('HGET', subscriberKeys[j], topicsField))
        if cleanSession == true then
            for i = 1,#topicsWithQoS,1 do
                local topic, qos = unpack(topicsWithQoS[i])
                local group, sharedTopic = string.match(topic, '^$share/(.-)/(.*)')
                if group == nil then
                    local topicKey = cmsgpack.pack({MP, topic})
                    redis.call('SREM', topicKey, cmsgpack.pack({deadNode, clientId, qos}))
                else
                    local topicKey = cmsgpack.pack({MP, sharedTopic})
                    redis.call('SREM', topicKey, cmsgpack.pack({deadNode, group, clientId, qos}))
                end
            end
            redis.call('SREM', deadNode, subscriberKeys[j])
            redis.call('DEL', subscriberKeys[j])
        else
            updateNodeForRouting(MP, clientId, topicsWithQoS, deadNode, newNode)
            redis.call('SMOVE', deadNode, newNode, subscriberKeys[j])
            redis.call('HSET', subscriberKeys[j], nodeField, newNode)
            migratedSubscribers[i] = {MP, clientId}
            i = i + 1
        end
    end
    return migratedSubscribers
end

redis.register_function('reap_queues', reap_queues)
