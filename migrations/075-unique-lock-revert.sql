-- THIS SHOULD NOT BE MERGED INTO MASTER
--Rolls back 074
-- remove the new constraint that was added in 074
ALTER TABLE dschief.delegate_lock DROP CONSTRAINT delegate_lock_key;

-- add back the previous constraint
ALTER TABLE dschief.delegate_lock ADD CONSTRAINT delegate_lock_log_index_tx_id_key UNIQUE (log_index, tx_id);