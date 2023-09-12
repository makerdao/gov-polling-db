create or replace function api.polls_vote_breakdown(param_poll_ids integer[])
returns table (
  poll_id INTEGER,
	option_id CHARACTER,
	mkr_support NUMERIC
) as $$
  with merged_votes as (
	SELECT DISTINCT (poll_id) poll_id, voter, option_id_raw, timestamp
	FROM (
		SELECT voter, option_id_raw, poll_id, b.timestamp
		FROM polling.voted_event ve
		JOIN vulcan2x.block b ON ve.block_id = b.id
			UNION
		SELECT voter, option_id_raw, poll_id, ba.timestamp
		FROM polling.voted_event_arbitrum vea
		JOIN vulcan2xarbitrum.block ba ON vea.block_id = ba.id
	) sub1
),
votes_with_end_date as (
	select voter, v.poll_id, option_id_raw, v.timestamp as vote_time, p.end_date, (
	    	select id from vulcan2x.block where timestamp <= to_timestamp(end_date)
	    	order by timestamp desc limit 1
	  	) as end_block
	from merged_votes v left join api.active_polls() p
	on v.poll_id = p.poll_id
	where p.poll_id is not null
),
unique_votes_with_mkr as (
	select voter, poll_id, option_id_raw, polling.reverse_voter_weight(voter, end_block) mkr_balance
	from (
		select
			polling.unique_voter_address(voter, end_block) voter,
			poll_id,
			(array_agg(option_id_raw ORDER BY vote_time DESC))[1] AS option_id_raw,
			end_block
		from votes_with_end_date
		where vote_time <= to_timestamp(end_date)
		group by poll_id, voter, end_block
		order by poll_id, voter
	) vwed
)
select 
	poll_id,
	option_id_raw,
	sum(mkr_balance) as mkr_support
from unique_votes_with_mkr
where poll_id = ANY (param_poll_ids)
group by poll_id, option_id_raw
order by poll_id, option_id_raw
$$ language sql stable strict;