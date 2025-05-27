local redis = require "resty.redis"
local http = require "resty.http"
local cjson = require "cjson"

local red = redis:new()
local ok, err = red:connect("127.0.0.1", 6379)
if not ok then
    ngx.log(ngx.ERR, "Failed to connect to Redis: ", err)
    ngx.exit(500)
end

-- Get purge path
local path = ngx.var[1]
if not path or path == "" then
    ngx.exit(400)
end

-- Construct cache key
local cache_key = ngx.var.scheme .. ngx.var.host .. path

-- Purge Nginx cache
local res = ngx.location.capture("/purge-internal" .. path, {
    method = ngx.HTTP_GET,
    args = { key = cache_key }
})

-- Purge Redis cache
local success, err = red:del(cache_key)
if not success then
    ngx.log(ngx.ERR, "Failed to purge Redis cache: ", err)
end

-- Close Redis connection
red:set_keepalive(10000, 100)

-- Return response
if res.status == 200 then
    ngx.status = 200
    ngx.say("Cache purged successfully for: ", path)
else
    ngx.status = res.status
    ngx.say("Cache purge failed for: ", path)
end

return ngx.exit(ngx.status)