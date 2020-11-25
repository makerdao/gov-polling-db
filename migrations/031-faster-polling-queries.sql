create index poll_id_index on polling.voted_event (poll_id);
create index timestamp_index on vulcan2x.block (timestamp);

create or replace function polling.voter_weight(address character(66), block_id integer)
returns decimal(78,18) as $$
declare
  wallet_amount decimal(78,18);
  chief_amount decimal(78,18);
  proxy dschief.vote_proxy_created_event%rowtype;
  proxy_chief_amount decimal(78,18);
  linked_wallet_amount decimal(78,18);
begin
  select amount into wallet_amount from mkr.balances ba
  where ba.address = voter_weight.address
  and ba.block_id <= voter_weight.block_id
  order by ba.id desc limit 1;

  select amount into chief_amount from dschief.balances ba
  where ba.address = voter_weight.address
  and ba.block_id <= voter_weight.block_id
  order by ba.id desc limit 1;

  select * into proxy
  from dschief.vote_proxy_created_event vpc
  where (hot = voter_weight.address or cold = voter_weight.address)
  and vpc.block_id <= voter_weight.block_id
  order by vpc.id desc limit 1;

  if proxy is not null then
    select amount into proxy_chief_amount from dschief.balances ba
    where ba.address = proxy.vote_proxy
    and ba.block_id <= voter_weight.block_id
    order by ba.id desc limit 1;

    select amount into linked_wallet_amount from mkr.balances ba
    where ba.address = (
      case when proxy.cold = voter_weight.address
      then proxy.hot else proxy.cold end)
    and ba.block_id <= voter_weight.block_id
    order by ba.id desc limit 1;
  end if;

  return coalesce(wallet_amount, 0) + 
    coalesce(chief_amount, 0) + 
    coalesce(proxy_chief_amount, 0) + 
    coalesce(linked_wallet_amount, 0);
end;
$$ language plpgsql stable strict;

create or replace function polling.votes(poll_id integer, block_id integer)
returns table (
  voter character(66),
  option_id integer,
  amount decimal(78,18)
) as $$
  select 
    voter, 
    option_id, 
    polling.voter_weight(voter, votes.block_id)
  from polling.valid_votes(votes.poll_id) vv
  where vv.block_id <= votes.block_id
$$ language sql stable strict;

create or replace function polling.votes_at_block(poll_id integer, block_number integer)
returns table (
  voter character(66),
  option_id integer,
  amount decimal(78,18)
) as $$
  select * from polling.votes(poll_id, (
    select id from vulcan2x.block where number = block_number
  )) 
$$ language sql stable strict;

create or replace function polling.votes_at_time(poll_id integer, unixtime integer)
returns table (
  voter character(66),
  option_id integer,
  amount decimal(78,18)
) as $$
  select * from polling.votes(poll_id, (
    select id from vulcan2x.block where timestamp <= to_timestamp(unixtime)
    order by timestamp desc limit 1
  )) 
$$ language sql stable strict;
