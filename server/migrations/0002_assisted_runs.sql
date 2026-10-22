-- Batch 13: a run helped by Maestri, wagon props or the campaign counts in the player's own
-- stats but stays off the best-hand and town leaderboards.
ALTER TABLE runs ADD COLUMN assisted INTEGER NOT NULL DEFAULT 0;
