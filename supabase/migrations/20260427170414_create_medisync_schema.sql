/*
  # MediSync ERP - Full Database Schema

  ## Tables Created
  1. `profiles` - Extended user profile (role, specialty, etc.)
  2. `departments` - Hospital departments
  3. `patient_profiles` - Patient medical details
  4. `appointments` - Scheduling with priority and status
  5. `appointment_status_history` - Audit trail
  6. `prescriptions` - Medication prescriptions with JSONB metadata
  7. `billing_invoices` - Invoice management
  8. `invoice_items` - Line items
  9. `real_time_vitals` - Vital signs storage
  10. `medications` - Medication catalog

  ## Security
  - RLS enabled on every table
  - Policies scoped by auth.uid() and role
*/

-- Profiles first (no FK deps except auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL DEFAULT '',
  email text NOT NULL DEFAULT '',
  role text NOT NULL DEFAULT 'PATIENT' CHECK (role IN ('SUPER_ADMIN', 'DOCTOR', 'NURSE', 'PATIENT')),
  avatar_url text DEFAULT '',
  phone text DEFAULT '',
  specialty text DEFAULT '',
  license_number text DEFAULT '',
  date_of_birth date,
  gender text DEFAULT '' CHECK (gender IN ('', 'male', 'female', 'other')),
  address text DEFAULT '',
  department_id uuid,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Medical staff can view all profiles"
  ON profiles FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('SUPER_ADMIN','DOCTOR','NURSE'))
  );

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Super admins can update any profile"
  ON profiles FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'SUPER_ADMIN'))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'SUPER_ADMIN'));

-- Departments
CREATE TABLE IF NOT EXISTS departments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text DEFAULT '',
  head_doctor_id uuid REFERENCES profiles(id),
  color text DEFAULT '#3b82f6',
  icon text DEFAULT 'stethoscope',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE departments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Departments viewable by authenticated"
  ON departments FOR SELECT TO authenticated USING (true);

CREATE POLICY "Super admins can insert departments"
  ON departments FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'SUPER_ADMIN'));

CREATE POLICY "Super admins can update departments"
  ON departments FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'SUPER_ADMIN'))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'SUPER_ADMIN'));

-- Add FK from profiles to departments now that departments exists
ALTER TABLE profiles ADD CONSTRAINT fk_profiles_department FOREIGN KEY (department_id) REFERENCES departments(id);

-- Patient Profiles
CREATE TABLE IF NOT EXISTS patient_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  blood_type text DEFAULT '' CHECK (blood_type IN ('','A+','A-','B+','B-','AB+','AB-','O+','O-')),
  allergies text[] DEFAULT '{}',
  chronic_conditions text[] DEFAULT '{}',
  emergency_contact_name text DEFAULT '',
  emergency_contact_phone text DEFAULT '',
  emergency_contact_relation text DEFAULT '',
  insurance_provider text DEFAULT '',
  insurance_policy_number text DEFAULT '',
  insurance_group_number text DEFAULT '',
  primary_doctor_id uuid REFERENCES profiles(id),
  notes text DEFAULT '',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id)
);

ALTER TABLE patient_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patients can view own patient profile"
  ON patient_profiles FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Medical staff can view patient profiles"
  ON patient_profiles FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('SUPER_ADMIN','DOCTOR','NURSE')));

CREATE POLICY "Patients can insert own patient profile"
  ON patient_profiles FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Patients can update own patient profile"
  ON patient_profiles FOR UPDATE TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "Medical staff can update patient profiles"
  ON patient_profiles FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('SUPER_ADMIN','DOCTOR','NURSE')))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('SUPER_ADMIN','DOCTOR','NURSE')));

-- Appointments
CREATE TABLE IF NOT EXISTS appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES profiles(id),
  doctor_id uuid NOT NULL REFERENCES profiles(id),
  department_id uuid REFERENCES departments(id),
  appointment_date timestamptz NOT NULL,
  duration_minutes integer DEFAULT 30,
  status text NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled','confirmed','in_progress','completed','cancelled','no_show')),
  priority text NOT NULL DEFAULT 'medium' CHECK (priority IN ('low','medium','high','critical')),
  appointment_type text NOT NULL DEFAULT 'consultation' CHECK (appointment_type IN ('consultation','follow_up','emergency','procedure','lab','imaging')),
  chief_complaint text DEFAULT '',
  notes text DEFAULT '',
  room_number text DEFAULT '',
  created_by uuid REFERENCES profiles(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patients can view own appointments"
  ON appointments FOR SELECT TO authenticated
  USING (patient_id = auth.uid());

CREATE POLICY "Doctors can view their appointments"
  ON appointments FOR SELECT TO authenticated
  USING (doctor_id = auth.uid());

CREATE POLICY "Staff can view all appointments"
  ON appointments FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('SUPER_ADMIN','NURSE')));

