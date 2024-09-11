return {
  postgres = {
    up = [[
      CREATE TABLE IF NOT EXISTS "api_monetization_rate_plan" (
        "id"           UUID   PRIMARY KEY,
        "service_name"   TEXT,
        "monthly"   TEXT,
		"yearly"  TEXT,
		"plan_type" TEXT
		);
		
		DO $$
      BEGIN
        INSERT INTO "api_monetization_rate_plan" (id,service_name,monthly,yearly,plan_type)
         VALUES ('00000000-0000-0000-0000-000000000001','Real_Time_Stock_Price_Service','40$', '200$','Lite');
		INSERT INTO "api_monetization_rate_plan" (id,service_name,monthly,yearly,plan_type)
         VALUES ('00000000-0000-0000-0000-000000000002','Historical_Stock_Price_Service','20$', '150$','Lite');
        -- Do nothing, accept existing state
      END$$;
		
    ]],
  },

 cassandra = {
    up = [[]]
  }
}