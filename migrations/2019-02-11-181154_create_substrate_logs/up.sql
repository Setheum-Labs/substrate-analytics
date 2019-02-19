CREATE TABLE substrate_logs (
  id SERIAL PRIMARY KEY,
  node_ip VARCHAR NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  logs JSONB NOT NULL
);