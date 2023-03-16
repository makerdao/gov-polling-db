create type poll_entry as (
  creator character varying,
  poll_id int,
  created_at timestamp with time zone,
  start_date timestamp with time zone,
  end_date timestamp with time zone,
  multi_hash character varying,
  url character varying
);

create type poll_order_by_type as enum ('NEAREST_END', 'FURTHEST_END', 'NEAREST_START', 'FURTHEST_START');

create type poll_stats as (
  active_polls bigint,
  finished_polls bigint,
  total_polls bigint
);

create or replace function api.polls(_first int, order_by poll_order_by_type default 'NEAREST_END')
returns setof poll_entry as $$
declare
  max_page_size_value int := (select api.max_page_size());
begin
  if _first > max_page_size_value then
    raise exception 'Parameter FIRST cannot be greater than %.', max_page_size_value
    return;
  else
    return query
      select creator, poll_id, timestamp, to_timestamp(start_date), to_timestamp(end_date), multi_hash, url
      from api.active_polls() A
      left join vulcan2x.block B
      on A.block_created = B.number
      order by
        -- First, order active polls before ended polls
        case when end_date > extract(epoch from now()) then 1 else 0 end desc,
        -- Then, apply the desired ordering
        case
          when order_by = 'NEAREST_END' then end_date
          when order_by = 'FURTHEST_END' then -end_date
          when order_by = 'NEAREST_START' then -start_date
          else start_date
        end,
        -- Finally, if sorted polls have the same dates, order them by poll ID descending
        poll_id desc;
  end if;
end;
$$ language plpgsql stable strict;

create or replace function api.polling_stats()
returns poll_stats as $$
  select active_polls, total_polls - active_polls as finished_polls, total_polls
  from (
    select count(*) as total_polls, count(case when start_date < extract(epoch from now()) and end_date > extract(epoch from now()) then 1 end) as active_polls
    from api.active_polls()
  ) A
$$ language sql stable strict;