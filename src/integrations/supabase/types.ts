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
        Row: { id:string;seller_id:string;payment_code:string;gross_amount_eur:number;currency:string;payment_method:string;fee_percent_snapshot:number;fee_amount_eur:number;net_amount_eur:number;status:string;reference:string|null;order_id:string|null;notes:string|null;mbway_phone_snapshot:string|null;central_iban_snapshot:string|null;proof_path:string|null;proof_mime_type:string|null;proof_size_bytes:number|null;admin_notes:string|null;decision_reason:string|null;decided_by:string|null;receipt_id:string|null;risk_reason:string|null;idempotency_key:string|null;submitted_at:string;approved_at:string|null;created_at:string;updated_at:string }
        Insert: { id?:string;seller_id:string;payment_code?:string;gross_amount_eur:number;currency?:string;payment_method?:string;fee_percent_snapshot:number;fee_amount_eur:number;net_amount_eur:number;status?:string;reference?:string|null;order_id?:string|null;notes?:string|null;mbway_phone_snapshot?:string|null;central_iban_snapshot?:string|null;proof_path?:string|null;proof_mime_type?:string|null;proof_size_bytes?:number|null;admin_notes?:string|null;decision_reason?:string|null;decided_by?:string|null;receipt_id?:string|null;risk_reason?:string|null;idempotency_key?:string|null;submitted_at?:string;approved_at?:string|null;created_at?:string;updated_at?:string }
        Update: { id?:string;seller_id?:string;payment_code?:string;gross_amount_eur?:number;currency?:string;payment_method?:string;fee_percent_snapshot?:number;fee_amount_eur?:number;net_amount_eur?:number;status?:string;reference?:string|null;order_id?:string|null;notes?:string|null;mbway_phone_snapshot?:string|null;central_iban_snapshot?:string|null;proof_path?:string|null;proof_mime_type?:string|null;proof_size_bytes?:number|null;admin_notes?:string|null;decision_reason?:string|null;decided_by?:string|null;receipt_id?:string|null;risk_reason?:string|null;idempotency_key?:string|null;submitted_at?:string;approved_at?:string|null;created_at?:string;updated_at?:string }
        Relationships: []
      },
      withdrawals: {
        Row: { id:string;seller_id:string;amount_eur:number;fixed_fee_snapshot_eur:number;status:string;created_at:string;confirmed_at:string|null;updated_at:string;withdrawal_method_id:string|null;method_type_snapshot:string|null;destination_holder_name_snapshot:string|null;destination_tax_id_snapshot:string|null;destination_pix_key_type_snapshot:string|null;destination_pix_key_snapshot:string|null;destination_iban_snapshot:string|null;destination_country_snapshot:string|null;destination_bic_swift_snapshot:string|null;destination_revtag_snapshot:string|null;destination_masked_snapshot:string|null;net_amount_eur:number|null;payment_reference:string|null;payment_proof_path:string|null;paid_amount_brl:number|null;paid_at:string|null;decision_reason:string|null;decided_by:string|null;rules_updated_at_snapshot:string|null }
        Insert: { id?:string;seller_id:string;amount_eur:number;fixed_fee_snapshot_eur:number;status?:string;created_at?:string;confirmed_at?:string|null;updated_at?:string;withdrawal_method_id?:string|null;method_type_snapshot?:string|null;destination_holder_name_snapshot?:string|null;destination_tax_id_snapshot?:string|null;destination_pix_key_type_snapshot?:string|null;destination_pix_key_snapshot?:string|null;destination_iban_snapshot?:string|null;destination_country_snapshot?:string|null;destination_bic_swift_snapshot?:string|null;destination_revtag_snapshot?:string|null;destination_masked_snapshot?:string|null;net_amount_eur?:number|null;payment_reference?:string|null;payment_proof_path?:string|null;paid_amount_brl?:number|null;paid_at?:string|null;decision_reason?:string|null;decided_by?:string|null;rules_updated_at_snapshot?:string|null }
        Update: { id?:string;seller_id?:string;amount_eur?:number;fixed_fee_snapshot_eur?:number;status?:string;created_at?:string;confirmed_at?:string|null;updated_at?:string;withdrawal_method_id?:string|null;method_type_snapshot?:string|null;destination_holder_name_snapshot?:string|null;destination_tax_id_snapshot?:string|null;destination_pix_key_type_snapshot?:string|null;destination_pix_key_snapshot?:string|null;destination_country_snapshot?:string|null;destination_bic_swift_snapshot?:string|null;destination_revtag_snapshot?:string|null;destination_masked_snapshot?:string|null;net_amount_eur?:number|null;payment_reference?:string|null;payment_proof_path?:string|null;paid_amount_brl?:number|null;paid_at?:string|null;decision_reason?:string|null;decided_by?:string|null;rules_updated_at_snapshot?:string|null }
        Relationships: []
      },
      withdrawal_methods: {
        Row:{id:string;seller_id:string;method_type:string;holder_name:string;tax_id:string;pix_key_type:string|null;pix_key:string|null;iban:string|null;country:string|null;bic_swift:string|null;revtag:string|null;ownership_declared:boolean;ownership_declared_at:string|null;is_default:boolean;is_active:boolean;created_at:string;updated_at:string}
        Insert:{id?:string;seller_id:string;method_type:string;holder_name:string;tax_id:string;pix_key_type?:string|null;pix_key?:string|null;iban?:string|null;country?:string|null;bic_swift?:string|null;revtag?:string|null;ownership_declared?:boolean;ownership_declared_at?:string|null;is_default?:boolean;is_active?:boolean;created_at?:string;updated_at?:string}
        Update:{id?:string;seller_id?:string;method_type?:string;holder_name?:string;tax_id?:string;pix_key_type?:string|null;pix_key?:string|null;iban?:string|null;country?:string|null;bic_swift?:string|null;revtag?:string|null;ownership_declared?:boolean;ownership_declared_at?:string|null;is_default?:boolean;is_active?:boolean;created_at?:string;updated_at?:string}
        Relationships:[]
      },
      central_receipts: {
        Row:{id:string;receipt_reference:string;received_at:string;amount_eur:number;payment_method:string;observation:string|null;seller_id:string|null;payment_id:string|null;created_by:string;created_at:string}
        Insert:{id?:string;receipt_reference:string;received_at?:string;amount_eur:number;payment_method:string;observation?:string|null;seller_id?:string|null;payment_id?:string|null;created_by:string;created_at?:string}
        Update:{id?:string;receipt_reference?:string;received_at?:string;amount_eur?:number;payment_method?:string;observation?:string|null;seller_id?:string|null;payment_id?:string|null;created_by?:string;created_at?:string}
        Relationships:[]
      },
      payment_financial_ledger: {
        Row:{id:string;seller_id:string;payment_id:string|null;withdrawal_id:string|null;entry_type:string;amount_eur:number;reason:string;created_by:string;created_at:string}
        Insert:{id?:string;seller_id:string;payment_id?:string|null;withdrawal_id?:string|null;entry_type:string;amount_eur:number;reason:string;created_by:string;created_at?:string}
        Update:{id?:string;seller_id?:string;payment_id?:string|null;withdrawal_id?:string|null;entry_type?:string;amount_eur?:number;reason?:string;created_by?:string;created_at?:string}
        Relationships:[]
      },
      payment_admin_notes: {
        Row:{id:string;payment_id:string;admin_id:string;note:string;created_at:string}
        Insert:{id?:string;payment_id:string;admin_id:string;note:string;created_at?:string}
        Update:{id?:string;payment_id?:string;admin_id?:string;note?:string;created_at?:string}
        Relationships:[]
      },
    Views: {
      [_ in never]: never
    }
    Functions: {
      save_platform_settings: { Args: { p_mbway_phone: string | null; p_central_iban: string | null; p_platform_fee_percent: number; p_minimum_withdrawal_eur: number; p_withdrawal_fixed_fee_eur: number; p_withdrawals_paused: boolean }; Returns: Database["public"]["Tables"]["platform_settings"]["Row"] }
      submit_payment: { Args: { p_gross_amount_eur: number; p_reference?: string | null }; Returns: Database["public"]["Tables"]["payment_records"]["Row"] }
      request_withdrawal: { Args: { p_amount_eur: number; p_withdrawal_method_id: string; p_rules_updated_at: string }; Returns: Database["public"]["Tables"]["withdrawals"]["Row"] }
      create_withdrawal_method: { Args: { p_method_type:string;p_holder_name:string;p_tax_id:string;p_pix_key_type?:string|null;p_pix_key?:string|null;p_iban?:string|null;p_country?:string|null;p_bic_swift?:string|null;p_revtag?:string|null;p_ownership_declared?:boolean }; Returns: Database["public"]["Tables"]["withdrawal_methods"]["Row"] }
      set_default_withdrawal_method: { Args: { p_method_id:string }; Returns: Database["public"]["Tables"]["withdrawal_methods"]["Row"] }
      deactivate_withdrawal_method: { Args: { p_method_id:string }; Returns: Database["public"]["Tables"]["withdrawal_methods"]["Row"] }
      cancel_own_withdrawal: { Args: { p_withdrawal_id:string }; Returns: Database["public"]["Tables"]["withdrawals"]["Row"] }
      admin_set_withdrawal_status: { Args: { p_withdrawal_id:string;p_status:string;p_reason?:string|null }; Returns: Database["public"]["Tables"]["withdrawals"]["Row"] }
      admin_mark_withdrawal_paid: { Args: { p_withdrawal_id:string;p_payment_reference:string;p_payment_proof_path:string;p_paid_amount_brl?:number|null }; Returns: Database["public"]["Tables"]["withdrawals"]["Row"] }
      create_payment_submission: { Args: { p_gross_amount_eur:number;p_payment_method:string;p_reference:string|null;p_order_id:string|null;p_notes:string|null;p_idempotency_key:string }; Returns: Database["public"]["Tables"]["payment_records"]["Row"] }
      finalize_payment_submission: { Args: { p_payment_id:string;p_proof_path:string;p_proof_mime_type:string;p_proof_size_bytes:number }; Returns: Database["public"]["Tables"]["payment_records"]["Row"] }
      cleanup_failed_payment_submission: { Args: { p_payment_id:string }; Returns: boolean }
      admin_add_payment_note: { Args: { p_payment_id:string;p_note:string }; Returns: Database["public"]["Tables"]["payment_admin_notes"]["Row"] }
      admin_reject_payment: { Args: { p_payment_id:string;p_reason:string }; Returns: Database["public"]["Tables"]["payment_records"]["Row"] }
      admin_escalate_payment: { Args: { p_payment_id:string;p_reason:string }; Returns: Database["public"]["Tables"]["payment_records"]["Row"] }
      admin_approve_payment: { Args: { p_payment_id:string;p_receipt_id:string|null;p_new_receipt_reference:string|null;p_new_receipt_at:string|null;p_new_receipt_amount_eur:number|null;p_new_receipt_method:string|null;p_new_receipt_observation:string|null }; Returns: Database["public"]["Tables"]["payment_records"]["Row"] }
      admin_reverse_payment: { Args: { p_payment_id:string;p_reason:string }; Returns: Database["public"]["Tables"]["payment_records"]["Row"] }
      admin_create_central_receipt: { Args: { p_reference:string;p_received_at:string|null;p_amount_eur:number;p_method:string;p_observation:string|null }; Returns: Database["public"]["Tables"]["central_receipts"]["Row"] }
      get_seller_dashboard: { Args: { p_start?: string | null; p_end?: string | null }; Returns: { available_balance_eur: number; pending_balance_eur: number; approved_volume_eur: number; at_risk_eur: number; reserved_withdrawals_eur: number }[] }
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