CREATE POLICY "Authenticated users can insert appointments"
  ON appointments FOR INSERT TO authenticated
  WITH CHECK (
    patient_id = auth.uid() OR
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('SUPER_ADMIN','DOCTOR','NURSE'))
  );

CREATE POLICY "Staff can update appointments"
  ON appointments FOR UPDATE TO authenticated
  USING (
    doctor_id = auth.uid() OR patient_id = auth.uid() OR
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('SUPER_ADMIN','NURSE'))
  )
  WITH CHECK (
    doctor_id = auth.uid() OR patient_id = auth.uid() OR
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('SUPER_ADMIN','NURSE'))
  );

-- Appointment Status History
CREATE TABLE IF NOT EXISTS appointment_status_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id uuid NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
  old_status text DEFAULT '',
  new_status text NOT NULL,
  changed_by uuid REFERENCES profiles(id),
  reason text DEFAULT '',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE appointment_status_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view status history of own appointments"
  ON appointment_status_history FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM appointments a
      WHERE a.id = appointment_id AND (a.patient_id = auth.uid() OR a.doctor_id = auth.uid())
    ) OR
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('SUPER_ADMIN','NURSE'))
  );

CREATE POLICY "Staff can insert status history"
  ON appointment_status_history FOR INSERT TO authenticated
  WITH CHECK (changed_by = auth.uid());

-- Prescriptions
CREATE TABLE IF NOT EXISTS prescriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES profiles(id),
  doctor_id uuid NOT NULL REFERENCES profiles(id),
  appointment_id uuid REFERENCES appointments(id),
  medication_name text NOT NULL,
  dosage_metadata jsonb NOT NULL DEFAULT '{}',
  instructions text DEFAULT '',
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','completed','cancelled','on_hold')),
  start_date date NOT NULL DEFAULT CURRENT_DATE,
  end_date date,
  refills_remaining integer DEFAULT 0,
  pharmacy_notes text DEFAULT '',
  interaction_warnings text[] DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patients can view own prescriptions"
  ON prescriptions FOR SELECT TO authenticated
  USING (patient_id = auth.uid());

CREATE POLICY "Doctors can view their prescriptions"
  ON prescriptions FOR SELECT TO authenticated
  USING (doctor_id = auth.uid());

CREATE POLICY "Staff can view all prescriptions"
  ON prescriptions FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('SUPER_ADMIN','NURSE')));

CREATE POLICY "Doctors can create prescriptions"
  ON prescriptions FOR INSERT TO authenticated
  WITH CHECK (
    doctor_id = auth.uid() AND
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('DOCTOR','SUPER_ADMIN'))
  );

CREATE POLICY "Doctors can update their prescriptions"
  ON prescriptions FOR UPDATE TO authenticated
  USING (
    doctor_id = auth.uid() OR
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'SUPER_ADMIN')
  )
  WITH CHECK (
    doctor_id = auth.uid() OR
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'SUPER_ADMIN')
  );

-- Billing Invoices
CREATE TABLE IF NOT EXISTS billing_invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number text UNIQUE NOT NULL,
  patient_id uuid NOT NULL REFERENCES profiles(id),
  appointment_id uuid REFERENCES appointments(id),
  subtotal numeric(10,2) NOT NULL DEFAULT 0,
  tax_amount numeric(10,2) NOT NULL DEFAULT 0,
  insurance_coverage numeric(10,2) NOT NULL DEFAULT 0,
  discount_amount numeric(10,2) NOT NULL DEFAULT 0,
  total_amount numeric(10,2) NOT NULL DEFAULT 0,
  amount_paid numeric(10,2) NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','sent','paid','overdue','cancelled','partially_paid')),
  due_date date,
  paid_at timestamptz,
  payment_method text DEFAULT '',
  insurance_claim_number text DEFAULT '',
  notes text DEFAULT '',
  created_by uuid REFERENCES profiles(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE billing_invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patients can view own invoices"
  ON billing_invoices FOR SELECT TO authenticated
  USING (patient_id = auth.uid());

CREATE POLICY "Staff can view all invoices"
  ON billing_invoices FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('SUPER_ADMIN','DOCTOR','NURSE')));

