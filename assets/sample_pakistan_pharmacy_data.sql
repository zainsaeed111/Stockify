-- Sample Pakistani Pharmacy Products
-- Common Medicines with Real Prices (in PKR)

-- Pain Relief & Fever
INSERT INTO medicines (code, name, generic_name, main_category, sub_category, pack_size, manufacturer) VALUES
('PANA001', 'Panadol 500mg', 'Paracetamol', 'Analgesics', 'Pain Relief', '20 Tablets', 'GSK'),
('PANA002', 'Panadol Extra', 'Paracetamol + Caffeine', 'Analgesics', 'Pain Relief', '24 Tablets', 'GSK'),
('DISP001', 'Disprin 300mg', 'Aspirin', 'Analgesics', 'Pain Relief', '12 Tablets', 'Reckitt Benckiser'),
('PONT001', 'Ponstan Forte 500mg', 'Mefenamic Acid', 'Analgesics', 'Pain Relief', '10 Tablets', 'Pfizer'),
('BRUF001', 'Brufen 400mg', 'Ibuprofen', 'Analgesics', 'Pain Relief', '20 Tablets', 'Abbott'),
('AFEN001', 'Afen Plus', 'Ibuprofen + Paracetamol', 'Analgesics', 'Pain Relief', '20 Tablets', 'Novartis');

-- Add batches with prices for pain relief medicines
INSERT INTO batches (medicine_id, batch_number, expiry_date, quantity, purchase_price, sale_price) VALUES
((SELECT id FROM medicines WHERE code = 'PANA001' LIMIT 1), 'PAN2024001', '2025-12-31', 200, 2.50, 5.00),
((SELECT id FROM medicines WHERE code = 'PANA002' LIMIT 1), 'PAN2024002', '2025-11-30', 150, 4.00, 8.00),
((SELECT id FROM medicines WHERE code = 'DISP001' LIMIT 1), 'DIS2024001', '2025-10-31', 180, 2.00, 4.00),
((SELECT id FROM medicines WHERE code = 'PONT001' LIMIT 1), 'PON2024001', '2026-01-31', 100, 6.00, 12.00),
((SELECT id FROM medicines WHERE code = 'BRUF001' LIMIT 1), 'BRU2024001', '2025-09-30', 250, 3.50, 7.00),
((SELECT id FROM medicines WHERE code = 'AFEN001' LIMIT 1), 'AFE2024001', '2025-08-31', 120, 5.00, 10.00);

-- Antibiotics
INSERT INTO medicines (code, name, generic_name, main_category, sub_category, pack_size, manufacturer) VALUES
('AUGM001', 'Augmentin 625mg', 'Amoxicillin + Clavulanic Acid', 'Antibiotics', 'Combination', '10 Tablets', 'GSK'),
('AZIT001', 'Zithromax 500mg', 'Azithromycin', 'Antibiotics', 'Macrolides', '3 Tablets', 'Pfizer'),
('CIPR001', 'Ciproxin 500mg', 'Ciprofloxacin', 'Antibiotics', 'Fluoroquinolones', '10 Tablets', 'Bayer'),
('CLAV001', 'Clavulin 375mg', 'Amoxicillin + Clavulanic Acid', 'Antibiotics', 'Combination', '14 Tablets', 'GSK'),
('CEFI001', 'Cefspan 200mg', 'Cefixime', 'Antibiotics', 'Cephalosporins', '10 Tablets', 'Getz Pharma'),
('MOXI001', 'Moxiflox 400mg', 'Moxifloxacin', 'Antibiotics', 'Fluoroquinolones', '5 Tablets', 'Abbott');

