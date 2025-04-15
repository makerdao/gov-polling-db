-- Create combined event table for all event types
CREATE TABLE mkr.event_v2 (
  id serial primary key,
  event_type character varying(10) not null, -- 'transfer', 'mint', or 'burn'
  sender character varying(66), -- null for mints
  receiver character varying(66), -- null for burns
  amount decimal(78,18) not null,
  log_index integer not null,
  tx_id integer not null REFERENCES vulcan2x.transaction(id) ON DELETE CASCADE,
  block_id integer not null REFERENCES vulcan2x.block(id) ON DELETE CASCADE,
  unique (log_index, tx_id)
);

-- Create new balances table that handles all events
CREATE TABLE mkr.balances_v2 (
  id serial primary key,
  address character varying(66) not null,
  amount decimal(78,18) not null,
  tx_id integer not null REFERENCES vulcan2x.transaction(id) ON DELETE CASCADE,
  block_id integer not null REFERENCES vulcan2x.block(id) ON DELETE CASCADE
);

CREATE INDEX idx_balances_v2_address ON mkr.balances_v2(address);
