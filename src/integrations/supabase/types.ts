export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18"
  }
  public: {
    Tables: {
      profiles: {
        Row: {
          accepted_terms_at: string | null
          admin_level: string
          created_at: string | null
          email: string
          full_name: string
          id: string
          suspended_at: string | null
          suspension_reason: string | null
          role: Database["public"]["Enums"]["user_role"]
          status: Database["public"]["Enums"]["user_status"]
          updated_at: string | null
        }
        Insert: {
          accepted_terms_at?: string | null
          admin_level?: string
          created_at?: string | null
          email?: string
          full_name?: string
          id: string
          suspended_at?: string | null
          suspension_reason?: string | null
          role?: Database["public"]["Enums"]["user_role"]
          status?: Database["public"]["Enums"]["user_status"]
          updated_at?: string | null
        }
        Update: {
          accepted_terms_at?: string | null
          admin_level?: string
          created_at?: string | null
          email?: string
          full_name?: string
          id?: string
          suspended_at?: string | null
          suspension_reason?: string | null
          role?: Database["public"]["Enums"]["user_role"]
          status?: Database["public"]["Enums"]["user_status"]
          updated_at?: string | null
        }
        Relationships: []
      },
      platform_settings: {
        Row: { id: number; mbway_phone: string | null; central_iban: string | null; platform_fee_percent: number; minimum_withdrawal_eur: number; withdrawal_fixed_fee_eur: number; withdrawals_paused: boolean; initialized_at: string | null; updated_at: string; updated_by: string | null }
        Insert: { id?: number; mbway_phone?: string | null; central_iban?: string | null; platform_fee_percent?: number; minimum_withdrawal_eur?: number; withdrawal_fixed_fee_eur?: number; withdrawals_paused?: boolean; initialized_at?: string | null; updated_at?: string; updated_by?: string | null }
        Update: { id?: number; mbway_phone?: string | null; central_iban?: string | null; platform_fee_percent?: number; minimum_withdrawal_eur?: number; withdrawal_fixed_fee_eur?: number; withdrawals_paused?: boolean; initialized_at?: string | null; updated_at?: string; updated_by?: string | null }
        Relationships: []
      },
      payment_records: {
        Row: { id: string; seller_id: string; gross_amount_eur: number; fee_percent_snapshot: number; fee_amount_eur: number; net_amount_eur: number; status: string; reference: string | null; submitted_at: string; approved_at: string | null; created_at: string; updated_at: string }
        Insert: { id?: string; seller_id: string; gross_amount_eur: number; fee_percent_snapshot: number; fee_amount_eur: number; net_amount_eur: number; status?: string; reference?: string | null; submitted_at?: string; approved_at?: string | null; created_at?: string; updated_at?: string }
        Update: { id?: string; seller_id?: string; gross_amount_eur?: number; fee_percent_snapshot?: number; fee_amount_eur?: number; net_amount_eur?: number; status?: string; reference?: string | null; submitted_at?: string; approved_at?: string | null; created_at?: string; updated_at?: string }
        Relationships: []
      },
      withdrawals: {
        Row: { id: string; seller_id: string; amount_eur: number; fixed_fee_snapshot_eur: number; status: string; created_at: string; confirmed_at: string | null; updated_at: string }
        Insert: { id?: string; seller_id: string; amount_eur: number; fixed_fee_snapshot_eur: number; status?: string; created_at?: string; confirmed_at?: string | null; updated_at?: string }
        Update: { id?: string; seller_id?: string; amount_eur?: number; fixed_fee_snapshot_eur?: number; status?: string; created_at?: string; confirmed_at?: string | null; updated_at?: string }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      save_platform_settings: { Args: { p_mbway_phone: string | null; p_central_iban: string | null; p_platform_fee_percent: number; p_minimum_withdrawal_eur: number; p_withdrawal_fixed_fee_eur: number; p_withdrawals_paused: boolean }; Returns: Database["public"]["Tables"]["platform_settings"]["Row"] }
      get_seller_dashboard: { Args: {}; Returns: { available_balance_eur: number; pending_balance_eur: number; approved_volume_eur: number; at_risk_eur: number; reserved_withdrawals_eur: number }[] }
      update_my_profile: { Args: { p_full_name: string }; Returns: Database["public"]["Tables"]["profiles"]["Row"] }
      suspend_seller: { Args: { p_user_id: string; p_reason: string }; Returns: undefined }
      reactivate_seller: { Args: { p_user_id: string; p_reason: string }; Returns: undefined }
      bootstrap_superadmin: { Args: { p_email: string }; Returns: undefined }
      invite_admin_record: { Args: { p_email: string }; Returns: string }
      revoke_admin: { Args: { p_user_id: string; p_reason: string }; Returns: undefined }
    }
    Enums: {
      user_role: "seller" | "admin"
      user_status: "pending" | "active" | "suspended" | "rejected"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      user_role: ["seller", "admin"],
      user_status: ["pending", "active", "suspended", "rejected"],
    },
  },
} as const