INSERT INTO batches (medicine_id, batch_number, expiry_date, quantity, purchase_price, sale_price) VALUES
((SELECT id FROM medicines WHERE code = 'AUGM001' LIMIT 1), 'AUG2024001', '2025-12-31', 80, 150.00, 300.00),
((SELECT id FROM medicines WHERE code = 'AZIT001' LIMIT 1), 'ZIT2024001', '2026-02-28', 60, 180.00, 360.00),
((SELECT id FROM medicines WHERE code = 'CIPR001' LIMIT 1), 'CIP2024001', '2025-11-30', 90, 80.00, 160.00),
((SELECT id FROM medicines WHERE code = 'CLAV001' LIMIT 1), 'CLA2024001', '2025-10-31', 70, 120.00, 240.00),
((SELECT id FROM medicines WHERE code = 'CEFI001' LIMIT 1), 'CEF2024001', '2026-03-31', 100, 100.00, 200.00),
((SELECT id FROM medicines WHERE code = 'MOXI001' LIMIT 1), 'MOX2024001', '2025-12-31', 50, 250.00, 500.00);

-- Antacids & Digestive
INSERT INTO medicines (code, name, generic_name, main_category, sub_category, pack_size, manufacturer) VALUES
('GAVI001', 'Gaviscon Syrup', 'Sodium Alginate', 'Antacids', 'Liquid', '200ml', 'Reckitt Benckiser'),
('OMEP001', 'Omez 20mg', 'Omeprazole', 'Antacids', 'PPI', '14 Capsules', 'Dr. Reddy''s'),
('RABE001', 'Rabeprazole 20mg', 'Rabeprazole', 'Antacids', 'PPI', '14 Tablets', 'Getz Pharma'),
('GELUSIL', 'Gelusil MPS', 'Aluminum Hydroxide + Magnesium', 'Antacids', 'Suspension', '170ml', 'Pfizer'),
('MOTIL001', 'Motilium 10mg', 'Domperidone', 'Antacids', 'Prokinetic', '30 Tablets', 'Sanofi'),
('RISEK001', 'Risek 20mg', 'Omeprazole', 'Antacids', 'PPI', '14 Capsules', 'Getz Pharma');

INSERT INTO batches (medicine_id, batch_number, expiry_date, quantity, purchase_price, sale_price) VALUES
((SELECT id FROM medicines WHERE code = 'GAVI001' LIMIT 1), 'GAV2024001', '2025-09-30', 40, 250.00, 500.00),
((SELECT id FROM medicines WHERE code = 'OMEP001' LIMIT 1), 'OME2024001', '2025-12-31', 120, 50.00, 100.00),
((SELECT id FROM medicines WHERE code = 'RABE001' LIMIT 1), 'RAB2024001', '2026-01-31', 100, 60.00, 120.00),
((SELECT id FROM medicines WHERE code = 'GELUSIL' LIMIT 1), 'GEL2024001', '2025-11-30', 60, 100.00, 200.00),
((SELECT id FROM medicines WHERE code = 'MOTIL001' LIMIT 1), 'MOT2024001', '2025-10-31', 80, 120.00, 240.00),
((SELECT id FROM medicines WHERE code = 'RISEK001' LIMIT 1), 'RIS2024001', '2026-02-28', 150, 45.00, 90.00);

-- Cough & Cold
INSERT INTO medicines (code, name, generic_name, main_category, sub_category, pack_size, manufacturer) VALUES
('RYNA001', 'Rynathsiol Syrup', 'Carbocisteine', 'Cough/Cold', 'Expectorant', '120ml', 'Sanofi'),
('BRON001', 'Brofex Syrup', 'Bromhexine', 'Cough/Cold', 'Expectorant', '120ml', 'Highnu Pharma'),
('ACTI001', 'Actifed Syrup', 'Triprolidine + Pseudoephedrine', 'Cough/Cold', 'Antihistamine', '100ml', 'GSK'),
('LETR001', 'Letrozine 5mg', 'Levocetirizine', 'Cough/Cold', 'Antihistamine', '10 Tablets', 'Getz Pharma'),
('CETR001', 'Cetrizet 10mg', 'Cetirizine', 'Cough/Cold', 'Antihistamine', '10 Tablets', 'Barrett Hodgson'),
('DEXO001', 'Dexodril Syrup', 'Dextromethorphan', 'Cough/Cold', 'Cough Suppressant', '120ml', 'Saffron Pharma');

