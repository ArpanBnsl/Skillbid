-- ============================================================================
-- SkillBid Database Migration
-- Run this in Supabase SQL Editor to create all tables
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. Profiles Table (Users)
-- ============================================================================
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  full_name VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  avatar_url TEXT,
  last_role VARCHAR(50), -- 'client' or 'provider'
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_auth_user FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- ============================================================================
-- 2. Roles Table
-- ============================================================================
CREATE TABLE roles (
  id INT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO roles (id, name) VALUES (1, 'client'), (2, 'provider');

-- ============================================================================
-- 3. User Roles Junction Table
-- ============================================================================
CREATE TABLE user_roles (
  user_id UUID NOT NULL,
  role_id INT NOT NULL,
  PRIMARY KEY (user_id, role_id),
  FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);

-- ============================================================================
-- 4. Provider Profiles
-- ============================================================================
CREATE TABLE provider_profiles (
  user_id UUID PRIMARY KEY,
  bio TEXT,
  experience_years INT DEFAULT 0,
  hourly_rate DECIMAL(10, 2) DEFAULT 0,
  verified BOOLEAN DEFAULT FALSE, -- Admin only
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
);

-- ============================================================================
-- 5. Skills Table (Categories/Skills)
-- ============================================================================
CREATE TABLE skills (
  id INT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE
);

INSERT INTO skills (id, name) VALUES
  (1, 'Woodwork'),
  (2, 'Plumbing'),
  (3, 'Electrical'),
  (4, 'Interior Design'),
  (5, 'Full Home Renovation'),
  (6, 'Wall Makeovers'),
  (7, 'Flooring'),
  (8, 'Painting'),
  (9, 'Kitchen Remodel'),
  (10, 'Bathroom Remodel'),
  (11, 'Waterproofing'),
  (12, 'Carpentry');

-- ============================================================================
-- 6. Provider Skills
-- ============================================================================
CREATE TABLE provider_skills (
  provider_id UUID NOT NULL,
  skill_id INT NOT NULL,
  PRIMARY KEY (provider_id, skill_id),
  FOREIGN KEY (provider_id) REFERENCES provider_profiles(user_id) ON DELETE CASCADE,
  FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE
);

-- ============================================================================
-- 7. Jobs Table
-- ============================================================================
CREATE TABLE jobs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  budget DECIMAL(10, 2) NOT NULL,
  location VARCHAR(255) NOT NULL,
  skill_id INT NOT NULL,
  desired_completion_days INT,
  status VARCHAR(50) DEFAULT 'open', -- 'open', 'in_progress', 'completed', 'cancelled'
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (client_id) REFERENCES profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE RESTRICT
);

-- ============================================================================
-- 8. Job Images
-- ============================================================================
CREATE TABLE job_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID NOT NULL,
  image_url TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE
);

-- ============================================================================
-- 9. Bids
-- ============================================================================
CREATE TABLE bids (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID NOT NULL,
  provider_id UUID NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  estimated_days INT,
  message TEXT,
  status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'accepted', 'rejected', 'withdrawn'
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE,
  FOREIGN KEY (provider_id) REFERENCES provider_profiles(user_id) ON DELETE CASCADE,
  UNIQUE(job_id, provider_id) -- One bid per provider per job
);

-- ============================================================================
-- 10. Contracts (Accepted Bids)
-- ============================================================================
CREATE TABLE contracts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID NOT NULL,
  bid_id UUID NOT NULL,
  client_id UUID NOT NULL,
  provider_id UUID NOT NULL,
  status VARCHAR(50) DEFAULT 'active', -- 'active', 'completed', 'cancelled'
  start_date TIMESTAMP,
  end_date TIMESTAMP,
  rating INT, -- 1-5 stars
  review_text TEXT,
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE,
  FOREIGN KEY (bid_id) REFERENCES bids(id) ON DELETE CASCADE,
  FOREIGN KEY (client_id) REFERENCES profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (provider_id) REFERENCES provider_profiles(user_id) ON DELETE CASCADE
);

