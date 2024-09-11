local kong = kong
local ngx = require "ngx"
local inspect = require "inspect"
local jwt = require "resty.jwt"
local cjson = require "cjson"
local os = require "os"
local openssl_pkey = require "resty.openssl.pkey"
local mail = require "resty.mail"
local jwt = require "resty.jwt"
local http = require "resty.http"

local apimonetization = {
  VERSION  = "1.0.0",
  PRIORITY = 18,
}

local function send_email(config,jwtToken,email_subject,email_content)
  kong.log("######## Executing Email content for api-monitization Plugin ########")
    local self = {options = {
    auth_type = "plain",
    domain = "localhost.localdomain",
    host = "smtp.gmail.com",
    password = "dgxbjsyxbaznhfdd",
    port = 587,
    ssl = false,
    starttls = true,
    timeout_connect = 60000,
    timeout_read = 60000,
    timeout_send = 60000,
    username = "premagsckong@gmail.com"
  }}
  local html_template={from = "premagsckong@gmail.com",
  html = email_content,
  reply_to = "premagsckong@gmail.com",
  subject = email_subject,
  to = { config.email_address }}
	local r, e = mail.send(self, html_template)
	kong.log("######## r of api-monitization Plugin ########",r)
	if not r then
	kong.log("######## e of api-monitization Plugin error ########",e)
	  return nil, e
	end
	kong.log("######## Ending schema.lua api-monitization Plugin ########")
  return true
end

-- Function to decode JWT token
local function decode_jwt(token)
  local jwt_obj = jwt:load_jwt(token)

  if jwt_obj.valid then
    kong.log("Decoded JWT: ", require("cjson").encode(jwt_obj.payload))
    return jwt_obj.payload
  else
    kong.log.err("Invalid JWT: ", jwt_obj.reason)
    return nil, jwt_obj.reason
  end
end

local function getHtmlContentForExpiredToken(jwtToken,expiry)
  local html_content = [[
		<p>Dear Kong Customer,</p>

		<p>This is a reminder that your access token is set to expire soon. Based on your subscription, your access token will expire on {{jwtToken}}.</p>

		<p>Please renew your token at your earliest convenience to ensure uninterrupted access to our services.</p>

		<p>If you need assistance with the renewal process, feel free to reach out to our support team.</p>

		<p>Thank you for choosing Kong</p>
		<p></p>
		<p> Your Access Token:</p>
		<p>{{jwtToken}}</p>

		<p>	Best regards,<p>
		<p>	Kong<p>
    ]]
  local formatted_date = os.date("%Y-%m-%d %H:%M:%S", expiry)
  local email_content = string.gsub(html_content, "{{jwtToken}}", jwtToken)
  email_content = string.gsub(email_content, "{{ExpiryDate}}", formatted_date)
  return email_content
end

local function sendEmailOnExpiry(config,jwtToken,payload)
  local ten_days = 10 * 24 * 60 * 60 -- 10 days in seconds
  if payload.exp and os.time() > payload.exp then
	return kong.response.exit(401, { message = "UnAuthorized"} )
  end
  local current_time = os.time()
  if payload.exp - current_time <= ten_days then
                -- Send an email notification
	kong.log("######## Inside set Expiry function ########")
    local cache_key = jwtToken .. ":" .. os.date("%Y-%m-%d")
    local ttl, err, already_sent = kong.cache:probe(cache_key)
	kong.log("######## Retrieved Cache Value ########", already_sent)
    if already_sent == nil then
      -- Send email notification
	  kong.log("######## Inside if Block Already Sent ########")
	  local htmlContent = getHtmlContentForExpiredToken(jwtToken,payload.exp)
      send_email(config,jwtToken,"Your Kong Access Token is going to Expire",htmlContent)
      kong.log("######## cahce Key ########" .. cache_key)
	  local ok, cacheErr, level = kong.cache:get(cache_key, { neg_ttl = 24 * 60 * 60, ttl = 24 * 60 * 60 }, function() 
                   return true end)
      if not ok then
         kong.log.err("Failed to set cache for token: ", token_id, " Error: ", err)
      end
	else
	  kong.log("######## Email Already Sent ########")
	end
  end

end

local function is_service_allowed(allowed_services,current_service_name)
  for _, service_name in ipairs(allowed_services) do
    if service_name == current_service_name then
      return true  -- Match found
    end
  end
  return false  -- No match found
end


function apimonetization:access(config)
  -- Implement logic for the access phase here (http)
  kong.log("############ access ############")
  local jwtToken = kong.request.get_header("Authorization");
  if jwtToken then
    kong.log("############ JWT Token Value ############" .. jwtToken)
    jwtToken = jwtToken:match("^Bearer%s+(.+)$") or jwtToken
	local payload, err = decode_jwt(jwtToken)
	  if payload then
		kong.log("JWT Payload: ", require("cjson").encode(payload))
		-- You can now work with the payload, e.g., access claims
		  sendEmailOnExpiry(config,jwtToken,payload)
		  --if payload.subscriptionPlan == "Premium" then
		    local service = kong.router.get_service()
			local service_name = service.name
			kong.log("######### Service Name: ########", service_name)
			local allowed_services = payload.allowedServices
			if is_service_allowed(allowed_services,service_name) ~= true then
			  kong.log.warn("Service is not allowed: ", service_name)
			  return kong.response.exit(403, { message = "You are not allowed to access the service" })
			end
	  else
		kong.log.err("Error decoding JWT: ", err)
	  end
  end
end
-- return the created table, so that Kong can execute it
return apimonetization