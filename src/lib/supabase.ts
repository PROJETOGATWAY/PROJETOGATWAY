import type { SupabaseClient } from "@supabase/supabase-js";
import { supabase } from "@/integrations/supabase/client";
export function getSupabase(): SupabaseClient { return supabase as unknown as SupabaseClient; }
