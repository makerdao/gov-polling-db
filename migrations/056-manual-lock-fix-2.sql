--Temporary fix since the UI uses the tx.origin of lock events to group delegation events
--Gnosis Safe address is 0xf65475e74C1Ed6d004d5240b06E3088724dFDA5d
--Main address used is 0xc0583df0d10c2e87ae1873b728a0bda04d8b660c
--But user also used this address twice, which we are overwriting now: 0x2487fb0baa85e550fda42396d8c99ab03bd23fe1

UPDATE dschief.lock l
SET from_address = '0xc0583df0d10c2e87ae1873b728a0bda04d8b660c'
FROM vulcan2x.block b
WHERE l.block_id = b.id
AND b.number = 15256282
AND l.lock = -7610.756;

UPDATE dschief.lock l
SET from_address = '0xc0583df0d10c2e87ae1873b728a0bda04d8b660c'
FROM vulcan2x.block b
WHERE l.block_id = b.id
AND b.number = 15256118
AND l.lock = -7.618;