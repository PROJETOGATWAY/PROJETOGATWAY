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
      admin_invitations: {
        Row: {
          accepted_at: string | null
          created_at: string
          email: string
          expires_at: string
          full_name: string | null
          id: string
          invited_by: string
          role: string
          status: string
        }
        Insert: {
          accepted_at?: string | null
          created_at?: string
          email: string
          expires_at?: string
          full_name?: string | null
          id?: string
          invited_by: string
          role?: string
          status?: string
        }
        Update: {
          accepted_at?: string | null
          created_at?: string
          email?: string
          expires_at?: string
          full_name?: string | null
          id?: string
          invited_by?: string
          role?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "admin_invitations_invited_by_fkey"
            columns: ["invited_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      audit_logs: {
        Row: {
          action: string
          actor_id: string | null
          created_at: string
          id: number
          metadata: Json
          target_user_id: string | null
        }
        Insert: {
          action: string
          actor_id?: string | null
          created_at?: string
          id?: never
          metadata?: Json
          target_user_id?: string | null
        }
        Update: {
          action?: string
          actor_id?: string | null
          created_at?: string
          id?: never
          metadata?: Json
          target_user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "audit_logs_actor_id_fkey"
            columns: ["actor_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "audit_logs_target_user_id_fkey"
            columns: ["target_user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      central_receipts: {
        Row: {
          amount_eur: number
          created_at: string
          created_by: string
          id: string
          observation: string | null
          payment_id: string | null
          payment_method: string
          receipt_reference: string
          received_at: string
          seller_id: string | null
        }
        Insert: {
          amount_eur: number
          created_at?: string
          created_by: string
          id?: string
          observation?: string | null
          payment_id?: string | null
          payment_method: string
          receipt_reference: string
          received_at?: string
          seller_id?: string | null
        }
        Update: {
          amount_eur?: number
          created_at?: string
          created_by?: string
          id?: string
          observation?: string | null
          payment_id?: string | null
          payment_method?: string
          receipt_reference?: string
          received_at?: string
          seller_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "central_receipts_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "central_receipts_payment_id_fkey"
            columns: ["payment_id"]
            isOneToOne: false
            referencedRelation: "payment_records"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "central_receipts_seller_id_fkey"
            columns: ["seller_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      compensation_adjustments: {
        Row: {
          amount_eur: number
          beneficiary_id: string
          compensation_entry_id: string
          created_at: string
          created_by: string
          id: string
          payment_id: string
          reason: string
        }
        Insert: {
          amount_eur: number
          beneficiary_id: string
          compensation_entry_id: string
          created_at?: string
          created_by: string
          id?: string
          payment_id: string
          reason: string
        }
        Update: {
          amount_eur?: number
          beneficiary_id?: string
          compensation_entry_id?: string
          created_at?: string
          created_by?: string
          id?: string
          payment_id?: string
          reason?: string
        }
        Relationships: [
          {
            foreignKeyName: "compensation_adjustments_beneficiary_id_fkey"
            columns: ["beneficiary_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "compensation_adjustments_compensation_entry_id_fkey"
            columns: ["compensation_entry_id"]
            isOneToOne: false
            referencedRelation: "compensation_entries"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "compensation_adjustments_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "compensation_adjustments_payment_id_fkey"
            columns: ["payment_id"]
            isOneToOne: false
            referencedRelation: "payment_records"
            referencedColumns: ["id"]
          },
        ]
      }
      compensation_entries: {
        Row: {
          amount_eur: number
          applied_percent: number
          beneficiary_id: string
          configured_percent: number
          created_at: string
          gross_amount_eur: number
          id: string
          payment_id: string
          rule_id: string | null
        }
        Insert: {
          amount_eur: number
          applied_percent: number
          beneficiary_id: string
          configured_percent: number
          created_at?: string
          gross_amount_eur: number
          id?: string
          payment_id: string
          rule_id?: string | null
        }
        Update: {
          amount_eur?: number
          applied_percent?: number
          beneficiary_id?: string
          configured_percent?: number
          created_at?: string
          gross_amount_eur?: number
          id?: string
          payment_id?: string
          rule_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "compensation_entries_beneficiary_id_fkey"
            columns: ["beneficiary_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "compensation_entries_payment_id_fkey"
            columns: ["payment_id"]
            isOneToOne: false
            referencedRelation: "payment_records"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "compensation_entries_rule_id_fkey"
            columns: ["rule_id"]
            isOneToOne: false
            referencedRelation: "compensation_rules"
            referencedColumns: ["id"]
          },
        ]
      }
      compensation_rules: {
        Row: {
          activated_at: string | null
          active: boolean
          beneficiary_id: string
          configured_percent: number
          created_at: string
          created_by: string
          deactivated_at: string | null
          id: string
          platform_fee_percent_at_activation: number
          updated_at: string
          version: number
        }
        Insert: {
          activated_at?: string | null
          active?: boolean
          beneficiary_id: string
          configured_percent: number
          created_at?: string
          created_by: string
          deactivated_at?: string | null
          id?: string
          platform_fee_percent_at_activation: number
          updated_at?: string
          version: number
        }
        Update: {
          activated_at?: string | null
          active?: boolean
          beneficiary_id?: string
          configured_percent?: number
          created_at?: string
          created_by?: string
          deactivated_at?: string | null
          id?: string
          platform_fee_percent_at_activation?: number
          updated_at?: string
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "compensation_rules_beneficiary_id_fkey"
            columns: ["beneficiary_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "compensation_rules_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      compensation_settlement_allocations: {
        Row: {
          amount_eur: number
          compensation_entry_id: string
          created_at: string
          id: string
          settlement_id: string
        }
        Insert: {
          amount_eur: number
          compensation_entry_id: string
          created_at?: string
          id?: string
          settlement_id: string
        }
        Update: {
          amount_eur?: number
          compensation_entry_id?: string
          created_at?: string
          id?: string
          settlement_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "compensation_settlement_allocations_compensation_entry_id_fkey"
            columns: ["compensation_entry_id"]
            isOneToOne: false
            referencedRelation: "compensation_entries"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "compensation_settlement_allocations_settlement_id_fkey"
            columns: ["settlement_id"]
            isOneToOne: false
            referencedRelation: "compensation_settlements"
            referencedColumns: ["id"]
          },
        ]
      }
      compensation_settlements: {
        Row: {
          amount_eur: number
          beneficiary_id: string
          created_at: string
          created_by: string
          id: string
          observation: string | null
          proof_path: string | null
          reference: string | null
          settlement_date: string
          settlement_method: string
        }
        Insert: {
          amount_eur: number
          beneficiary_id: string
          created_at?: string
          created_by: string
          id?: string
          observation?: string | null
          proof_path?: string | null
          reference?: string | null
          settlement_date: string
          settlement_method: string
        }
        Update: {
          amount_eur?: number
          beneficiary_id?: string
          created_at?: string
          created_by?: string
          id?: string
          observation?: string | null
          proof_path?: string | null
          reference?: string | null
          settlement_date?: string
          settlement_method?: string
        }
        Relationships: [
          {
            foreignKeyName: "compensation_settlements_beneficiary_id_fkey"
            columns: ["beneficiary_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "compensation_settlements_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      counter_commissions: {
        Row: {
          counter_id: string
          percent: number
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          counter_id: string
          percent?: number
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          counter_id?: string
          percent?: number
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "counter_commissions_counter_id_fkey"
            columns: ["counter_id"]
            isOneToOne: true
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "counter_commissions_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      notifications: {
        Row: {
          created_at: string
          dedupe_key: string
          id: string
          message: string
          read_at: string | null
          recipient_id: string
          related_id: string | null
          related_type: string | null
          title: string
          type: string
        }
        Insert: {
          created_at?: string
          dedupe_key: string
          id?: string
          message: string
          read_at?: string | null
          recipient_id: string
          related_id?: string | null
          related_type?: string | null
          title: string
          type: string
        }
        Update: {
          created_at?: string
          dedupe_key?: string
          id?: string
          message?: string
          read_at?: string | null
          recipient_id?: string
          related_id?: string | null
          related_type?: string | null
          title?: string
          type?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_recipient_id_fkey"
            columns: ["recipient_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      payment_admin_notes: {
        Row: {
          admin_id: string
          created_at: string
          id: string
          note: string
          payment_id: string
        }
        Insert: {
          admin_id: string
          created_at?: string
          id?: string
          note: string
          payment_id: string
        }
        Update: {
          admin_id?: string
          created_at?: string
          id?: string
          note?: string
          payment_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "payment_admin_notes_admin_id_fkey"
            columns: ["admin_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_admin_notes_payment_id_fkey"
            columns: ["payment_id"]
            isOneToOne: false
            referencedRelation: "payment_records"
            referencedColumns: ["id"]
          },
        ]
      }
      payment_financial_ledger: {
        Row: {
          amount_eur: number
          created_at: string
          created_by: string
          entry_type: string
          id: string
          payment_id: string | null
          reason: string
          seller_id: string
          withdrawal_id: string | null
        }
        Insert: {
          amount_eur: number
          created_at?: string
          created_by: string
          entry_type: string
          id?: string
          payment_id?: string | null
          reason: string
          seller_id: string
          withdrawal_id?: string | null
        }
        Update: {
          amount_eur?: number
          created_at?: string
          created_by?: string
          entry_type?: string
          id?: string
          payment_id?: string | null
          reason?: string
          seller_id?: string
          withdrawal_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "payment_financial_ledger_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_financial_ledger_payment_id_fkey"
            columns: ["payment_id"]
            isOneToOne: false
            referencedRelation: "payment_records"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_financial_ledger_seller_id_fkey"
            columns: ["seller_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_financial_ledger_withdrawal_id_fkey"
            columns: ["withdrawal_id"]
            isOneToOne: false
            referencedRelation: "withdrawals"
            referencedColumns: ["id"]
          },
        ]
      }
      payment_records: {
        Row: {
          admin_notes: string | null
          approved_at: string | null
          central_iban_snapshot: string | null
          compensation_beneficiary_id: string | null
          compensation_percent_applied: number | null
          compensation_percent_configured: number | null
          compensation_rule_id: string | null
          created_at: string
          currency: string
          decided_by: string | null
          decision_reason: string | null
          fee_amount_eur: number
          fee_percent_snapshot: number
          gross_amount_eur: number
          id: string
          idempotency_key: string | null
          mbway_phone_snapshot: string | null
          net_amount_eur: number
          notes: string | null
          order_id: string | null
          payment_code: string
          payment_method: string | null
          proof_mime_type: string | null
          proof_path: string | null
          proof_size_bytes: number | null
          receipt_id: string | null
          reference: string | null
          risk_reason: string | null
          seller_id: string
          status: string
          submitted_at: string
          updated_at: string
        }
        Insert: {
          admin_notes?: string | null
          approved_at?: string | null
          central_iban_snapshot?: string | null
          compensation_beneficiary_id?: string | null
          compensation_percent_applied?: number | null
          compensation_percent_configured?: number | null
          compensation_rule_id?: string | null
          created_at?: string
          currency?: string
          decided_by?: string | null
          decision_reason?: string | null
          fee_amount_eur: number
          fee_percent_snapshot: number
          gross_amount_eur: number
          id?: string
          idempotency_key?: string | null
          mbway_phone_snapshot?: string | null
          net_amount_eur: number
          notes?: string | null
          order_id?: string | null
          payment_code?: string
          payment_method?: string | null
          proof_mime_type?: string | null
          proof_path?: string | null
          proof_size_bytes?: number | null
          receipt_id?: string | null
          reference?: string | null
          risk_reason?: string | null
          seller_id: string
          status?: string
          submitted_at?: string
          updated_at?: string
        }
        Update: {
          admin_notes?: string | null
          approved_at?: string | null
          central_iban_snapshot?: string | null
          compensation_beneficiary_id?: string | null
          compensation_percent_applied?: number | null
          compensation_percent_configured?: number | null
          compensation_rule_id?: string | null
          created_at?: string
          currency?: string
          decided_by?: string | null
          decision_reason?: string | null
          fee_amount_eur?: number
          fee_percent_snapshot?: number
          gross_amount_eur?: number
          id?: string
          idempotency_key?: string | null
          mbway_phone_snapshot?: string | null
          net_amount_eur?: number
          notes?: string | null
          order_id?: string | null
          payment_code?: string
          payment_method?: string | null
          proof_mime_type?: string | null
          proof_path?: string | null
          proof_size_bytes?: number | null
          receipt_id?: string | null
          reference?: string | null
          risk_reason?: string | null
          seller_id?: string
          status?: string
          submitted_at?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "payment_records_compensation_beneficiary_id_fkey"
            columns: ["compensation_beneficiary_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_records_compensation_rule_id_fkey"
            columns: ["compensation_rule_id"]
            isOneToOne: false
            referencedRelation: "compensation_rules"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_records_decided_by_fkey"
            columns: ["decided_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payment_records_seller_id_fkey"
            columns: ["seller_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      platform_settings: {
        Row: {
          central_iban: string | null
          id: number
          initialized_at: string | null
          mbway_phone: string | null
          minimum_withdrawal_eur: number
          platform_fee_percent: number
          updated_at: string
          updated_by: string | null
          withdrawal_fixed_fee_eur: number
          withdrawals_paused: boolean
        }
        Insert: {
          central_iban?: string | null
          id?: number
          initialized_at?: string | null
          mbway_phone?: string | null
          minimum_withdrawal_eur?: number
          platform_fee_percent?: number
          updated_at?: string
          updated_by?: string | null
          withdrawal_fixed_fee_eur?: number
          withdrawals_paused?: boolean
        }
        Update: {
          central_iban?: string | null
          id?: number
          initialized_at?: string | null
          mbway_phone?: string | null
          minimum_withdrawal_eur?: number
          platform_fee_percent?: number
          updated_at?: string
          updated_by?: string | null
          withdrawal_fixed_fee_eur?: number
          withdrawals_paused?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "platform_settings_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          accepted_terms_at: string | null
          admin_level: string
          counter_previous_role: string | null
          created_at: string | null
          email: string
          full_name: string
          id: string
          role: Database["public"]["Enums"]["user_role"]
          status: Database["public"]["Enums"]["user_status"]
          suspended_at: string | null
          suspension_reason: string | null
          updated_at: string | null
        }
        Insert: {
          accepted_terms_at?: string | null
          admin_level?: string
          counter_previous_role?: string | null
          created_at?: string | null
          email?: string
          full_name?: string
          id: string
          role?: Database["public"]["Enums"]["user_role"]
          status?: Database["public"]["Enums"]["user_status"]
          suspended_at?: string | null
          suspension_reason?: string | null
          updated_at?: string | null
        }
        Update: {
          accepted_terms_at?: string | null
          admin_level?: string
          counter_previous_role?: string | null
          created_at?: string | null
          email?: string
          full_name?: string
          id?: string
          role?: Database["public"]["Enums"]["user_role"]
          status?: Database["public"]["Enums"]["user_status"]
          suspended_at?: string | null
          suspension_reason?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
      support_messages: {
        Row: {
          author_id: string
          created_at: string
          id: string
          message: string
          ticket_id: string
        }
        Insert: {
          author_id: string
          created_at?: string
          id?: string
          message: string
          ticket_id: string
        }
        Update: {
          author_id?: string
          created_at?: string
          id?: string
          message?: string
          ticket_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "support_messages_author_id_fkey"
            columns: ["author_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "support_messages_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "support_tickets"
            referencedColumns: ["id"]
          },
        ]
      }
      support_tickets: {
        Row: {
          created_at: string
          id: string
          message: string
          resolved_at: string | null
          seller_id: string
          status: string
          subject: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          message: string
          resolved_at?: string | null
          seller_id: string
          status?: string
          subject: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          message?: string
          resolved_at?: string | null
          seller_id?: string
          status?: string
          subject?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "support_tickets_seller_id_fkey"
            columns: ["seller_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      withdrawal_methods: {
        Row: {
          bic_swift: string | null
          country: string | null
          created_at: string
          holder_name: string
          iban: string | null
          id: string
          is_active: boolean
          is_default: boolean
          method_type: string
          ownership_declared: boolean
          ownership_declared_at: string | null
          pix_key: string | null
          pix_key_type: string | null
          revtag: string | null
          seller_id: string
          tax_id: string | null
          updated_at: string
        }
        Insert: {
          bic_swift?: string | null
          country?: string | null
          created_at?: string
          holder_name: string
          iban?: string | null
          id?: string
          is_active?: boolean
          is_default?: boolean
          method_type: string
          ownership_declared?: boolean
          ownership_declared_at?: string | null
          pix_key?: string | null
          pix_key_type?: string | null
          revtag?: string | null
          seller_id: string
          tax_id?: string | null
          updated_at?: string
        }
        Update: {
          bic_swift?: string | null
          country?: string | null
          created_at?: string
          holder_name?: string
          iban?: string | null
          id?: string
          is_active?: boolean
          is_default?: boolean
          method_type?: string
          ownership_declared?: boolean
          ownership_declared_at?: string | null
          pix_key?: string | null
          pix_key_type?: string | null
          revtag?: string | null
          seller_id?: string
          tax_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "withdrawal_methods_seller_id_fkey"
            columns: ["seller_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      withdrawals: {
        Row: {
          amount_eur: number
          confirmed_at: string | null
          created_at: string
          decided_by: string | null
          decision_reason: string | null
          destination_bic_swift_snapshot: string | null
          destination_country_snapshot: string | null
          destination_holder_name_snapshot: string | null
          destination_iban_snapshot: string | null
          destination_masked_snapshot: string | null
          destination_pix_key_snapshot: string | null
          destination_pix_key_type_snapshot: string | null
          destination_revtag_snapshot: string | null
          destination_tax_id_snapshot: string | null
          fixed_fee_snapshot_eur: number
          id: string
          method_type_snapshot: string | null
          net_amount_eur: number | null
          paid_amount_brl: number | null
          paid_at: string | null
          payment_proof_path: string | null
          payment_reference: string | null
          rules_updated_at_snapshot: string | null
          seller_id: string
          status: string
          updated_at: string
          withdrawal_method_id: string | null
        }
        Insert: {
          amount_eur: number
          confirmed_at?: string | null
          created_at?: string
          decided_by?: string | null
          decision_reason?: string | null
          destination_bic_swift_snapshot?: string | null
          destination_country_snapshot?: string | null
          destination_holder_name_snapshot?: string | null
          destination_iban_snapshot?: string | null
          destination_masked_snapshot?: string | null
          destination_pix_key_snapshot?: string | null
          destination_pix_key_type_snapshot?: string | null
          destination_revtag_snapshot?: string | null
          destination_tax_id_snapshot?: string | null
          fixed_fee_snapshot_eur: number
          id?: string
          method_type_snapshot?: string | null
          net_amount_eur?: number | null
          paid_amount_brl?: number | null
          paid_at?: string | null
          payment_proof_path?: string | null
          payment_reference?: string | null
          rules_updated_at_snapshot?: string | null
          seller_id: string
          status?: string
          updated_at?: string
          withdrawal_method_id?: string | null
        }
        Update: {
          amount_eur?: number
          confirmed_at?: string | null
          created_at?: string
          decided_by?: string | null
          decision_reason?: string | null
          destination_bic_swift_snapshot?: string | null
          destination_country_snapshot?: string | null
          destination_holder_name_snapshot?: string | null
          destination_iban_snapshot?: string | null
          destination_masked_snapshot?: string | null
          destination_pix_key_snapshot?: string | null
          destination_pix_key_type_snapshot?: string | null
          destination_revtag_snapshot?: string | null
          destination_tax_id_snapshot?: string | null
          fixed_fee_snapshot_eur?: number
          id?: string
          method_type_snapshot?: string | null
          net_amount_eur?: number | null
          paid_amount_brl?: number | null
          paid_at?: string | null
          payment_proof_path?: string | null
          payment_reference?: string | null
          rules_updated_at_snapshot?: string | null
          seller_id?: string
          status?: string
          updated_at?: string
          withdrawal_method_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "withdrawals_decided_by_fkey"
            columns: ["decided_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "withdrawals_seller_id_fkey"
            columns: ["seller_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "withdrawals_withdrawal_method_id_fkey"
            columns: ["withdrawal_method_id"]
            isOneToOne: false
            referencedRelation: "withdrawal_methods"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_add_payment_note: {
        Args: { p_note: string; p_payment_id: string }
        Returns: {
          admin_id: string
          created_at: string
          id: string
          note: string
          payment_id: string
        }
        SetofOptions: {
          from: "*"
          to: "payment_admin_notes"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      admin_approve_payment: {
        Args: {
          p_new_receipt_amount_eur?: number
          p_new_receipt_at?: string
          p_new_receipt_method?: string
          p_new_receipt_observation?: string
          p_new_receipt_reference?: string
          p_payment_id: string
          p_receipt_id?: string
        }
        Returns: {
          admin_notes: string | null
          approved_at: string | null
          central_iban_snapshot: string | null
          compensation_beneficiary_id: string | null
          compensation_percent_applied: number | null
          compensation_percent_configured: number | null
          compensation_rule_id: string | null
          created_at: string
          currency: string
          decided_by: string | null
          decision_reason: string | null
          fee_amount_eur: number
          fee_percent_snapshot: number
          gross_amount_eur: number
          id: string
          idempotency_key: string | null
          mbway_phone_snapshot: string | null
          net_amount_eur: number
          notes: string | null
          order_id: string | null
          payment_code: string
          payment_method: string | null
          proof_mime_type: string | null
          proof_path: string | null
          proof_size_bytes: number | null
          receipt_id: string | null
          reference: string | null
          risk_reason: string | null
          seller_id: string
          status: string
          submitted_at: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "payment_records"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      admin_create_central_receipt: {
        Args: {
          p_amount_eur: number
          p_method: string
          p_observation?: string
          p_received_at: string
          p_reference: string
        }
        Returns: {
          amount_eur: number
          created_at: string
          created_by: string
          id: string
          observation: string | null
          payment_id: string | null
          payment_method: string
          receipt_reference: string
          received_at: string
          seller_id: string | null
        }
        SetofOptions: {
          from: "*"
          to: "central_receipts"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      admin_escalate_payment: {
        Args: { p_payment_id: string; p_reason: string }
        Returns: {
          admin_notes: string | null
          approved_at: string | null
          central_iban_snapshot: string | null
          compensation_beneficiary_id: string | null
          compensation_percent_applied: number | null
          compensation_percent_configured: number | null
          compensation_rule_id: string | null
          created_at: string
          currency: string
          decided_by: string | null
          decision_reason: string | null
          fee_amount_eur: number
          fee_percent_snapshot: number
          gross_amount_eur: number
          id: string
          idempotency_key: string | null
          mbway_phone_snapshot: string | null
          net_amount_eur: number
          notes: string | null
          order_id: string | null
          payment_code: string
          payment_method: string | null
          proof_mime_type: string | null
          proof_path: string | null
          proof_size_bytes: number | null
          receipt_id: string | null
          reference: string | null
          risk_reason: string | null
          seller_id: string
          status: string
          submitted_at: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "payment_records"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      admin_financial_summary: {
        Args: { p_end?: string; p_seller_id?: string; p_start?: string }
        Returns: {
          active_sellers: number
          approved_gross_eur: number
          jaguapay_sales_fees_eur: number
          pending_payments_eur: number
          sellers_available_eur: number
          sellers_reserved_eur: number
          suspended_sellers: number
          under_review_payments_eur: number
          withdrawal_fees_paid_eur: number
          withdrawals_awaiting_action: number
          withdrawals_paid: number
        }[]
      }
      admin_mark_withdrawal_paid: {
        Args: {
          p_paid_amount_brl?: number
          p_payment_proof_path: string
          p_payment_reference: string
          p_withdrawal_id: string
        }
        Returns: {
          amount_eur: number
          confirmed_at: string | null
          created_at: string
          decided_by: string | null
          decision_reason: string | null
          destination_bic_swift_snapshot: string | null
          destination_country_snapshot: string | null
          destination_holder_name_snapshot: string | null
          destination_iban_snapshot: string | null
          destination_masked_snapshot: string | null
          destination_pix_key_snapshot: string | null
          destination_pix_key_type_snapshot: string | null
          destination_revtag_snapshot: string | null
          destination_tax_id_snapshot: string | null
          fixed_fee_snapshot_eur: number
          id: string
          method_type_snapshot: string | null
          net_amount_eur: number | null
          paid_amount_brl: number | null
          paid_at: string | null
          payment_proof_path: string | null
          payment_reference: string | null
          rules_updated_at_snapshot: string | null
          seller_id: string
          status: string
          updated_at: string
          withdrawal_method_id: string | null
        }
        SetofOptions: {
          from: "*"
          to: "withdrawals"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      admin_reject_payment: {
        Args: { p_payment_id: string; p_reason: string }
        Returns: {
          admin_notes: string | null
          approved_at: string | null
          central_iban_snapshot: string | null
          compensation_beneficiary_id: string | null
          compensation_percent_applied: number | null
          compensation_percent_configured: number | null
          compensation_rule_id: string | null
          created_at: string
          currency: string
          decided_by: string | null
          decision_reason: string | null
          fee_amount_eur: number
          fee_percent_snapshot: number
          gross_amount_eur: number
          id: string
          idempotency_key: string | null
          mbway_phone_snapshot: string | null
          net_amount_eur: number
          notes: string | null
          order_id: string | null
          payment_code: string
          payment_method: string | null
          proof_mime_type: string | null
          proof_path: string | null
          proof_size_bytes: number | null
          receipt_id: string | null
          reference: string | null
          risk_reason: string | null
          seller_id: string
          status: string
          submitted_at: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "payment_records"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      admin_reply_support: {
        Args: { p_message: string; p_status?: string; p_ticket_id: string }
        Returns: {
          author_id: string
          created_at: string
          id: string
          message: string
          ticket_id: string
        }
        SetofOptions: {
          from: "*"
          to: "support_messages"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      admin_reverse_payment: {
        Args: { p_payment_id: string; p_reason: string }
        Returns: {
          admin_notes: string | null
          approved_at: string | null
          central_iban_snapshot: string | null
          compensation_beneficiary_id: string | null
          compensation_percent_applied: number | null
          compensation_percent_configured: number | null
          compensation_rule_id: string | null
          created_at: string
          currency: string
          decided_by: string | null
          decision_reason: string | null
          fee_amount_eur: number
          fee_percent_snapshot: number
          gross_amount_eur: number
          id: string
          idempotency_key: string | null
          mbway_phone_snapshot: string | null
          net_amount_eur: number
          notes: string | null
          order_id: string | null
          payment_code: string
          payment_method: string | null
          proof_mime_type: string | null
          proof_path: string | null
          proof_size_bytes: number | null
          receipt_id: string | null
          reference: string | null
          risk_reason: string | null
          seller_id: string
          status: string
          submitted_at: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "payment_records"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      admin_set_withdrawal_status: {
        Args: { p_reason?: string; p_status: string; p_withdrawal_id: string }
        Returns: {
          amount_eur: number
          confirmed_at: string | null
          created_at: string
          decided_by: string | null
          decision_reason: string | null
          destination_bic_swift_snapshot: string | null
          destination_country_snapshot: string | null
          destination_holder_name_snapshot: string | null
          destination_iban_snapshot: string | null
          destination_masked_snapshot: string | null
          destination_pix_key_snapshot: string | null
          destination_pix_key_type_snapshot: string | null
          destination_revtag_snapshot: string | null
          destination_tax_id_snapshot: string | null
          fixed_fee_snapshot_eur: number
          id: string
          method_type_snapshot: string | null
          net_amount_eur: number | null
          paid_amount_brl: number | null
          paid_at: string | null
          payment_proof_path: string | null
          payment_reference: string | null
          rules_updated_at_snapshot: string | null
          seller_id: string
          status: string
          updated_at: string
          withdrawal_method_id: string | null
        }
        SetofOptions: {
          from: "*"
          to: "withdrawals"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      bootstrap_superadmin: { Args: { p_email: string }; Returns: undefined }
      cancel_own_withdrawal: {
        Args: { p_withdrawal_id: string }
        Returns: {
          amount_eur: number
          confirmed_at: string | null
          created_at: string
          decided_by: string | null
          decision_reason: string | null
          destination_bic_swift_snapshot: string | null
          destination_country_snapshot: string | null
          destination_holder_name_snapshot: string | null
          destination_iban_snapshot: string | null
          destination_masked_snapshot: string | null
          destination_pix_key_snapshot: string | null
          destination_pix_key_type_snapshot: string | null
          destination_revtag_snapshot: string | null
          destination_tax_id_snapshot: string | null
          fixed_fee_snapshot_eur: number
          id: string
          method_type_snapshot: string | null
          net_amount_eur: number | null
          paid_amount_brl: number | null
          paid_at: string | null
          payment_proof_path: string | null
          payment_reference: string | null
          rules_updated_at_snapshot: string | null
          seller_id: string
          status: string
          updated_at: string
          withdrawal_method_id: string | null
        }
        SetofOptions: {
          from: "*"
          to: "withdrawals"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      cleanup_failed_payment_submission: {
        Args: { p_payment_id: string }
        Returns: boolean
      }
      create_compensation_settlement: {
        Args: {
          p_amount_eur: number
          p_beneficiary_id: string
          p_observation: string
          p_proof_path: string
          p_reference: string
          p_settlement_date: string
          p_settlement_method: string
        }
        Returns: {
          amount_eur: number
          beneficiary_id: string
          created_at: string
          created_by: string
          id: string
          observation: string | null
          proof_path: string | null
          reference: string | null
          settlement_date: string
          settlement_method: string
        }
        SetofOptions: {
          from: "*"
          to: "compensation_settlements"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      create_payment_submission: {
        Args: {
          p_gross_amount_eur: number
          p_idempotency_key: string
          p_notes: string
          p_order_id: string
          p_payment_method: string
          p_reference: string
        }
        Returns: {
          admin_notes: string | null
          approved_at: string | null
          central_iban_snapshot: string | null
          compensation_beneficiary_id: string | null
          compensation_percent_applied: number | null
          compensation_percent_configured: number | null
          compensation_rule_id: string | null
          created_at: string
          currency: string
          decided_by: string | null
          decision_reason: string | null
          fee_amount_eur: number
          fee_percent_snapshot: number
          gross_amount_eur: number
          id: string
          idempotency_key: string | null
          mbway_phone_snapshot: string | null
          net_amount_eur: number
          notes: string | null
          order_id: string | null
          payment_code: string
          payment_method: string | null
          proof_mime_type: string | null
          proof_path: string | null
          proof_size_bytes: number | null
          receipt_id: string | null
          reference: string | null
          risk_reason: string | null
          seller_id: string
          status: string
          submitted_at: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "payment_records"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      create_support_ticket: {
        Args: { p_message: string; p_subject: string }
        Returns: {
          created_at: string
          id: string
          message: string
          resolved_at: string | null
          seller_id: string
          status: string
          subject: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "support_tickets"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      create_withdrawal_method: {
        Args: {
          p_bic_swift?: string
          p_country?: string
          p_holder_name: string
          p_iban?: string
          p_method_type: string
          p_ownership_declared?: boolean
          p_pix_key?: string
          p_pix_key_type?: string
          p_revtag?: string
          p_tax_id: string
        }
        Returns: {
          bic_swift: string | null
          country: string | null
          created_at: string
          holder_name: string
          iban: string | null
          id: string
          is_active: boolean
          is_default: boolean
          method_type: string
          ownership_declared: boolean
          ownership_declared_at: string | null
          pix_key: string | null
          pix_key_type: string | null
          revtag: string | null
          seller_id: string
          tax_id: string | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "withdrawal_methods"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      deactivate_counter_compensation: {
        Args: { p_reason: string }
        Returns: {
          activated_at: string | null
          active: boolean
          beneficiary_id: string
          configured_percent: number
          created_at: string
          created_by: string
          deactivated_at: string | null
          id: string
          platform_fee_percent_at_activation: number
          updated_at: string
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "compensation_rules"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      deactivate_withdrawal_method: {
        Args: { p_method_id: string }
        Returns: {
          bic_swift: string | null
          country: string | null
          created_at: string
          holder_name: string
          iban: string | null
          id: string
          is_active: boolean
          is_default: boolean
          method_type: string
          ownership_declared: boolean
          ownership_declared_at: string | null
          pix_key: string | null
          pix_key_type: string | null
          revtag: string | null
          seller_id: string
          tax_id: string | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "withdrawal_methods"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      emit_notification: {
        Args: {
          p_dedupe_key: string
          p_message: string
          p_recipient: string
          p_related_id: string
          p_related_type: string
          p_title: string
          p_type: string
        }
        Returns: undefined
      }
      finalize_payment_submission: {
        Args: {
          p_payment_id: string
          p_proof_mime_type: string
          p_proof_path: string
          p_proof_size_bytes: number
        }
        Returns: {
          admin_notes: string | null
          approved_at: string | null
          central_iban_snapshot: string | null
          compensation_beneficiary_id: string | null
          compensation_percent_applied: number | null
          compensation_percent_configured: number | null
          compensation_rule_id: string | null
          created_at: string
          currency: string
          decided_by: string | null
          decision_reason: string | null
          fee_amount_eur: number
          fee_percent_snapshot: number
          gross_amount_eur: number
          id: string
          idempotency_key: string | null
          mbway_phone_snapshot: string | null
          net_amount_eur: number
          notes: string | null
          order_id: string | null
          payment_code: string
          payment_method: string | null
          proof_mime_type: string | null
          proof_path: string | null
          proof_size_bytes: number | null
          receipt_id: string | null
          reference: string | null
          risk_reason: string | null
          seller_id: string
          status: string
          submitted_at: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "payment_records"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      get_compensation_admin_summary: {
        Args: never
        Returns: {
          beneficiary_id: string
          pending_eur: number
          total_accrued_eur: number
          total_adjustments_eur: number
          total_paid_eur: number
        }[]
      }
      get_compensation_balances: {
        Args: never
        Returns: {
          beneficiary_id: string
          pending_eur: number
          total_accrued_eur: number
          total_adjustments_eur: number
          total_paid_eur: number
        }[]
      }
      get_my_compensation_summary: {
        Args: never
        Returns: {
          active: boolean
          configured_percent: number
          pending_eur: number
          total_accrued_eur: number
          total_adjustments_eur: number
          total_paid_eur: number
        }[]
      }
      get_my_counter_overview: {
        Args: never
        Returns: {
          jaguapay_fees_eur: number
          jaguapay_gross_eur: number
          percent: number
          platform_fee_percent: number
          total_accrued_eur: number
        }[]
      }
      get_seller_dashboard:
        | {
            Args: never
            Returns: {
              approved_volume_eur: number
              at_risk_eur: number
              available_balance_eur: number
              pending_balance_eur: number
              reserved_withdrawals_eur: number
            }[]
          }
        | {
            Args: { p_end?: string; p_start?: string }
            Returns: {
              approved_volume_eur: number
              at_risk_eur: number
              available_balance_eur: number
              pending_balance_eur: number
              reserved_withdrawals_eur: number
            }[]
          }
      grant_counter: {
        Args: { p_reason: string; p_user_id: string }
        Returns: {
          accepted_terms_at: string | null
          admin_level: string
          counter_previous_role: string | null
          created_at: string | null
          email: string
          full_name: string
          id: string
          role: Database["public"]["Enums"]["user_role"]
          status: Database["public"]["Enums"]["user_status"]
          suspended_at: string | null
          suspension_reason: string | null
          updated_at: string | null
        }
        SetofOptions: {
          from: "*"
          to: "profiles"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      invite_admin_record: { Args: { p_email: string }; Returns: string }
      invite_counter_record: {
        Args: { p_email: string; p_full_name: string }
        Returns: string
      }
      is_admin: { Args: never; Returns: boolean }
      is_admin_or_counter: { Args: never; Returns: boolean }
      is_superadmin: { Args: never; Returns: boolean }
      mark_notification_read: {
        Args: { p_notification_id: string }
        Returns: {
          created_at: string
          dedupe_key: string
          id: string
          message: string
          read_at: string | null
          recipient_id: string
          related_id: string | null
          related_type: string | null
          title: string
          type: string
        }
        SetofOptions: {
          from: "*"
          to: "notifications"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      reactivate_counter: {
        Args: { p_reason: string; p_user_id: string }
        Returns: undefined
      }
      reactivate_seller: {
        Args: { p_reason: string; p_user_id: string }
        Returns: undefined
      }
      remove_counter: {
        Args: { p_reason: string; p_user_id: string }
        Returns: undefined
      }
      request_withdrawal: {
        Args: {
          p_amount_eur: number
          p_rules_updated_at: string
          p_withdrawal_method_id: string
        }
        Returns: {
          amount_eur: number
          confirmed_at: string | null
          created_at: string
          decided_by: string | null
          decision_reason: string | null
          destination_bic_swift_snapshot: string | null
          destination_country_snapshot: string | null
          destination_holder_name_snapshot: string | null
          destination_iban_snapshot: string | null
          destination_masked_snapshot: string | null
          destination_pix_key_snapshot: string | null
          destination_pix_key_type_snapshot: string | null
          destination_revtag_snapshot: string | null
          destination_tax_id_snapshot: string | null
          fixed_fee_snapshot_eur: number
          id: string
          method_type_snapshot: string | null
          net_amount_eur: number | null
          paid_amount_brl: number | null
          paid_at: string | null
          payment_proof_path: string | null
          payment_reference: string | null
          rules_updated_at_snapshot: string | null
          seller_id: string
          status: string
          updated_at: string
          withdrawal_method_id: string | null
        }
        SetofOptions: {
          from: "*"
          to: "withdrawals"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      revoke_admin: {
        Args: { p_reason: string; p_user_id: string }
        Returns: undefined
      }
      revoke_counter_invitation: {
        Args: { p_invitation_id: string; p_reason: string }
        Returns: undefined
      }
      save_compensation_rule: {
        Args: {
          p_active: boolean
          p_beneficiary_id: string
          p_configured_percent: number
          p_reason: string
        }
        Returns: {
          activated_at: string | null
          active: boolean
          beneficiary_id: string
          configured_percent: number
          created_at: string
          created_by: string
          deactivated_at: string | null
          id: string
          platform_fee_percent_at_activation: number
          updated_at: string
          version: number
        }
        SetofOptions: {
          from: "*"
          to: "compensation_rules"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      save_platform_settings: {
        Args: {
          p_central_iban: string
          p_mbway_phone: string
          p_minimum_withdrawal_eur: number
          p_platform_fee_percent: number
          p_withdrawal_fixed_fee_eur: number
          p_withdrawals_paused: boolean
        }
        Returns: {
          central_iban: string | null
          id: number
          initialized_at: string | null
          mbway_phone: string | null
          minimum_withdrawal_eur: number
          platform_fee_percent: number
          updated_at: string
          updated_by: string | null
          withdrawal_fixed_fee_eur: number
          withdrawals_paused: boolean
        }
        SetofOptions: {
          from: "*"
          to: "platform_settings"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      set_counter_commission: {
        Args: { p_counter_id: string; p_percent: number }
        Returns: {
          counter_id: string
          percent: number
          updated_at: string
          updated_by: string | null
        }
        SetofOptions: {
          from: "*"
          to: "counter_commissions"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      set_default_withdrawal_method: {
        Args: { p_method_id: string }
        Returns: {
          bic_swift: string | null
          country: string | null
          created_at: string
          holder_name: string
          iban: string | null
          id: string
          is_active: boolean
          is_default: boolean
          method_type: string
          ownership_declared: boolean
          ownership_declared_at: string | null
          pix_key: string | null
          pix_key_type: string | null
          revtag: string | null
          seller_id: string
          tax_id: string | null
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "withdrawal_methods"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      submit_payment: {
        Args: { p_gross_amount_eur: number; p_reference?: string }
        Returns: {
          admin_notes: string | null
          approved_at: string | null
          central_iban_snapshot: string | null
          compensation_beneficiary_id: string | null
          compensation_percent_applied: number | null
          compensation_percent_configured: number | null
          compensation_rule_id: string | null
          created_at: string
          currency: string
          decided_by: string | null
          decision_reason: string | null
          fee_amount_eur: number
          fee_percent_snapshot: number
          gross_amount_eur: number
          id: string
          idempotency_key: string | null
          mbway_phone_snapshot: string | null
          net_amount_eur: number
          notes: string | null
          order_id: string | null
          payment_code: string
          payment_method: string | null
          proof_mime_type: string | null
          proof_path: string | null
          proof_size_bytes: number | null
          receipt_id: string | null
          reference: string | null
          risk_reason: string | null
          seller_id: string
          status: string
          submitted_at: string
          updated_at: string
        }
        SetofOptions: {
          from: "*"
          to: "payment_records"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      suspend_counter: {
        Args: { p_reason: string; p_user_id: string }
        Returns: undefined
      }
      suspend_seller: {
        Args: { p_reason: string; p_user_id: string }
        Returns: undefined
      }
      update_my_profile: {
        Args: { p_full_name: string }
        Returns: {
          accepted_terms_at: string | null
          admin_level: string
          counter_previous_role: string | null
          created_at: string | null
          email: string
          full_name: string
          id: string
          role: Database["public"]["Enums"]["user_role"]
          status: Database["public"]["Enums"]["user_status"]
          suspended_at: string | null
          suspension_reason: string | null
          updated_at: string | null
        }
        SetofOptions: {
          from: "*"
          to: "profiles"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      validate_withdrawal_method_input: {
        Args: {
          p_bic_swift: string
          p_country: string
          p_holder_name: string
          p_iban: string
          p_method_type: string
          p_pix_key: string
          p_pix_key_type: string
          p_revtag: string
          p_tax_id: string
        }
        Returns: undefined
      }
      withdrawal_mask_destination: {
        Args: {
          p_bic_swift: string
          p_country: string
          p_iban: string
          p_method_type: string
          p_pix_key: string
          p_pix_key_type: string
          p_revtag: string
        }
        Returns: string
      }
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