INSERT INTO batches (medicine_id, batch_number, expiry_date, quantity, purchase_price, sale_price) VALUES
((SELECT id FROM medicines WHERE code = 'RYNA001' LIMIT 1), 'RYN2024001', '2025-08-31', 50, 100.00, 200.00),
((SELECT id FROM medicines WHERE code = 'BRON001' LIMIT 1), 'BRO2024001', '2025-09-30', 60, 80.00, 160.00),
((SELECT id FROM medicines WHERE code = 'ACTI001' LIMIT 1), 'ACT2024001', '2025-10-31', 40, 120.00, 240.00),
((SELECT id FROM medicines WHERE code = 'LETR001' LIMIT 1), 'LET2024001', '2026-01-31', 100, 60.00, 120.00),
((SELECT id FROM medicines WHERE code = 'CETR001' LIMIT 1), 'CET2024001', '2025-12-31', 120, 40.00, 80.00),
((SELECT id FROM medicines WHERE code = 'DEXO001' LIMIT 1), 'DEX2024001', '2025-11-30', 45, 90.00, 180.00);

-- Vitamins & Supplements
INSERT INTO medicines (code, name, generic_name, main_category, sub_category, pack_size, manufacturer) VALUES
('MULT001', 'Multivitamin Capsules', 'Multivitamins', 'Supplements', 'Vitamins', '30 Capsules', 'Getz Pharma'),
('CALC001', 'Calcet D3', 'Calcium + Vitamin D3', 'Supplements', 'Minerals', '30 Tablets', 'Abbott'),
('FERR001', 'Ferobin Capsules', 'Iron + Folic Acid', 'Supplements', 'Minerals', '30 Capsules', 'Hilton Pharma'),
('OMEG001', 'Omega-3 Capsules', 'Fish Oil', 'Supplements', 'Omega Fatty Acids', '30 Capsules', 'Novartis'),
('VITC001', 'Vitamin C 500mg', 'Ascorbic Acid', 'Supplements', 'Vitamins', '30 Tablets', 'Barrett Hodgson'),
('VITD001', 'Vitamin D3 5000 IU', 'Cholecalciferol', 'Supplements', 'Vitamins', '30 Tablets', 'Getz Pharma');

INSERT INTO batches (medicine_id, batch_number, expiry_date, quantity, purchase_price, sale_price) VALUES
((SELECT id FROM medicines WHERE code = 'MULT001' LIMIT 1), 'MUL2024001', '2026-06-30', 100, 100.00, 200.00),
((SELECT id FROM medicines WHERE code = 'CALC001' LIMIT 1), 'CAL2024001', '2026-05-31', 80, 150.00, 300.00),
((SELECT id FROM medicines WHERE code = 'FERR001' LIMIT 1), 'FER2024001', '2026-04-30', 90, 80.00, 160.00),
((SELECT id FROM medicines WHERE code = 'OMEG001' LIMIT 1), 'OME2024001', '2026-07-31', 60, 200.00, 400.00),
((SELECT id FROM medicines WHERE code = 'VITC001' LIMIT 1), 'VIC2024001', '2026-08-31', 120, 50.00, 100.00),
((SELECT id FROM medicines WHERE code = 'VITD001' LIMIT 1), 'VID2024001', '2026-09-30', 100, 120.00, 240.00);