CREATE POLICY "Staff can create invoices"
  ON billing_invoices FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('SUPER_ADMIN','DOCTOR','NURSE')));

CREATE POLICY "Staff can update invoices"
  ON billing_invoices FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('SUPER_ADMIN','DOCTOR','NURSE')))
  WITH CHECK (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('SUPER_ADMIN','DOCTOR','NURSE')));

-- Invoice Items
CREATE TABLE IF NOT EXISTS invoice_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id uuid NOT NULL REFERENCES billing_invoices(id) ON DELETE CASCADE,
  description text NOT NULL,
  quantity integer NOT NULL DEFAULT 1,
  unit_price numeric(10,2) NOT NULL DEFAULT 0,
  total_price numeric(10,2) NOT NULL DEFAULT 0,
  item_type text DEFAULT 'service' CHECK (item_type IN ('consultation','procedure','medication','lab','imaging','service','other')),
  created_at timestamptz DEFAULT now()
);

ALTER TABLE invoice_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view invoice items for their invoices"
  ON invoice_items FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM billing_invoices bi
      WHERE bi.id = invoice_id AND (
        bi.patient_id = auth.uid() OR
        EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('SUPER_ADMIN','DOCTOR','NURSE'))
      )
    )
  );

CREATE POLICY "Staff can insert invoice items"
  ON invoice_items FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('SUPER_ADMIN','DOCTOR','NURSE')));

-- Real-time Vitals
CREATE TABLE IF NOT EXISTS real_time_vitals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES profiles(id),
  appointment_id uuid REFERENCES appointments(id),
  recorded_by uuid REFERENCES profiles(id),
  heart_rate integer,
  spo2 numeric(5,2),
  systolic_bp integer,
  diastolic_bp integer,
  temperature numeric(4,1),
  respiratory_rate integer,
  weight_kg numeric(5,2),
  height_cm numeric(5,1),
  notes text DEFAULT '',
  recorded_at timestamptz DEFAULT now()
);

ALTER TABLE real_time_vitals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patients can view own vitals"
  ON real_time_vitals FOR SELECT TO authenticated
  USING (patient_id = auth.uid());

CREATE POLICY "Medical staff can view all vitals"
  ON real_time_vitals FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('SUPER_ADMIN','DOCTOR','NURSE')));

CREATE POLICY "Medical staff can insert vitals"
  ON real_time_vitals FOR INSERT TO authenticated
  WITH CHECK (
    recorded_by = auth.uid() AND
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('SUPER_ADMIN','DOCTOR','NURSE'))
  );

-- Medications catalog
CREATE TABLE IF NOT EXISTS medications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  generic_name text DEFAULT '',
  drug_class text DEFAULT '',
  common_dosages text[] DEFAULT '{}',
  common_interactions text[] DEFAULT '{}',
  requires_prescription boolean DEFAULT true,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE medications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view medications"
  ON medications FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admins can manage medications"
  ON medications FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role = 'SUPER_ADMIN'));

-- Indexes
CREATE INDEX IF NOT EXISTS idx_appointments_patient_id ON appointments(patient_id);
CREATE INDEX IF NOT EXISTS idx_appointments_doctor_id ON appointments(doctor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);
CREATE INDEX IF NOT EXISTS idx_prescriptions_patient_id ON prescriptions(patient_id);
CREATE INDEX IF NOT EXISTS idx_vitals_patient_id ON real_time_vitals(patient_id);
CREATE INDEX IF NOT EXISTS idx_vitals_recorded_at ON real_time_vitals(recorded_at);
CREATE INDEX IF NOT EXISTS idx_billing_patient_id ON billing_invoices(patient_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_profiles_updated_at') THEN
    CREATE TRIGGER set_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_appointments_updated_at') THEN
    CREATE TRIGGER set_appointments_updated_at BEFORE UPDATE ON appointments FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_prescriptions_updated_at') THEN
    CREATE TRIGGER set_prescriptions_updated_at BEFORE UPDATE ON prescriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_billing_updated_at') THEN
    CREATE TRIGGER set_billing_updated_at BEFORE UPDATE ON billing_invoices FOR EACH ROW EXECUTE FUNCTION update_updated_at();
  END IF;
END $$;
