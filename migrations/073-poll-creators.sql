create table polling.creators (
  address character varying(66) not null
);

create or replace function api.poll_creators()
returns setof polling.creators as $$
  select *
  from polling.creators;
$$ language sql stable strict;
