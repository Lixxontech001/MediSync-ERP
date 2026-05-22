export type UserRole = 'SUPER_ADMIN' | 'DOCTOR' | 'NURSE' | 'PATIENT'

export interface Profile {
  id: string
  full_name: string
  email: string
  role: UserRole
  avatar_url: string
  phone: string
  specialty: string
  license_number: string
  date_of_birth: string | null
  gender: string
  address: string
  department_id: string | null
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface Department {
  id: string
  name: string
  description: string
  head_doctor_id: string | null
  color: string
  icon: string
  created_at: string
}

export interface PatientProfile {
  id: string
  user_id: string
  blood_type: string
  allergies: string[]
  chronic_conditions: string[]
  emergency_contact_name: string
  emergency_contact_phone: string
  emergency_contact_relation: string
  insurance_provider: string
  insurance_policy_number: string
  insurance_group_number: string
  primary_doctor_id: string | null
  notes: string
  created_at: string
  updated_at: string
}

export interface Appointment {
  id: string
  patient_id: string
  doctor_id: string
  department_id: string | null
  appointment_date: string
  duration_minutes: number
  status: 'scheduled' | 'confirmed' | 'in_progress' | 'completed' | 'cancelled' | 'no_show'
  priority: 'low' | 'medium' | 'high' | 'critical'
  appointment_type: 'consultation' | 'follow_up' | 'emergency' | 'procedure' | 'lab' | 'imaging'
  chief_complaint: string
  notes: string
  room_number: string
  created_by: string | null
  created_at: string
  updated_at: string
  patient?: Profile
  doctor?: Profile
  department?: Department
}

export interface AppointmentStatusHistory {
  id: string
  appointment_id: string
  old_status: string
  new_status: string
  changed_by: string | null
  reason: string
  created_at: string
}

export interface Prescription {
  id: string
  patient_id: string
  doctor_id: string
  appointment_id: string | null
  medication_name: string
  dosage_metadata: {
    dosage?: string
    frequency?: string
    route?: string
    form?: string
  }
  instructions: string
  status: 'active' | 'completed' | 'cancelled' | 'on_hold'
  start_date: string
  end_date: string | null
  refills_remaining: number
  pharmacy_notes: string
  interaction_warnings: string[]
  created_at: string
  updated_at: string
  patient?: Profile
  doctor?: Profile
}

export interface BillingInvoice {
  id: string
  invoice_number: string
  patient_id: string
  appointment_id: string | null
  subtotal: number
  tax_amount: number
  insurance_coverage: number
  discount_amount: number
  total_amount: number
  amount_paid: number
  status: 'draft' | 'sent' | 'paid' | 'overdue' | 'cancelled' | 'partially_paid'
  due_date: string | null
  paid_at: string | null
  payment_method: string
  insurance_claim_number: string
  notes: string
  created_by: string | null
  created_at: string
  updated_at: string
  patient?: Profile
  items?: InvoiceItem[]
}

export interface InvoiceItem {
  id: string
  invoice_id: string
  description: string
  quantity: number
  unit_price: number
  total_price: number
  item_type: string
  created_at: string
}

export interface RealTimeVital {
  id: string
  patient_id: string
  appointment_id: string | null
  recorded_by: string | null
  heart_rate: number | null
  spo2: number | null
  systolic_bp: number | null
  diastolic_bp: number | null
  temperature: number | null
  respiratory_rate: number | null
  weight_kg: number | null
  height_cm: number | null
  notes: string
  recorded_at: string
}

export interface Medication {
  id: string
  name: string
  generic_name: string
  drug_class: string
  common_dosages: string[]
  common_interactions: string[]
  requires_prescription: boolean
  is_active: boolean
  created_at: string
}

export type Database = {
  public: {
    Tables: {
      profiles: { Row: Profile; Insert: Partial<Profile>; Update: Partial<Profile> }
      departments: { Row: Department; Insert: Partial<Department>; Update: Partial<Department> }
      patient_profiles: { Row: PatientProfile; Insert: Partial<PatientProfile>; Update: Partial<PatientProfile> }
      appointments: { Row: Appointment; Insert: Partial<Appointment>; Update: Partial<Appointment> }
      appointment_status_history: { Row: AppointmentStatusHistory; Insert: Partial<AppointmentStatusHistory>; Update: Partial<AppointmentStatusHistory> }
      prescriptions: { Row: Prescription; Insert: Partial<Prescription>; Update: Partial<Prescription> }
      billing_invoices: { Row: BillingInvoice; Insert: Partial<BillingInvoice>; Update: Partial<BillingInvoice> }
      invoice_items: { Row: InvoiceItem; Insert: Partial<InvoiceItem>; Update: Partial<InvoiceItem> }
      real_time_vitals: { Row: RealTimeVital; Insert: Partial<RealTimeVital>; Update: Partial<RealTimeVital> }
      medications: { Row: Medication; Insert: Partial<Medication>; Update: Partial<Medication> }
    }
  }
}
