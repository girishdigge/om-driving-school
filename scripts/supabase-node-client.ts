/**
 * Node.js-compatible Supabase client for migration scripts
 * This client doesn't use localStorage and is suitable for server-side operations
 */
import { createClient } from '@supabase/supabase-js';
import type { Database } from '../src/integrations/supabase/types';

const SUPABASE_URL = 'https://ufzhifwznyzfrahibtnc.supabase.co';
const SUPABASE_PUBLISHABLE_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVmemhpZnd6bnl6ZnJhaGlidG5jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIyMDg5NzEsImV4cCI6MjEwNzc4NDk3MX0.5ddLKkPViW-XJMKrUoz-9hOEm1D6ZykcemiQgtxlzqI';

// Simple in-memory storage adapter for Node.js
class MemoryStorage {
  private storage: Map<string, string> = new Map();

  async getItem(key: string): Promise<string | null> {
    return this.storage.get(key) || null;
  }

  async setItem(key: string, value: string): Promise<void> {
    this.storage.set(key, value);
  }

  async removeItem(key: string): Promise<void> {
    this.storage.delete(key);
  }
}

// Create a Node.js-compatible Supabase client with memory storage
export const supabaseNode = createClient<Database>(
  SUPABASE_URL,
  SUPABASE_PUBLISHABLE_KEY,
  {
    auth: {
      storage: new MemoryStorage(),
      persistSession: false,
      autoRefreshToken: false,
    },
  },
);
