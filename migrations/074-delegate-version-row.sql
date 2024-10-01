-- Add optional version column as a number to dschief.vote_delegate_created_event table
ALTER TABLE dschief.vote_delegate_created_event
ADD COLUMN delegate_version INTEGER NULL;