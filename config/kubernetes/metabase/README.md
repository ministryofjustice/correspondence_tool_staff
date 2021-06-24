# How to create read-only user

CREATE USER <user_name> WITH PASSWORD '<your_password>';

GRANT SELECT ON ALL TABLES IN SCHEMA public to <user_name>;
GRANT CONNECT ON DATABASE track_a_query_qa to <user_name>;
GRANT USAGE ON SCHEMA public to <user_name>;
