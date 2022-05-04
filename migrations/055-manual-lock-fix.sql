UPDATE dschief.lock l
SET from_address = '0x84383092D31e1664126639876C536A8Ad1024A59'
FROM vulcan2x.block b
WHERE l.block_id = b.id
AND b.number = 13624992
AND l.lock = 103.3137;

UPDATE dschief.lock l
SET from_address = '0x84383092D31e1664126639876C536A8Ad1024A59'
FROM vulcan2x.block b
WHERE l.block_id = b.id
AND b.number = 13842058
AND l.lock = -103.3137;