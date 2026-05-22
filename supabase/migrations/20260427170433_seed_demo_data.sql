/*
  # Seed Demo Data

  Inserts departments and medications catalog for demo purposes.
  No user-specific data seeded here (users created via auth).
*/

INSERT INTO departments (id, name, description, color, icon) VALUES
  ('d1000000-0000-0000-0000-000000000001', 'Emergency Room', 'Critical and urgent care unit', '#ef4444', 'zap'),
  ('d1000000-0000-0000-0000-000000000002', 'Cardiology', 'Heart and cardiovascular diseases', '#3b82f6', 'heart'),
  ('d1000000-0000-0000-0000-000000000003', 'Neurology', 'Brain and nervous system disorders', '#8b5cf6', 'brain'),
  ('d1000000-0000-0000-0000-000000000004', 'Oncology', 'Cancer diagnosis and treatment', '#f59e0b', 'shield'),
  ('d1000000-0000-0000-0000-000000000005', 'Pediatrics', 'Medical care for children', '#10b981', 'baby'),
  ('d1000000-0000-0000-0000-000000000006', 'Orthopedics', 'Bone, joint and muscle care', '#06b6d4', 'bone'),
  ('d1000000-0000-0000-0000-000000000007', 'Radiology', 'Medical imaging and diagnostics', '#6366f1', 'scan'),
  ('d1000000-0000-0000-0000-000000000008', 'Surgery', 'Surgical procedures and post-op care', '#f97316', 'scissors')
ON CONFLICT (id) DO NOTHING;

INSERT INTO medications (name, generic_name, drug_class, common_dosages, common_interactions) VALUES
  ('Aspirin', 'Acetylsalicylic Acid', 'NSAID', ARRAY['81mg', '325mg', '500mg'], ARRAY['Warfarin', 'Ibuprofen', 'Naproxen']),
  ('Lisinopril', 'Lisinopril', 'ACE Inhibitor', ARRAY['5mg', '10mg', '20mg', '40mg'], ARRAY['Potassium supplements', 'NSAIDs', 'Aliskiren']),
  ('Metformin', 'Metformin HCl', 'Biguanide', ARRAY['500mg', '850mg', '1000mg'], ARRAY['Alcohol', 'Contrast dye', 'Carbonic anhydrase inhibitors']),
  ('Atorvastatin', 'Atorvastatin Calcium', 'Statin', ARRAY['10mg', '20mg', '40mg', '80mg'], ARRAY['Clarithromycin', 'Erythromycin', 'Grapefruit juice']),
  ('Amoxicillin', 'Amoxicillin', 'Penicillin antibiotic', ARRAY['250mg', '500mg', '875mg'], ARRAY['Warfarin', 'Methotrexate', 'Oral contraceptives']),
  ('Omeprazole', 'Omeprazole', 'Proton Pump Inhibitor', ARRAY['10mg', '20mg', '40mg'], ARRAY['Clopidogrel', 'Methotrexate', 'Ketoconazole']),
  ('Ibuprofen', 'Ibuprofen', 'NSAID', ARRAY['200mg', '400mg', '600mg', '800mg'], ARRAY['Aspirin', 'Warfarin', 'ACE inhibitors']),
  ('Metoprolol', 'Metoprolol Tartrate', 'Beta Blocker', ARRAY['25mg', '50mg', '100mg', '200mg'], ARRAY['Verapamil', 'Diltiazem', 'Clonidine']),
  ('Levothyroxine', 'Levothyroxine Sodium', 'Thyroid hormone', ARRAY['25mcg', '50mcg', '75mcg', '100mcg'], ARRAY['Calcium', 'Iron', 'Antacids']),
  ('Sertraline', 'Sertraline HCl', 'SSRI', ARRAY['25mg', '50mg', '100mg'], ARRAY['MAOIs', 'Tramadol', 'Linezolid']),
  ('Amlodipine', 'Amlodipine Besylate', 'Calcium Channel Blocker', ARRAY['2.5mg', '5mg', '10mg'], ARRAY['Simvastatin', 'Cyclosporine', 'Tacrolimus']),
  ('Prednisone', 'Prednisone', 'Corticosteroid', ARRAY['5mg', '10mg', '20mg', '50mg'], ARRAY['NSAIDs', 'Warfarin', 'Vaccines']),
  ('Azithromycin', 'Azithromycin', 'Macrolide antibiotic', ARRAY['250mg', '500mg'], ARRAY['Antacids', 'Warfarin', 'Digoxin']),
  ('Furosemide', 'Furosemide', 'Loop Diuretic', ARRAY['20mg', '40mg', '80mg'], ARRAY['Aminoglycosides', 'Digoxin', 'Lithium']),
  ('Warfarin', 'Warfarin Sodium', 'Anticoagulant', ARRAY['1mg', '2mg', '2.5mg', '5mg', '7.5mg', '10mg'], ARRAY['Aspirin', 'NSAIDs', 'Antibiotics', 'Vitamin K'])
ON CONFLICT DO NOTHING;
