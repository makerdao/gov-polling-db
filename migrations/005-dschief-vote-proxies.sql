CREATE TABLE dschief.vote_proxy_created_event (
  id         serial primary key,
  cold             character varying(66) not null,
  hot              character varying(66) not null,
  vote_proxy    character varying(66) not null,
  
  log_index  integer not null,
  tx_id      integer not null REFERENCES vulcan2x.transaction(id) ON DELETE CASCADE,
  block_id   integer not null REFERENCES vulcan2x.block(id) ON DELETE CASCADE,
  unique (log_index, tx_id)
);