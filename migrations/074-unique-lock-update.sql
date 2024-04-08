-- existing contraint is (log_index, tx_id) and this does not work with multi-send transactions from gnosis safe
ALTER TABLE dschief.delegate_lock DROP CONSTRAINT delegate_lock_log_index_tx_id_key;

-- add a new constraint that includes the lock value and the from_address (delegate contract)
ALTER TABLE dschief.delegate_lock ADD CONSTRAINT delegate_lock_key UNIQUE (log_index, tx_id, from_address, lock);