-- Canlı DB: b2c4 stamp atlandığında veya create_all ile tablolar önceden oluştuysa
ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_device_token VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS city VARCHAR;
ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_code VARCHAR(16);
ALTER TABLE users ADD COLUMN IF NOT EXISTS referred_by_user_id INTEGER;

ALTER TABLE players_multivideo ADD COLUMN IF NOT EXISTS previous_overall_rating INTEGER;
ALTER TABLE players_multivideo ADD COLUMN IF NOT EXISTS profile_image_url VARCHAR;
ALTER TABLE players_multivideo ADD COLUMN IF NOT EXISTS city VARCHAR;
ALTER TABLE players_multivideo ADD COLUMN IF NOT EXISTS club_name VARCHAR;
ALTER TABLE players_multivideo ADD COLUMN IF NOT EXISTS club_history TEXT;
ALTER TABLE players_multivideo ADD COLUMN IF NOT EXISTS preferred_foot VARCHAR(20);
ALTER TABLE players_multivideo ADD COLUMN IF NOT EXISTS height_cm INTEGER;
ALTER TABLE players_multivideo ADD COLUMN IF NOT EXISTS weight_kg INTEGER;