-- ============================================================================
-- 11. Provider Portfolio
-- ============================================================================
CREATE TABLE provider_portfolio (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  provider_id UUID NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  cost DECIMAL(10, 2),
  is_deleted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (provider_id) REFERENCES provider_profiles(user_id) ON DELETE CASCADE
);

-- ============================================================================
-- 12. Portfolio Images
-- ============================================================================
CREATE TABLE portfolio_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  portfolio_id UUID NOT NULL,
  image_url TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (portfolio_id) REFERENCES provider_portfolio(id) ON DELETE CASCADE
);

-- ============================================================================
-- 13. Chats (Only created after bid acceptance)
-- ============================================================================
CREATE TABLE chats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID NOT NULL,
  contract_id UUID, -- Links to the accepted bid/contract
  last_message_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE,
  FOREIGN KEY (contract_id) REFERENCES contracts(id) ON DELETE SET NULL,
  UNIQUE(job_id) -- One chat per job
);

-- ============================================================================
-- 14. Chat Participants
-- ============================================================================
CREATE TABLE chat_participants (
  chat_id UUID NOT NULL,
  user_id UUID NOT NULL,
  PRIMARY KEY (chat_id, user_id),
  FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
);

-- ============================================================================
-- 15. Messages
-- ============================================================================
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chat_id UUID NOT NULL,
  sender_id UUID NOT NULL,
  content TEXT NOT NULL,
  message_type VARCHAR(50) DEFAULT 'text', -- 'text', 'image', 'file'
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
  FOREIGN KEY (sender_id) REFERENCES profiles(id) ON DELETE CASCADE
);

-- ============================================================================
-- Indexes for Performance
-- ============================================================================
CREATE INDEX idx_profiles_last_role ON profiles(last_role);
CREATE INDEX idx_profiles_is_deleted ON profiles(is_deleted);
CREATE INDEX idx_provider_profiles_verified ON provider_profiles(verified);
CREATE INDEX idx_jobs_client_id ON jobs(client_id);
CREATE INDEX idx_jobs_skill_id ON jobs(skill_id);
CREATE INDEX idx_jobs_status ON jobs(status);
CREATE INDEX idx_jobs_created_at ON jobs(created_at DESC);
CREATE INDEX idx_bids_job_id ON bids(job_id);
CREATE INDEX idx_bids_provider_id ON bids(provider_id);
CREATE INDEX idx_bids_status ON bids(status);
CREATE INDEX idx_contracts_client_id ON contracts(client_id);
CREATE INDEX idx_contracts_provider_id ON contracts(provider_id);
CREATE INDEX idx_contracts_status ON contracts(status);
CREATE INDEX idx_messages_chat_id ON messages(chat_id);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX idx_chats_last_message_at ON chats(last_message_at DESC NULLS LAST);

-- ============================================================================
-- Row Level Security (Enable if you want RLS)
-- ============================================================================
-- ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE provider_profiles ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
-- ... (Add RLS policies as needed)

-- ============================================================================
-- Triggers for Updated_at Timestamps
-- ============================================================================
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_timestamp BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE PROCEDURE update_timestamp();
CREATE TRIGGER update_provider_profiles_timestamp BEFORE UPDATE ON provider_profiles FOR EACH ROW EXECUTE PROCEDURE update_timestamp();
CREATE TRIGGER update_jobs_timestamp BEFORE UPDATE ON jobs FOR EACH ROW EXECUTE PROCEDURE update_timestamp();
CREATE TRIGGER update_bids_timestamp BEFORE UPDATE ON bids FOR EACH ROW EXECUTE PROCEDURE update_timestamp();
CREATE TRIGGER update_contracts_timestamp BEFORE UPDATE ON contracts FOR EACH ROW EXECUTE PROCEDURE update_timestamp();
CREATE TRIGGER update_provider_portfolio_timestamp BEFORE UPDATE ON provider_portfolio FOR EACH ROW EXECUTE PROCEDURE update_timestamp();
CREATE TRIGGER update_chats_timestamp BEFORE UPDATE ON chats FOR EACH ROW EXECUTE PROCEDURE update_timestamp();
