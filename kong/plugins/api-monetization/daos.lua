local typedefs = require "kong.db.schema.typedefs"

local api_monetization_rate_plan = {
  primary_key = { "id" },
  name = "api_monetization_rate_plan",
  fields = {
    { id = typedefs.uuid },
    { service_name = { type = "string", required = true }, },
    { monthly = { type = "string", required = true }, },
	{ yearly = { type = "string", required = true }, },
	{ plan_type = { type = "string", required = true }, },
  },
}

return {
  api_monetization_rate_plan
}