-- Diabetes Medicines
INSERT INTO medicines (code, name, generic_name, main_category, sub_category, pack_size, manufacturer) VALUES
('GLUC001', 'Glucophage 500mg', 'Metformin', 'Antidiabetic', 'Biguanides', '60 Tablets', 'Merck'),
('GLIM001', 'Glimepiride 2mg', 'Glimepiride', 'Antidiabetic', 'Sulfonylureas', '30 Tablets', 'Getz Pharma'),
('GALI001', 'Galvus Met 50/500', 'Vildagliptin + Metformin', 'Antidiabetic', 'Combination', '30 Tablets', 'Novartis'),
('JANU001', 'Januvia 100mg', 'Sitagliptin', 'Antidiabetic', 'DPP-4 Inhibitors', '28 Tablets', 'MSD'),
('INSU001', 'Insulatard Flexpen', 'Insulin Isophane', 'Antidiabetic', 'Insulin', '3ml Pen', 'Novo Nordisk'),
('FORX001', 'Forxiga 10mg', 'Dapagliflozin', 'Antidiabetic', 'SGLT2 Inhibitors', '28 Tablets', 'AstraZeneca');

INSERT INTO batches (medicine_id, batch_number, expiry_date, quantity, purchase_price, sale_price) VALUES
((SELECT id FROM medicines WHERE code = 'GLUC001' LIMIT 1), 'GLU2024001', '2026-03-31', 150, 100.00, 200.00),
((SELECT id FROM medicines WHERE code = 'GLIM001' LIMIT 1), 'GLI2024001', '2026-02-28', 100, 60.00, 120.00),
((SELECT id FROM medicines WHERE code = 'GALI001' LIMIT 1), 'GAL2024001', '2026-04-30', 60, 400.00, 800.00),
((SELECT id FROM medicines WHERE code = 'JANU001' LIMIT 1), 'JAN2024001', '2026-05-31', 40, 1200.00, 2400.00),
((SELECT id FROM medicines WHERE code = 'INSU001' LIMIT 1), 'INS2024001', '2025-12-31', 30, 400.00, 800.00),
((SELECT id FROM medicines WHERE code = 'FORX001' LIMIT 1), 'FOR2024001', '2026-06-30', 50, 1500.00, 3000.00);

-- Blood Pressure Medicines
INSERT INTO medicines (code, name, generic_name, main_category, sub_category, pack_size, manufacturer) VALUES
('NORM001', 'Norvasc 5mg', 'Amlodipine', 'Antihypertensive', 'CCB', '30 Tablets', 'Pfizer'),
('ATEN001', 'Atenolol 50mg', 'Atenolol', 'Antihypertensive', 'Beta Blockers', '30 Tablets', 'Barrett Hodgson'),
('TELM001', 'Telmisartan 40mg', 'Telmisartan', 'Antihypertensive', 'ARB', '30 Tablets', 'Getz Pharma'),
('RAME001', 'Ramipril 5mg', 'Ramipril', 'Antihypertensive', 'ACE Inhibitors', '30 Tablets', 'Sanofi'),
('CARV001', 'Carvedilol 6.25mg', 'Carvedilol', 'Antihypertensive', 'Beta Blockers', '30 Tablets', 'GSK'),
('LOSA001', 'Losartan 50mg', 'Losartan', 'Antihypertensive', 'ARB', '30 Tablets', 'Abbott');

INSERT INTO batches (medicine_id, batch_number, expiry_date, quantity, purchase_price, sale_price) VALUES
((SELECT id FROM medicines WHERE code = 'NORM001' LIMIT 1), 'NOR2024001', '2026-01-31', 120, 120.00, 240.00),
((SELECT id FROM medicines WHERE code = 'ATEN001' LIMIT 1), 'ATE2024001', '2026-02-28', 150, 30.00, 60.00),
((SELECT id FROM medicines WHERE code = 'TELM001' LIMIT 1), 'TEL2024001', '2026-03-31', 100, 80.00, 160.00),
((SELECT id FROM medicines WHERE code = 'RAME001' LIMIT 1), 'RAM2024001', '2026-04-30', 90, 100.00, 200.00),
((SELECT id FROM medicines WHERE code = 'CARV001' LIMIT 1), 'CAR2024001', '2026-05-31', 80, 150.00, 300.00),
((SELECT id FROM medicines WHERE code = 'LOSA001' LIMIT 1), 'LOS2024001', '2026-06-30', 110, 70.00, 140.00);

