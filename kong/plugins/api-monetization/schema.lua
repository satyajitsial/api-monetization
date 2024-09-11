-- schema.lua
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

local function getServiceNamesforPlan(plan_type)
   kong.log("############## Inside getServiceNames : ###########")
   local service_names = {}
   local rows, err = kong.db.api_monetization_rate_plan:each()
   for row, err in rows do
		kong.log("############ Inside the For Loop ############")
		if err then
		  kong.log.err("Error processing subscription data: ", err)
		  return kong.response.exit(500, { message = "Internal Server Error" })
		end
		local planType = row.plan_type
		
		if plan_type == "Premium" then
		  kong.log("############ Inside Premium ############" , row.service_name)
		  table.insert(service_names, row.service_name)
		else
		  if planType == plan_type then
		   kong.log("############ Inside Lite ############" , row.service_name)
		   table.insert(service_names, row.service_name)
		  end
		end
   end
  kong.log("############## Inside getServiceNames : ###########" .. inspect(service_names)) 
  return service_names
end

local function getPrivatekey(config)
    kong.log("############## Inside getPrivateKey : ###########")
    local private_key = config.Private_key
	local private_key_received=private_key:gsub(" ", "\n")
    private_key_received=private_key_received:gsub("%-%-%-%-%-BEGIN\nPRIVATE\nKEY%-%-%-%-%-",
	"%-%-%-%-%-BEGIN PRIVATE KEY%-%-%-%-%-")
	
    private_key_received=private_key_received:gsub("%-%-%-%-%-END\nPRIVATE\nKEY%-%-%-%-%-",
	"%-%-%-%-%-END PRIVATE KEY%-%-%-%-%-")
	private_key_received = string.gsub(private_key_received, "\\n", "\n")
    kong.log("############## Inside rs256 : ###########", inspect(payload))
	kong.log("############## Inside rs256 private_key : ###########", inspect(private_key_received))
	return private_key_received
end

local function generate_jwt_token_with_rs256(privateKey,payload)
    kong.log("############## Inside generate_jwt_token_with_rs256 : ###########" .. inspect(payload))
	kong.log("############## Inside PrivateKey : ###########" .. inspect(privateKey))
    local jwt_token, err = jwt:sign(
        privateKey,
        {
            header = { typ = "JWT", alg = "RS256" },
            payload = payload
        }
    )
    
	 kong.log("############## Inside rs256 : ###########", inspect(jwt_token)) 
    if not jwt_token then
        kong.log("Failed to sign JWT: ", err)
        return nil, err
    end

    return jwt_token
end

local function getHtmlContentForToken(jwtToken)
   local html_content = [[
		<p>Dear Customer,

		<p>Thank you for subscribing . We are excited to have you on board and look forward to providing you with the best service possible.</p>

		<p>As part of your subscription, we are pleased to provide you with your access token, which you will need to authenticate your requests and access our services.</p>

		<p> Your Access Token:</p>
		<p>{{jwtToken}}</p>
    ]]
  local email_content = string.gsub(html_content, "{{jwtToken}}", jwtToken)
  return email_content
end

local function createToken(privateKey,payload)   
	--kong.log("############## Private key : ###########", privateKey) 
    --kong.log("############## Payload : ###########", inspect(payload))	
    local token, err = generate_jwt_token_with_rs256(privateKey,payload)
    if token then
        kong.log("############## Generated JWT: ###########", token)
    else
        kong.log("############## Failed to generate JWT: ###########", err)
    end
	return token;
end

local function getTokenPayload(subscriptionPlan,expiryTime,subscriptionPackage)
   --local consumer = kong.client.get_consumer()
   --local consumerId = consumer.id
   local payload = {
        sub = "1234567890",
        --customer_name = "Kong_Customer",
		--consumer_Id = consumerId,
        admin = true,
		subscriptionPackage = subscriptionPackage,
		subscriptionPlan = subscriptionPlan
    }
   if subscriptionPlan == "Premium" then
	  local allowedServices = getServiceNamesforPlan(subscriptionPlan)
	  payload.allowedServices = allowedServices
	  payload.consumer_Id = "6a975998-91a2-4ca4-9548-a51ad0cc2fa1"
   elseif  subscriptionPlan == "Lite" then
      local allowedServices = getServiceNamesforPlan(subscriptionPlan)
      payload.allowedServices = allowedServices
	  payload.consumer_Id = "0926166b-3471-43ff-a39f-359b87e8a5cc"
   end 
   kong.log("############## Inside getTokenPayload : ###########", inspect(payload))	
   payload.exp = os.time() + expiryTime
  return payload
