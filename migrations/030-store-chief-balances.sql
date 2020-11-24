create table dschief.balances (
  id serial primary key,
  address character(66) not null,
  amount decimal(78,18) not null,
  tx_id integer not null references vulcan2x.transaction(id) on delete cascade,
  block_id integer not null references vulcan2x.block(id) on delete cascade
);

create index chief_balance_address_index on dschief.balances (address);