-- Cholesterol/Lipid Medicines
INSERT INTO medicines (code, name, generic_name, main_category, sub_category, pack_size, manufacturer) VALUES
('ATOR001', 'Atorvastatin 20mg', 'Atorvastatin', 'Lipid Lowering', 'Statins', '30 Tablets', 'Pfizer'),
('ROSU001', 'Rosuvastatin 10mg', 'Rosuvastatin', 'Lipid Lowering', 'Statins', '30 Tablets', 'AstraZeneca'),
('SIMV001', 'Simvastatin 20mg', 'Simvastatin', 'Lipid Lowering', 'Statins', '30 Tablets', 'Getz Pharma'),
('FENO001', 'Fenofibrate 160mg', 'Fenofibrate', 'Lipid Lowering', 'Fibrates', '30 Tablets', 'Abbott'),
('EZET001', 'Ezetimibe 10mg', 'Ezetimibe', 'Lipid Lowering', 'Cholesterol Absorption Inhibitor', '30 Tablets', 'Merck'),
('PRAV001', 'Pravastatin 40mg', 'Pravastatin', 'Lipid Lowering', 'Statins', '30 Tablets', 'Bristol-Myers Squibb');

INSERT INTO batches (medicine_id, batch_number, expiry_date, quantity, purchase_price, sale_price) VALUES
((SELECT id FROM medicines WHERE code = 'ATOR001' LIMIT 1), 'ATO2024001', '2026-02-28', 130, 80.00, 160.00),
((SELECT id FROM medicines WHERE code = 'ROSU001' LIMIT 1), 'ROS2024001', '2026-03-31', 100, 150.00, 300.00),
((SELECT id FROM medicines WHERE code = 'SIMV001' LIMIT 1), 'SIM2024001', '2026-04-30', 120, 60.00, 120.00),
((SELECT id FROM medicines WHERE code = 'FENO001' LIMIT 1), 'FEN2024001', '2026-05-31', 80, 200.00, 400.00),
((SELECT id FROM medicines WHERE code = 'EZET001' LIMIT 1), 'EZE2024001', '2026-06-30', 70, 250.00, 500.00),
((SELECT id FROM medicines WHERE code = 'PRAV001' LIMIT 1), 'PRA2024001', '2026-07-31', 60, 180.00, 360.00);

-- Dermatological Products
INSERT INTO medicines (code, name, generic_name, main_category, sub_category, pack_size, manufacturer) VALUES
('FUSI001', 'Fucidin Cream', 'Fusidic Acid', 'Dermatology', 'Antibacterial', '15g Tube', 'Leo Pharma'),
('BETA001', 'Betnovate-N Cream', 'Betamethasone + Neomycin', 'Dermatology', 'Steroid', '15g Tube', 'GSK'),
('CLOT001', 'Candid Cream', 'Clotrimazole', 'Dermatology', 'Antifungal', '20g Tube', 'Glenmark'),
('HYDR001', 'Hydrozole Cream', 'Hydrocortisone', 'Dermatology', 'Steroid', '15g Tube', 'Efroze Chemical'),
('MOME001', 'Elocon Cream', 'Mometasone', 'Dermatology', 'Steroid', '15g Tube', 'Merck'),
('MUPIR001', 'Mupirocin Ointment', 'Mupirocin', 'Dermatology', 'Antibacterial', '15g Tube', 'GSK');

INSERT INTO batches (medicine_id, batch_number, expiry_date, quantity, purchase_price, sale_price) VALUES
((SELECT id FROM medicines WHERE code = 'FUSI001' LIMIT 1), 'FUS2024001', '2025-12-31', 50, 150.00, 300.00),
((SELECT id FROM medicines WHERE code = 'BETA001' LIMIT 1), 'BET2024001', '2025-11-30', 60, 80.00, 160.00),
((SELECT id FROM medicines WHERE code = 'CLOT001' LIMIT 1), 'CLO2024001', '2026-01-31', 70, 60.00, 120.00),
((SELECT id FROM medicines WHERE code = 'HYDR001' LIMIT 1), 'HYD2024001', '2025-10-31', 80, 40.00, 80.00),
((SELECT id FROM medicines WHERE code = 'MOME001' LIMIT 1), 'MOM2024001', '2026-02-28', 40, 200.00, 400.00),
((SELECT id FROM medicines WHERE code = 'MUPIR001' LIMIT 1), 'MUP2024001', '2025-12-31', 55, 120.00, 240.00);