end

local function getExpiryTime(subscriptionPackage)
    --local expiry_time = 365 * 24 * 60 * 60
	--local expiry_time = 5 * 24 * 60 * 60
	local expiry_time = nil
	if subscriptionPackage == "Yearly" then
	 local one_year_in_seconds = 5 * 24 * 60 * 60
     expiry_time = one_year_in_seconds
    elseif subscriptionPackage == "Monthly" then
	  local one_month_in_seconds = 5 * 24 * 60 * 60
     expiry_time = one_month_in_seconds
    end
   return expiry_time
end

local function tokenForLiteSubscription(config)
  local subscriptionPackage = config.subscriptionPackage
  kong.log("############ SubscriptionAmount ############" .. subscriptionPackage)
  --local subscriptionAmount = getAmountForLitePlan(subscriptionPackage)
  --local serviceName = config.BlackListServices
  local expiryTime = getExpiryTime(subscriptionPackage)
  --local payload = getTokenPayload(config.subscriptionType,expiryTime,serviceName)
  local payload = getTokenPayload(config.subscriptionPlan,expiryTime,subscriptionPackage)
  kong.log("############## Inside tokenForFlatSubscription Payload : ###########", inspect(payload))	
  local privateKey = getPrivatekey(config)
  local jwtToken = createToken(privateKey,payload)
  kong.log("############## Created JWT Token : ###########", jwtToken)
  return jwtToken
end

local function tokenForPremiumSubscription(config)
  local subscriptionPackage = config.subscriptionPackage
  kong.log("############ SubscriptionAmount ############" .. subscriptionPackage)
  local expiryTime = getExpiryTime(subscriptionPackage)
  local payload = getTokenPayload(config.subscriptionPlan,expiryTime,subscriptionPackage)
  kong.log("############## Inside tokenForFlatSubscription Payload : ###########", inspect(payload))	
  local privateKey = getPrivatekey(config)
  local jwtToken = createToken(privateKey,payload)
  kong.log("############## Created JWT Token : ###########", jwtToken)
  return jwtToken
end

local function createTokenBasedOnSubscription(config)
   local subscriptionPlan = config.subscriptionPlan
   kong.log("############ subscriptionPlan ############" .. subscriptionPlan)
   local jwtToken = nil
   if subscriptionPlan == "Lite" then
      jwtToken = tokenForLiteSubscription(config)
   elseif subscriptionPlan == "Premium" then
      jwtToken = tokenForPremiumSubscription(config)
   end
   return jwtToken
end

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

local function generateTokenBasedOnSubscription(config)
  kong.log("######## Executing schema.lua api-monetization Plugin ########")
    local subscriptionPlan = config.subscriptionPlan
	local subscriptionPackage = config.subscriptionPackage
	kong.log("############ SubscriptionAmount ############" .. subscriptionPackage)
	--local consumer = kong.client.get_consumer()
	--kong.log("############ Consumer ID ############" , consumer)
	--local consumer = ngx_ctx.authenticated_consumer.id
	local jwtToken = createTokenBasedOnSubscription(config)
	kong.log("############ jwtToken in Access Phase############" .. jwtToken)
	local htmlContent = getHtmlContentForToken(jwtToken)
    send_email(config,jwtToken,"Welcome to Kong - Here’s Your Access Token",htmlContent)
	--kong.response.exit(200, { message = "Please find your subscription in the Email. Kindly use this token to access the service:"})
    return true  
end

return {
  name = "api-monetization",
  fields = {
     {
      consumer = {
        type = "foreign",
        reference = "consumers",
        default = null,
        required = false,
      },
    },   
    { config = {
      type = "record",
	  custom_validator = generateTokenBasedOnSubscription,
      fields = {
		{ subscriptionPlan = { type = "string", required = true, default = "Lite",
                            one_of = { "Lite","Premium"},
                          } },
        { subscriptionPackage = { type = "string", required = true, default = "Yearly",
                            one_of = { "Monthly", "Yearly" },     
		} }, 						  
		{ email_address = { type = "string", required = true} },
		{ Private_key = { type = "string", required = true} },
      },
    },},
  },
}
