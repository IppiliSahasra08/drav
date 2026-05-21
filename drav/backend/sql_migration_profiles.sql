-- ============================================================================
-- Profiles Table & Auth Sync Trigger
-- ============================================================================
-- This script creates a profiles table linked to auth.users with automatic
-- row creation/update whenever a user signs up or updates their metadata.
--
-- The trigger function extracts onboarding_completed and preferences from
-- the user's raw_user_meta_data and syncs them to the profiles table.
-- ============================================================================

-- Create profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  onboarding_completed BOOLEAN DEFAULT FALSE,
  preferences JSONB DEFAULT '{}',
  CONSTRAINT onboarding_completed_check CHECK (onboarding_completed IS NOT NULL)
);

-- Create index on updated_at for efficient queries
CREATE INDEX IF NOT EXISTS idx_profiles_updated_at ON profiles(updated_at DESC);

-- Enable Row Level Security (RLS) on profiles table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policy: users can view their own profile
CREATE POLICY IF NOT EXISTS "Users can view their own profile" 
  ON profiles 
  FOR SELECT 
  USING (auth.uid() = id);

-- Create RLS policy: users can update their own profile
CREATE POLICY IF NOT EXISTS "Users can update their own profile" 
  ON profiles 
  FOR UPDATE 
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ============================================================================
-- Trigger Function: Sync auth.users metadata to profiles table
-- ============================================================================
-- This function runs whenever a user is created or updated in auth.users.
-- It extracts onboarding_completed and preferences from raw_user_meta_data
-- and creates or updates the corresponding profiles row.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_auth_user_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_onboarding_completed BOOLEAN;
  v_preferences JSONB;
BEGIN
  -- Extract onboarding_completed from raw_user_meta_data, default to FALSE
  v_onboarding_completed := COALESCE(
    (NEW.raw_user_meta_data->>'onboarding_completed')::BOOLEAN,
    FALSE
  );

  -- Extract preferences from raw_user_meta_data, default to empty object
  v_preferences := COALESCE(
    NEW.raw_user_meta_data->'preferences',
    '{}'::JSONB
  );

  -- Insert or update the profiles row
  INSERT INTO public.profiles (id, onboarding_completed, preferences, updated_at)
  VALUES (NEW.id, v_onboarding_completed, v_preferences, NOW())
  ON CONFLICT (id) DO UPDATE SET
    onboarding_completed = EXCLUDED.onboarding_completed,
    preferences = EXCLUDED.preferences,
    updated_at = NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger that fires after insert or update on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_auth_user_sync();

-- ============================================================================
-- Schema Cache Invalidation
-- ============================================================================
-- Notify PostgREST to reload the schema cache so changes take effect immediately
-- ============================================================================

NOTIFY pgrst, 'reload schema';