-- Eye & Ear Drops
INSERT INTO medicines (code, name, generic_name, main_category, sub_category, pack_size, manufacturer) VALUES
('TOBA001', 'Tobramycin Eye Drops', 'Tobramycin', 'Ophthalmic', 'Antibacterial', '5ml', 'Alcon'),
('CHLO001', 'Chloramphenicol Eye Drops', 'Chloramphenicol', 'Ophthalmic', 'Antibacterial', '10ml', 'Barrett Hodgson'),
('ARTP001', 'Artificial Tears', 'Hypromellose', 'Ophthalmic', 'Lubricant', '10ml', 'Allergan'),
('TIMP001', 'Timolol Eye Drops', 'Timolol', 'Ophthalmic', 'Glaucoma', '5ml', 'Merck'),
('OFLOX001', 'Ofloxacin Ear Drops', 'Ofloxacin', 'Otic', 'Antibacterial', '5ml', 'Cipla'),
('SODI001', 'Otomize Ear Spray', 'Neomycin + Dexamethasone', 'Otic', 'Combination', '5ml', 'GSK');

INSERT INTO batches (medicine_id, batch_number, expiry_date, quantity, purchase_price, sale_price) VALUES
((SELECT id FROM medicines WHERE code = 'TOBA001' LIMIT 1), 'TOB2024001', '2025-09-30', 40, 100.00, 200.00),
((SELECT id FROM medicines WHERE code = 'CHLO001' LIMIT 1), 'CHL2024001', '2025-10-31', 60, 40.00, 80.00),
((SELECT id FROM medicines WHERE code = 'ARTP001' LIMIT 1), 'ART2024001', '2026-01-31', 80, 120.00, 240.00),
((SELECT id FROM medicines WHERE code = 'TIMP001' LIMIT 1), 'TIM2024001', '2025-12-31', 30, 150.00, 300.00),
((SELECT id FROM medicines WHERE code = 'OFLOX001' LIMIT 1), 'OFL2024001', '2025-11-30', 50, 80.00, 160.00),
((SELECT id FROM medicines WHERE code = 'SODI001' LIMIT 1), 'SOD2024001', '2026-02-28', 35, 200.00, 400.00);

-- Women's Health
INSERT INTO medicines (code, name, generic_name, main_category, sub_category, pack_size, manufacturer) VALUES
('FOLP001', 'Folic Acid 5mg', 'Folic Acid', 'Women Health', 'Prenatal', '100 Tablets', 'Getz Pharma'),
('IRON001', 'Feroglobin Capsules', 'Iron + B12', 'Women Health', 'Supplements', '30 Capsules', 'Vitabiotics'),
('DUPH001', 'Duphaston 10mg', 'Dydrogesterone', 'Women Health', 'Hormonal', '20 Tablets', 'Abbott'),
('PRIM001', 'Primolut-N', 'Norethisterone', 'Women Health', 'Hormonal', '30 Tablets', 'Bayer'),
('FLUCON', 'Fluconazole 150mg', 'Fluconazole', 'Women Health', 'Antifungal', '1 Capsule', 'Pfizer'),
('CLOM001', 'Clomid 50mg', 'Clomiphene', 'Women Health', 'Fertility', '10 Tablets', 'Sanofi');

INSERT INTO batches (medicine_id, batch_number, expiry_date, quantity, purchase_price, sale_price) VALUES
((SELECT id FROM medicines WHERE code = 'FOLP001' LIMIT 1), 'FOL2024001', '2026-06-30', 200, 30.00, 60.00),
((SELECT id FROM medicines WHERE code = 'IRON001' LIMIT 1), 'IRO2024001', '2026-05-31', 100, 250.00, 500.00),
((SELECT id FROM medicines WHERE code = 'DUPH001' LIMIT 1), 'DUP2024001', '2026-04-30', 60, 300.00, 600.00),
((SELECT id FROM medicines WHERE code = 'PRIM001' LIMIT 1), 'PRI2024001', '2026-03-31', 80, 150.00, 300.00),
((SELECT id FROM medicines WHERE code = 'FLUCON' LIMIT 1), 'FLU2024001', '2026-02-28', 100, 40.00, 80.00),
((SELECT id FROM medicines WHERE code = 'CLOM001' LIMIT 1), 'CLO2024001', '2026-07-31', 50, 400.00, 800.00);

-- Additional Common Medicines (to reach 100)
INSERT INTO medicines (code, name, generic_name, main_category, sub_category, pack_size, manufacturer) VALUES
('ASPI001', 'Aspirin 75mg', 'Aspirin', 'Cardiovascular', 'Antiplatelet', '30 Tablets', 'Bayer'),
('CLOP001', 'Clopidogrel 75mg', 'Clopidogrel', 'Cardiovascular', 'Antiplatelet', '14 Tablets', 'Sanofi'),
('DIGO001', 'Digoxin 0.25mg', 'Digoxin', 'Cardiovascular', 'Cardiac Glycoside', '100 Tablets', 'GSK'),
('FURO001', 'Lasix 40mg', 'Furosemide', 'Cardiovascular', 'Diuretic', '30 Tablets', 'Sanofi'),
('SPIR001', 'Spironolactone 25mg', 'Spironolactone', 'Cardiovascular', 'Diuretic', '30 Tablets', 'Pfizer'),
('WARF001', 'Warfarin 5mg', 'Warfarin', 'Cardiovascular', 'Anticoagulant', '30 Tablets', 'Orion'),
('ALPU001', 'Alprazolam 0.5mg', 'Alprazolam', 'Neuropsychiatry', 'Anxiolytic', '30 Tablets', 'Pfizer'),
('DIAZ001', 'Diazepam 5mg', 'Diazepam', 'Neuropsychiatry', 'Anxiolytic', '30 Tablets', 'Roche'),
('FLUO001', 'Fluoxetine 20mg', 'Fluoxetine', 'Neuropsychiatry', 'Antidepressant', '30 Capsules', 'Eli Lilly'),
('AMIT001', 'Amitriptyline 25mg', 'Amitriptyline', 'Neuropsychiatry', 'Antidepressant', '30 Tablets', 'Roche');

INSERT INTO batches (medicine_id, batch_number, expiry_date, quantity, purchase_price, sale_price) VALUES
((SELECT id FROM medicines WHERE code = 'ASPI001' LIMIT 1), 'ASP2024001', '2026-08-31', 200, 10.00, 20.00),
((SELECT id FROM medicines WHERE code = 'CLOP001' LIMIT 1), 'CLO2024002', '2026-07-31', 100, 150.00, 300.00),
((SELECT id FROM medicines WHERE code = 'DIGO001' LIMIT 1), 'DIG2024001', '2026-06-30', 80, 20.00, 40.00),
((SELECT id FROM medicines WHERE code = 'FURO001' LIMIT 1), 'FUR2024001', '2026-05-31', 150, 25.00, 50.00),
((SELECT id FROM medicines WHERE code = 'SPIR001' LIMIT 1), 'SPI2024001', '2026-04-30', 90, 35.00, 70.00),
((SELECT id FROM medicines WHERE code = 'WARF001' LIMIT 1), 'WAR2024001', '2026-09-30', 60, 30.00, 60.00),
((SELECT id FROM medicines WHERE code = 'ALPU001' LIMIT 1), 'ALP2024001', '2026-03-31', 70, 50.00, 100.00),
((SELECT id FROM medicines WHERE code = 'DIAZ001' LIMIT 1), 'DIA2024001', '2026-02-28', 80, 40.00, 80.00),
((SELECT id FROM medicines WHERE code = 'FLUO001' LIMIT 1), 'FLU2024002', '2026-10-31', 60, 200.00, 400.00),
((SELECT id FROM medicines WHERE code = 'AMIT001' LIMIT 1), 'AMI2024001', '2026-11-30', 70, 60.00, 120.00);

-- Pharmacy Items (Non-Medicine Products)
INSERT INTO medicines (code, name, generic_name, main_category, sub_category, pack_size, manufacturer) VALUES
('BAND001', 'Bandages - Cotton', 'Medical Supplies', 'Pharmacy Items', 'First Aid', '1 Roll', 'Multiple'),
('GLOV001', 'Surgical Gloves', 'Medical Supplies', 'Pharmacy Items', 'PPE', '1 Pair', 'Multiple'),
('SYRN001', 'Disposable Syringe 5ml', 'Medical Supplies', 'Pharmacy Items', 'Injection', '1 Piece', 'BD'),
('GAUS001', 'Gauze Pads', 'Medical Supplies', 'Pharmacy Items', 'First Aid', '10 Pieces', 'Multiple'),
('COTT001', 'Cotton Wool', 'Medical Supplies', 'Pharmacy Items', 'First Aid', '50g Pack', 'Multiple'),
('ALCO001', 'Alcohol Swabs', 'Medical Supplies', 'Pharmacy Items', 'Antiseptic', '100 Pieces', 'Multiple'),
('THEM001', 'Digital Thermometer', 'Medical Devices', 'Pharmacy Items', 'Diagnostic', '1 Piece', 'Omron'),
('GLUC002', 'Glucometer Strips', 'Medical Devices', 'Pharmacy Items', 'Diagnostic', '25 Strips', 'Accu-Chek'),
('BPMO001', 'BP Monitor', 'Medical Devices', 'Pharmacy Items', 'Diagnostic', '1 Piece', 'Omron'),
('MASK001', 'Surgical Masks', 'Medical Supplies', 'Pharmacy Items', 'PPE', '50 Pieces', 'Multiple');

INSERT INTO batches (medicine_id, batch_number, expiry_date, quantity, purchase_price, sale_price) VALUES
((SELECT id FROM medicines WHERE code = 'BAND001' LIMIT 1), 'BAN2024001', '2027-12-31', 100, 20.00, 40.00),
((SELECT id FROM medicines WHERE code = 'GLOV001' LIMIT 1), 'GLO2024001', '2027-12-31', 200, 5.00, 10.00),
((SELECT id FROM medicines WHERE code = 'SYRN001' LIMIT 1), 'SYR2024001', '2027-12-31', 500, 5.00, 10.00),
((SELECT id FROM medicines WHERE code = 'GAUS001' LIMIT 1), 'GAU2024001', '2027-12-31', 150, 15.00, 30.00),
((SELECT id FROM medicines WHERE code = 'COTT001' LIMIT 1), 'COT2024001', '2027-12-31', 200, 10.00, 20.00),
((SELECT id FROM medicines WHERE code = 'ALCO001' LIMIT 1), 'ALC2024001', '2027-12-31', 100, 50.00, 100.00),
((SELECT id FROM medicines WHERE code = 'THEM001' LIMIT 1), 'THE2024001', '2029-12-31', 30, 300.00, 600.00),
((SELECT id FROM medicines WHERE code = 'GLUC002' LIMIT 1), 'GLU2024002', '2026-12-31', 50, 400.00, 800.00),
((SELECT id FROM medicines WHERE code = 'BPMO001' LIMIT 1), 'BPM2024001', '2029-12-31', 20, 1500.00, 3000.00),
((SELECT id FROM medicines WHERE code = 'MASK001' LIMIT 1), 'MAS2024001', '2027-12-31', 100, 200.00, 400.00);
