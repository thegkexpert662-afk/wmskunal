CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_code VARCHAR(40) NOT NULL UNIQUE,
  name VARCHAR(200) NOT NULL,
  logo_url TEXT,
  address TEXT,
  gstin VARCHAR(20),
  email VARCHAR(200),
  mobile VARCHAR(30),
  invoice_locked BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE companies
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;

CREATE INDEX IF NOT EXISTS idx_companies_active ON companies(is_active);

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id),
  user_code VARCHAR(40) UNIQUE DEFAULT ('USR-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10))),
  employee_code VARCHAR(60),
  username VARCHAR(100) NOT NULL UNIQUE,
  email VARCHAR(200) UNIQUE,
  password_hash TEXT NOT NULL,
  full_name VARCHAR(150) NOT NULL,
  phone VARCHAR(30),
  department VARCHAR(100),
  designation VARCHAR(120),
  role VARCHAR(30) NOT NULL CHECK (role IN ('master_admin','admin','client','warehouse_manager','warehouse_supervisor','warehouse_operator','warehouse_qc','gate_operator','inventory_user','dispatch_user')),
  client_id UUID,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  permission_key VARCHAR(100) NOT NULL UNIQUE,
  description TEXT
);

CREATE TABLE IF NOT EXISTS role_permissions (
  role VARCHAR(30) NOT NULL,
  permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role, permission_id)
);

CREATE TABLE IF NOT EXISTS company_modules (
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  module_key VARCHAR(50) NOT NULL,
  is_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (company_id, module_key)
);

CREATE TABLE IF NOT EXISTS devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id),
  user_id UUID REFERENCES users(id),
  device_name VARCHAR(150),
  device_type VARCHAR(50),
  credential_id TEXT UNIQUE,
  status VARCHAR(20) NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','approved','rejected','revoked')),
  first_registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_seen_at TIMESTAMPTZ,
  last_ip INET,
  user_agent TEXT,
  approved_by UUID REFERENCES users(id),
  approved_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  client_code VARCHAR(50) NOT NULL,
  name VARCHAR(200) NOT NULL,
  email VARCHAR(200),
  mobile VARCHAR(30),
  gstin VARCHAR(20),
  address TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, client_code)
);

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS user_code VARCHAR(40) UNIQUE DEFAULT ('USR-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10))),
  ADD COLUMN IF NOT EXISTS employee_code VARCHAR(60),
  ADD COLUMN IF NOT EXISTS phone VARCHAR(30),
  ADD COLUMN IF NOT EXISTS department VARCHAR(100),
  ADD COLUMN IF NOT EXISTS designation VARCHAR(120);

UPDATE users SET user_code = 'USR-' || upper(substr(replace(id::text, '-', ''), 1, 10)) WHERE user_code IS NULL;
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('master_admin','admin','client','warehouse_manager','warehouse_supervisor','warehouse_operator','warehouse_qc','gate_operator','inventory_user','dispatch_user'));

ALTER TABLE users
  DROP CONSTRAINT IF EXISTS users_client_id_fkey;

ALTER TABLE users
  ADD CONSTRAINT users_client_id_fkey
  FOREIGN KEY (client_id) REFERENCES clients(id);

CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  sku VARCHAR(100) NOT NULL,
  name VARCHAR(250) NOT NULL,
  description TEXT,
  hsn_code VARCHAR(30),
  uom VARCHAR(30),
  rate NUMERIC(18,4) NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, sku)
);

CREATE TABLE IF NOT EXISTS warehouses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  code VARCHAR(50) NOT NULL,
  name VARCHAR(150) NOT NULL,
  address TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE (company_id, code)
);

CREATE TABLE IF NOT EXISTS warehouse_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
  code VARCHAR(80) NOT NULL,
  zone VARCHAR(80),
  bin VARCHAR(80),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (warehouse_id, code)
);

ALTER TABLE warehouse_locations
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

CREATE TABLE IF NOT EXISTS user_warehouses (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  warehouse_id UUID NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  assigned_by UUID REFERENCES users(id),
  PRIMARY KEY (user_id, warehouse_id)
);

CREATE INDEX IF NOT EXISTS idx_user_warehouses_warehouse ON user_warehouses(warehouse_id);
CREATE INDEX IF NOT EXISTS idx_users_company_role ON users(company_id, role);

CREATE TABLE IF NOT EXISTS grns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  grn_no VARCHAR(60) NOT NULL,
  supplier_name VARCHAR(200),
  invoice_no VARCHAR(100),
  warehouse_id UUID REFERENCES warehouses(id),
  status VARCHAR(30) NOT NULL DEFAULT 'draft',
  received_at TIMESTAMPTZ,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, grn_no)
);

CREATE TABLE IF NOT EXISTS production_receipts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  receipt_no VARCHAR(60) NOT NULL,
  production_reference VARCHAR(100),
  warehouse_id UUID REFERENCES warehouses(id),
  status VARCHAR(30) NOT NULL DEFAULT 'received',
  received_at TIMESTAMPTZ,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, receipt_no)
);

CREATE TABLE IF NOT EXISTS production_receipt_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  receipt_id UUID NOT NULL REFERENCES production_receipts(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  received_qty NUMERIC(18,4) NOT NULL CHECK (received_qty > 0),
  qc_status VARCHAR(20) NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_production_receipts_company_created
  ON production_receipts(company_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_production_receipt_items_receipt
  ON production_receipt_items(receipt_id);

CREATE TABLE IF NOT EXISTS grn_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  grn_id UUID NOT NULL REFERENCES grns(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  received_qty NUMERIC(18,4) NOT NULL CHECK (received_qty >= 0),
  qc_status VARCHAR(20) NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS qc_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  grn_item_id UUID REFERENCES grn_items(id) ON DELETE CASCADE,
  production_receipt_item_id UUID REFERENCES production_receipt_items(id) ON DELETE CASCADE,
  result VARCHAR(20) NOT NULL DEFAULT 'pending'
    CHECK (result IN ('pending','approved','rejected','partial')),
  inspected_qty NUMERIC(18,4) NOT NULL CHECK (inspected_qty > 0),
  accepted_qty NUMERIC(18,4) NOT NULL DEFAULT 0 CHECK (accepted_qty >= 0),
  rejected_qty NUMERIC(18,4) NOT NULL DEFAULT 0 CHECK (rejected_qty >= 0),
  remarks TEXT,
  inspected_by UUID REFERENCES users(id),
  inspected_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (
    (grn_item_id IS NOT NULL AND production_receipt_item_id IS NULL)
    OR
    (grn_item_id IS NULL AND production_receipt_item_id IS NOT NULL)
  ),
  CHECK (accepted_qty + rejected_qty <= inspected_qty)
);

CREATE INDEX IF NOT EXISTS idx_qc_company_created
  ON qc_records(company_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_qc_grn_item
  ON qc_records(grn_item_id);

CREATE INDEX IF NOT EXISTS idx_qc_production_item
  ON qc_records(production_receipt_item_id);

CREATE TABLE IF NOT EXISTS putaway_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  putaway_no VARCHAR(60),
  grn_item_id UUID REFERENCES grn_items(id) ON DELETE CASCADE,
  production_receipt_item_id UUID REFERENCES production_receipt_items(id) ON DELETE CASCADE,
  location_id UUID REFERENCES warehouse_locations(id),
  quantity NUMERIC(18,4) NOT NULL CHECK (quantity > 0),
  status VARCHAR(30) NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','in_progress','completed','cancelled')),
  processed_by UUID REFERENCES users(id),
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (
    (grn_item_id IS NOT NULL AND production_receipt_item_id IS NULL)
    OR
    (grn_item_id IS NULL AND production_receipt_item_id IS NOT NULL)
  ),
  UNIQUE (company_id, putaway_no)
);

ALTER TABLE putaway_tasks ALTER COLUMN grn_item_id DROP NOT NULL;
ALTER TABLE putaway_tasks ADD COLUMN IF NOT EXISTS putaway_no VARCHAR(60);
ALTER TABLE putaway_tasks ADD COLUMN IF NOT EXISTS production_receipt_item_id UUID REFERENCES production_receipt_items(id) ON DELETE CASCADE;
ALTER TABLE putaway_tasks DROP CONSTRAINT IF EXISTS putaway_tasks_grn_item_id_fkey;
ALTER TABLE putaway_tasks ADD CONSTRAINT putaway_tasks_grn_item_id_fkey FOREIGN KEY (grn_item_id) REFERENCES grn_items(id) ON DELETE CASCADE;
ALTER TABLE putaway_tasks DROP CONSTRAINT IF EXISTS putaway_tasks_source_check;
ALTER TABLE putaway_tasks ADD CONSTRAINT putaway_tasks_source_check CHECK (
  (grn_item_id IS NOT NULL AND production_receipt_item_id IS NULL)
  OR
  (grn_item_id IS NULL AND production_receipt_item_id IS NOT NULL)
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_putaway_no ON putaway_tasks(company_id, putaway_no) WHERE putaway_no IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_putaway_company_created ON putaway_tasks(company_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_putaway_grn_item ON putaway_tasks(grn_item_id);
CREATE INDEX IF NOT EXISTS idx_putaway_production_item ON putaway_tasks(production_receipt_item_id);

CREATE TABLE IF NOT EXISTS inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  product_id UUID NOT NULL REFERENCES products(id),
  warehouse_id UUID NOT NULL REFERENCES warehouses(id),
  location_id UUID REFERENCES warehouse_locations(id),
  quantity NUMERIC(18,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  reserved_quantity NUMERIC(18,4) NOT NULL DEFAULT 0 CHECK (reserved_quantity >= 0),
  damaged_quantity NUMERIC(18,4) NOT NULL DEFAULT 0 CHECK (damaged_quantity >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, product_id, warehouse_id, location_id)
);

ALTER TABLE inventory ADD COLUMN IF NOT EXISTS damaged_quantity NUMERIC(18,4) NOT NULL DEFAULT 0;
CREATE TABLE IF NOT EXISTS inventory_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  product_id UUID NOT NULL REFERENCES products(id),
  warehouse_id UUID REFERENCES warehouses(id),
  location_id UUID REFERENCES warehouse_locations(id),
  transaction_type VARCHAR(40) NOT NULL,
  quantity NUMERIC(18,4) NOT NULL,
  reference_type VARCHAR(50),
  reference_id UUID,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  client_id UUID NOT NULL REFERENCES clients(id),
  order_no VARCHAR(60) NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'draft',
  required_date DATE,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, order_no)
);

ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS warehouse_id UUID REFERENCES warehouses(id),
  ADD COLUMN IF NOT EXISTS remarks TEXT,
  ADD COLUMN IF NOT EXISTS truck_type VARCHAR(100),
  ADD COLUMN IF NOT EXISTS transporter_name VARCHAR(200),
  ADD COLUMN IF NOT EXISTS vehicle_no VARCHAR(60),
  ADD COLUMN IF NOT EXISTS driver_name VARCHAR(150),
  ADD COLUMN IF NOT EXISTS driver_mobile VARCHAR(30),
  ADD COLUMN IF NOT EXISTS shipment_no VARCHAR(100),
  ADD COLUMN IF NOT EXISTS shipment_date DATE,
  ADD COLUMN IF NOT EXISTS delivery_no VARCHAR(100),
  ADD COLUMN IF NOT EXISTS delivery_date DATE,
  ADD COLUMN IF NOT EXISTS sold_by_name VARCHAR(200),
  ADD COLUMN IF NOT EXISTS sold_by_address TEXT,
  ADD COLUMN IF NOT EXISTS sold_by_gstin VARCHAR(20),
  ADD COLUMN IF NOT EXISTS sold_to_name VARCHAR(200),
  ADD COLUMN IF NOT EXISTS sold_to_address TEXT,
  ADD COLUMN IF NOT EXISTS sold_to_gstin VARCHAR(20),
  ADD COLUMN IF NOT EXISTS ship_to_name VARCHAR(200),
  ADD COLUMN IF NOT EXISTS ship_to_address TEXT,
  ADD COLUMN IF NOT EXISTS ship_to_gstin VARCHAR(20);

CREATE INDEX IF NOT EXISTS idx_orders_company_warehouse_created
  ON orders(company_id, warehouse_id, created_at DESC);

ALTER TABLE orders
  DROP CONSTRAINT IF EXISTS orders_status_check;

ALTER TABLE orders
  ADD CONSTRAINT orders_status_check
  CHECK (status IN ('draft','confirmed','allocated','picking','packed','dispatched','delivered','cancelled'));

INSERT INTO role_permissions (role, permission_id)
SELECT 'client', p.id
FROM permissions p
WHERE p.permission_key IN ('order.read','order.create')
ON CONFLICT (role, permission_id) DO NOTHING;

CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  ordered_qty NUMERIC(18,4) NOT NULL CHECK (ordered_qty > 0),
  picked_qty NUMERIC(18,4) NOT NULL DEFAULT 0,
  dispatched_qty NUMERIC(18,4) NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS picking_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  order_id UUID NOT NULL REFERENCES orders(id),
  status VARCHAR(30) NOT NULL DEFAULT 'pending',
  picker_id UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS picking_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  picking_task_id UUID NOT NULL REFERENCES picking_tasks(id) ON DELETE CASCADE,
  order_item_id UUID NOT NULL REFERENCES order_items(id),
  location_id UUID REFERENCES warehouse_locations(id),
  quantity NUMERIC(18,4) NOT NULL CHECK (quantity > 0)
);

ALTER TABLE picking_tasks DROP CONSTRAINT IF EXISTS picking_tasks_status_check;
ALTER TABLE picking_tasks ADD CONSTRAINT picking_tasks_status_check CHECK (status IN ('pending','in_progress','completed','cancelled'));
CREATE UNIQUE INDEX IF NOT EXISTS uq_picking_tasks_active_order ON picking_tasks(order_id) WHERE status IN ('pending','in_progress');
CREATE INDEX IF NOT EXISTS idx_picking_tasks_company_status ON picking_tasks(company_id,status,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_picking_tasks_order ON picking_tasks(order_id);
CREATE INDEX IF NOT EXISTS idx_picking_items_task ON picking_items(picking_task_id);
CREATE INDEX IF NOT EXISTS idx_picking_items_order_item ON picking_items(order_item_id);
CREATE INDEX IF NOT EXISTS idx_picking_items_location ON picking_items(location_id);

INSERT INTO role_permissions (role, permission_id)
SELECT r.role,p.id FROM (VALUES ('warehouse_manager'),('warehouse_supervisor'),('warehouse_operator')) AS r(role)
CROSS JOIN permissions p WHERE p.permission_key='picking.manage'
ON CONFLICT (role,permission_id) DO NOTHING;

CREATE TABLE IF NOT EXISTS packing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  order_id UUID NOT NULL REFERENCES orders(id),
  warehouse_id UUID NOT NULL REFERENCES warehouses(id),
  packing_no VARCHAR(60) NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','in_progress','ready','cancelled')),
  packed_by UUID REFERENCES users(id),
  total_packages INTEGER NOT NULL DEFAULT 0 CHECK (total_packages >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  UNIQUE (company_id, packing_no)
);

ALTER TABLE packing
  ADD COLUMN IF NOT EXISTS warehouse_id UUID REFERENCES warehouses(id),
  ADD COLUMN IF NOT EXISTS packing_no VARCHAR(60),
  ADD COLUMN IF NOT EXISTS total_packages INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE packing DROP CONSTRAINT IF EXISTS packing_status_check;
ALTER TABLE packing ADD CONSTRAINT packing_status_check
  CHECK (status IN ('pending','in_progress','ready','cancelled'));

CREATE UNIQUE INDEX IF NOT EXISTS uq_packing_active_order
  ON packing(order_id) WHERE status IN ('pending','in_progress');

CREATE TABLE IF NOT EXISTS packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  packing_id UUID NOT NULL REFERENCES packing(id) ON DELETE CASCADE,
  package_no VARCHAR(60) NOT NULL,
  package_type VARCHAR(50) NOT NULL DEFAULT 'Box',
  weight NUMERIC(18,4) NOT NULL DEFAULT 0 CHECK (weight >= 0),
  length NUMERIC(18,4) NOT NULL DEFAULT 0 CHECK (length >= 0),
  width NUMERIC(18,4) NOT NULL DEFAULT 0 CHECK (width >= 0),
  height NUMERIC(18,4) NOT NULL DEFAULT 0 CHECK (height >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (packing_id, package_no)
);

CREATE TABLE IF NOT EXISTS packing_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  packing_id UUID NOT NULL REFERENCES packing(id) ON DELETE CASCADE,
  package_id UUID NOT NULL REFERENCES packages(id) ON DELETE CASCADE,
  order_item_id UUID NOT NULL REFERENCES order_items(id),
  product_id UUID NOT NULL REFERENCES products(id),
  quantity NUMERIC(18,4) NOT NULL CHECK (quantity > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_packing_company_created
  ON packing(company_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_packing_company_status
  ON packing(company_id, status);
CREATE INDEX IF NOT EXISTS idx_packing_order
  ON packing(order_id);
CREATE INDEX IF NOT EXISTS idx_packages_packing
  ON packages(packing_id);
CREATE INDEX IF NOT EXISTS idx_packing_items_packing
  ON packing_items(packing_id);
CREATE INDEX IF NOT EXISTS idx_packing_items_order_item
  ON packing_items(order_item_id);

CREATE TABLE IF NOT EXISTS dispatch (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  order_id UUID NOT NULL REFERENCES orders(id),
  packing_id UUID REFERENCES packing(id),
  warehouse_id UUID REFERENCES warehouses(id),
  dispatch_no VARCHAR(60) NOT NULL,
  vehicle_no VARCHAR(50),
  transporter_name VARCHAR(200),
  driver_name VARCHAR(150),
  driver_mobile VARCHAR(30),
  lr_no VARCHAR(100),
  status VARCHAR(30) NOT NULL DEFAULT 'ready'
    CHECK (status IN ('ready','dispatched','in_transit','delivered','cancelled')),
  total_packages INTEGER NOT NULL DEFAULT 0 CHECK (total_packages >= 0),
  total_weight NUMERIC(18,4) NOT NULL DEFAULT 0 CHECK (total_weight >= 0),
  dispatched_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, dispatch_no)
);

ALTER TABLE dispatch
  ADD COLUMN IF NOT EXISTS packing_id UUID REFERENCES packing(id),
  ADD COLUMN IF NOT EXISTS warehouse_id UUID REFERENCES warehouses(id),
  ADD COLUMN IF NOT EXISTS transporter_name VARCHAR(200),
  ADD COLUMN IF NOT EXISTS driver_name VARCHAR(150),
  ADD COLUMN IF NOT EXISTS driver_mobile VARCHAR(30),
  ADD COLUMN IF NOT EXISTS total_packages INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_weight NUMERIC(18,4) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

UPDATE dispatch SET status='ready' WHERE status='pending';

ALTER TABLE dispatch DROP CONSTRAINT IF EXISTS dispatch_status_check;
ALTER TABLE dispatch ADD CONSTRAINT dispatch_status_check
  CHECK (status IN ('ready','dispatched','in_transit','delivered','cancelled'));

CREATE UNIQUE INDEX IF NOT EXISTS uq_dispatch_active_order
  ON dispatch(company_id, order_id)
  WHERE status IN ('ready','dispatched','in_transit');

CREATE INDEX IF NOT EXISTS idx_dispatch_company_status
  ON dispatch(company_id, status);

CREATE INDEX IF NOT EXISTS idx_dispatch_warehouse
  ON dispatch(company_id, warehouse_id);

CREATE TABLE IF NOT EXISTS dispatch_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dispatch_id UUID NOT NULL REFERENCES dispatch(id) ON DELETE CASCADE,
  order_item_id UUID NOT NULL REFERENCES order_items(id),
  quantity NUMERIC(18,4) NOT NULL CHECK (quantity > 0)
);

CREATE TABLE IF NOT EXISTS returns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  client_id UUID REFERENCES clients(id),
  order_id UUID REFERENCES orders(id),
  invoice_id UUID,
  warehouse_id UUID REFERENCES warehouses(id),
  return_no VARCHAR(60) NOT NULL,
  reason TEXT,
  status VARCHAR(30) NOT NULL DEFAULT 'gate_in_pending'
    CHECK (status IN ('requested','gate_in_pending','qc_pending','completed','rejected','cancelled')),
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  gate_in_at TIMESTAMPTZ,
  gate_in_by UUID REFERENCES users(id),
  completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, return_no)
);

ALTER TABLE returns
  ADD COLUMN IF NOT EXISTS invoice_id UUID,
  ADD COLUMN IF NOT EXISTS warehouse_id UUID REFERENCES warehouses(id),
  ADD COLUMN IF NOT EXISTS gate_in_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS gate_in_by UUID REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE returns DROP CONSTRAINT IF EXISTS returns_status_check;
ALTER TABLE returns ADD CONSTRAINT returns_status_check
  CHECK (status IN ('requested','gate_in_pending','qc_pending','completed','rejected','cancelled'));

CREATE TABLE IF NOT EXISTS return_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  return_id UUID NOT NULL REFERENCES returns(id) ON DELETE CASCADE,
  order_item_id UUID REFERENCES order_items(id),
  product_id UUID NOT NULL REFERENCES products(id),
  returned_qty NUMERIC(18,4) NOT NULL CHECK (returned_qty > 0),
  qc_result VARCHAR(30) NOT NULL DEFAULT 'pending'
    CHECK (qc_result IN ('pending','accepted','damaged','rejected','partial')),
  accepted_qty NUMERIC(18,4) NOT NULL DEFAULT 0 CHECK (accepted_qty >= 0),
  damaged_qty NUMERIC(18,4) NOT NULL DEFAULT 0 CHECK (damaged_qty >= 0),
  rejected_qty NUMERIC(18,4) NOT NULL DEFAULT 0 CHECK (rejected_qty >= 0),
  remarks TEXT,
  CHECK (accepted_qty + damaged_qty + rejected_qty <= returned_qty)
);

ALTER TABLE return_items
  ADD COLUMN IF NOT EXISTS order_item_id UUID REFERENCES order_items(id),
  ADD COLUMN IF NOT EXISTS remarks TEXT,
  ADD COLUMN IF NOT EXISTS qc_by UUID REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS qc_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS rejected_by UUID REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

CREATE INDEX IF NOT EXISTS idx_returns_company_created ON returns(company_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_returns_company_status ON returns(company_id, status);
CREATE INDEX IF NOT EXISTS idx_returns_warehouse ON returns(company_id, warehouse_id);
CREATE INDEX IF NOT EXISTS idx_return_items_return ON return_items(return_id);
CREATE INDEX IF NOT EXISTS idx_return_items_order_item ON return_items(order_item_id);

CREATE TABLE IF NOT EXISTS invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  client_id UUID NOT NULL REFERENCES clients(id),
  order_id UUID REFERENCES orders(id),
  dispatch_id UUID REFERENCES dispatch(id),
  invoice_no VARCHAR(80) NOT NULL,
  invoice_date DATE NOT NULL DEFAULT CURRENT_DATE,
  status VARCHAR(20) NOT NULL DEFAULT 'issued'
    CHECK (status IN ('draft','issued','cancelled')),
  taxable_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  discount_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  cgst_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  sgst_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  igst_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  total_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  payment_terms TEXT,
  due_date DATE,
  company_name_snapshot VARCHAR(200),
  company_logo_url_snapshot TEXT,
  company_address_snapshot TEXT,
  company_gstin_snapshot VARCHAR(20),
  company_email_snapshot VARCHAR(200),
  company_mobile_snapshot VARCHAR(30),
  client_name_snapshot VARCHAR(200),
  client_address_snapshot TEXT,
  client_gstin_snapshot VARCHAR(20),
  client_email_snapshot VARCHAR(200),
  client_mobile_snapshot VARCHAR(30),
  pdf_path TEXT,
  pdf_generated_at TIMESTAMPTZ,
  email_status VARCHAR(20) NOT NULL DEFAULT 'not_sent'
    CHECK (email_status IN ('not_sent','queued','sent','failed')),
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, invoice_no)
);

ALTER TABLE invoices
  ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'issued',
  ADD COLUMN IF NOT EXISTS discount_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS payment_terms TEXT,
  ADD COLUMN IF NOT EXISTS due_date DATE,
  ADD COLUMN IF NOT EXISTS company_name_snapshot VARCHAR(200),
  ADD COLUMN IF NOT EXISTS company_logo_url_snapshot TEXT,
  ADD COLUMN IF NOT EXISTS company_address_snapshot TEXT,
  ADD COLUMN IF NOT EXISTS company_gstin_snapshot VARCHAR(20),
  ADD COLUMN IF NOT EXISTS company_email_snapshot VARCHAR(200),
  ADD COLUMN IF NOT EXISTS company_mobile_snapshot VARCHAR(30),
  ADD COLUMN IF NOT EXISTS client_name_snapshot VARCHAR(200),
  ADD COLUMN IF NOT EXISTS client_address_snapshot TEXT,
  ADD COLUMN IF NOT EXISTS client_gstin_snapshot VARCHAR(20),
  ADD COLUMN IF NOT EXISTS client_email_snapshot VARCHAR(200),
  ADD COLUMN IF NOT EXISTS client_mobile_snapshot VARCHAR(30),
  ADD COLUMN IF NOT EXISTS pdf_generated_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS email_status VARCHAR(20) NOT NULL DEFAULT 'not_sent',
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE invoices DROP CONSTRAINT IF EXISTS invoices_status_check;
ALTER TABLE invoices ADD CONSTRAINT invoices_status_check
  CHECK (status IN ('draft','issued','cancelled'));

ALTER TABLE invoices DROP CONSTRAINT IF EXISTS invoices_email_status_check;
ALTER TABLE invoices ADD CONSTRAINT invoices_email_status_check
  CHECK (email_status IN ('not_sent','queued','sent','failed'));

ALTER TABLE invoice_items
  ADD COLUMN IF NOT EXISTS uom VARCHAR(30),
  ADD COLUMN IF NOT EXISTS discount_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS taxable_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS cgst_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS sgst_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS igst_amount NUMERIC(18,2) NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_invoices_company_date
  ON invoices(company_id, invoice_date DESC);
CREATE INDEX IF NOT EXISTS idx_invoices_company_client_date
  ON invoices(company_id, client_id, invoice_date DESC);
CREATE INDEX IF NOT EXISTS idx_invoices_order
  ON invoices(company_id, order_id);
CREATE INDEX IF NOT EXISTS idx_invoices_dispatch
  ON invoices(company_id, dispatch_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_invoices_active_order
  ON invoices(company_id, order_id)
  WHERE order_id IS NOT NULL AND status <> 'cancelled';

ALTER TABLE returns DROP CONSTRAINT IF EXISTS returns_invoice_id_fkey;
ALTER TABLE returns ADD CONSTRAINT returns_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES invoices(id);


CREATE TABLE IF NOT EXISTS invoice_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  description TEXT NOT NULL,
  hsn_code VARCHAR(30),
  uom VARCHAR(30),
  quantity NUMERIC(18,4) NOT NULL DEFAULT 0,
  weight NUMERIC(18,4) NOT NULL DEFAULT 0,
  rate NUMERIC(18,4) NOT NULL DEFAULT 0,
  discount_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  taxable_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  cgst_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  sgst_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  igst_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  line_total NUMERIC(18,2) NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id),
  user_id UUID REFERENCES users(id),
  action VARCHAR(100) NOT NULL,
  entity_type VARCHAR(80),
  entity_id UUID,
  ip_address INET,
  user_agent TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_company ON users(company_id);
CREATE INDEX IF NOT EXISTS idx_clients_company ON clients(company_id);
CREATE INDEX IF NOT EXISTS idx_products_company_sku ON products(company_id, sku);
CREATE INDEX IF NOT EXISTS idx_warehouses_company ON warehouses(company_id);
CREATE INDEX IF NOT EXISTS idx_warehouses_company_active ON warehouses(company_id, is_active);
CREATE INDEX IF NOT EXISTS idx_warehouse_locations_warehouse ON warehouse_locations(warehouse_id);
CREATE INDEX IF NOT EXISTS idx_warehouse_locations_warehouse_active ON warehouse_locations(warehouse_id, is_active);
CREATE INDEX IF NOT EXISTS idx_inventory_company_product ON inventory(company_id, product_id);
CREATE INDEX IF NOT EXISTS idx_grns_company_created ON grns(company_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_company_created ON orders(company_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_company_client ON orders(company_id, client_id);
CREATE INDEX IF NOT EXISTS idx_dispatch_company_created ON dispatch(company_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_invoices_company_created ON invoices(company_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_company_created ON audit_logs(company_id, created_at DESC);

-- ============================================================
-- STOCK TRANSFER ORDER (STO)
-- ============================================================

CREATE TABLE IF NOT EXISTS stock_transfer_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  sto_no VARCHAR(60) NOT NULL,
  source_warehouse_id UUID NOT NULL REFERENCES warehouses(id),
  destination_warehouse_id UUID NOT NULL REFERENCES warehouses(id),
  status VARCHAR(30) NOT NULL DEFAULT 'draft'
    CHECK (status IN (
      'draft',
      'pending_approval',
      'approved',
      'picking',
      'in_transit',
      'partially_received',
      'received',
      'rejected',
      'cancelled'
    )),
  remarks TEXT,
  requested_by UUID REFERENCES users(id),
  approved_by UUID REFERENCES users(id),
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, sto_no),
  CHECK (source_warehouse_id <> destination_warehouse_id)
);

CREATE TABLE IF NOT EXISTS stock_transfer_order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sto_id UUID NOT NULL REFERENCES stock_transfer_orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  requested_qty NUMERIC(18,4) NOT NULL CHECK (requested_qty > 0),
  picked_qty NUMERIC(18,4) NOT NULL DEFAULT 0 CHECK (picked_qty >= 0),
  transferred_qty NUMERIC(18,4) NOT NULL DEFAULT 0 CHECK (transferred_qty >= 0),
  received_qty NUMERIC(18,4) NOT NULL DEFAULT 0 CHECK (received_qty >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS stock_transfer_pickings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sto_id UUID NOT NULL REFERENCES stock_transfer_orders(id) ON DELETE CASCADE,
  sto_item_id UUID NOT NULL REFERENCES stock_transfer_order_items(id) ON DELETE CASCADE,
  source_location_id UUID REFERENCES warehouse_locations(id),
  picked_qty NUMERIC(18,4) NOT NULL CHECK (picked_qty > 0),
  status VARCHAR(20) NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','picked','cancelled')),
  picked_by UUID REFERENCES users(id),
  picked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS stock_transfer_receipts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sto_id UUID NOT NULL REFERENCES stock_transfer_orders(id) ON DELETE CASCADE,
  sto_item_id UUID NOT NULL REFERENCES stock_transfer_order_items(id) ON DELETE CASCADE,
  destination_location_id UUID REFERENCES warehouse_locations(id),
  received_qty NUMERIC(18,4) NOT NULL CHECK (received_qty > 0),
  status VARCHAR(20) NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','received','rejected')),
  received_by UUID REFERENCES users(id),
  received_at TIMESTAMPTZ,
  remarks TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Existing inventory_transactions table is also used for STO movement.
-- These fields preserve both sides of the transfer for complete traceability.
ALTER TABLE inventory_transactions
  ADD COLUMN IF NOT EXISTS source_warehouse_id UUID REFERENCES warehouses(id),
  ADD COLUMN IF NOT EXISTS destination_warehouse_id UUID REFERENCES warehouses(id),
  ADD COLUMN IF NOT EXISTS source_location_id UUID REFERENCES warehouse_locations(id),
  ADD COLUMN IF NOT EXISTS destination_location_id UUID REFERENCES warehouse_locations(id);

CREATE INDEX IF NOT EXISTS idx_sto_company_created
  ON stock_transfer_orders(company_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_sto_company_status
  ON stock_transfer_orders(company_id, status);

CREATE INDEX IF NOT EXISTS idx_sto_source_warehouse
  ON stock_transfer_orders(company_id, source_warehouse_id);

CREATE INDEX IF NOT EXISTS idx_sto_destination_warehouse
  ON stock_transfer_orders(company_id, destination_warehouse_id);

CREATE INDEX IF NOT EXISTS idx_sto_items_sto
  ON stock_transfer_order_items(sto_id);

CREATE INDEX IF NOT EXISTS idx_sto_pickings_sto
  ON stock_transfer_pickings(sto_id);

CREATE INDEX IF NOT EXISTS idx_sto_receipts_sto
  ON stock_transfer_receipts(sto_id);

CREATE INDEX IF NOT EXISTS idx_inventory_txn_sto
  ON inventory_transactions(company_id, reference_type, reference_id);

CREATE INDEX IF NOT EXISTS idx_inventory_txn_source_destination
  ON inventory_transactions(company_id, source_warehouse_id, destination_warehouse_id);



-- ============================================================
-- RBAC permission seed
-- ============================================================

INSERT INTO permissions (permission_key, description) VALUES
  ('device.read', 'View device authentication records'),
  ('device.approve', 'Approve, reject, or revoke devices'),
  ('company.read', 'View company records'),
  ('company.manage', 'Manage own company profile'),
  ('user.read', 'View users and roles'),
  ('user.manage', 'Create or manage users and roles'),
  ('system.manage', 'Manage technical system settings'),
  ('security.audit.read', 'View security and audit records'),

  ('inbound.read', 'View inbound receipts'),
  ('inbound.create', 'Create inbound receipts'),
  ('grn.read', 'View GRNs'),
  ('grn.create', 'Create GRNs'),
  ('qc.read', 'View quality control records'),
  ('qc.manage', 'Process quality control records'),
  ('putaway.read', 'View putaway tasks'),
  ('putaway.manage', 'Process putaway tasks'),
  ('product.read', 'View products'),
  ('product.manage', 'Create or manage products'),
  ('warehouse.read', 'View warehouses and locations'),
  ('warehouse.manage', 'Create or manage warehouses and locations'),
  ('inventory.read', 'View inventory'),
  ('stock_transfer.read', 'View stock transfer orders'),
  ('stock_transfer.manage', 'Create and manage stock transfer orders'),
  ('stock_transfer.approve', 'Approve stock transfer orders'),
  ('stock_transfer.pick', 'Pick stock transfer orders'),
  ('stock_transfer.receive', 'Receive stock transfer orders'),
  ('inventory.manage', 'Adjust or manage inventory'),
  ('order.read', 'View orders'),
  ('order.create', 'Create orders'),
  ('order.manage', 'Manage order status'),
  ('picking.read', 'View picking tasks'),
  ('picking.manage', 'Process picking tasks'),
  ('packing.read', 'View packing tasks'),
  ('packing.manage', 'Process packing tasks'),
  ('dispatch.read', 'View dispatch records'),
  ('dispatch.manage', 'Process dispatch records'),
  ('return.read', 'View returns'),
  ('return.create', 'Create return requests'),
  ('return.manage', 'Manage returns'),
  ('invoice.read', 'View invoices'),
  ('invoice.create', 'Create invoices'),
  ('invoice.manage', 'Manage invoices'),
  ('report.read', 'View operational reports'),
  ('client.read', 'View clients'),
  ('client.manage', 'Manage clients'),
  ('profile.read', 'View own profile'),
  ('profile.update', 'Update own profile')
ON CONFLICT (permission_key) DO UPDATE
SET description = EXCLUDED.description;

INSERT INTO role_permissions (role, permission_id)
SELECT 'master_admin', p.id
FROM permissions p
WHERE p.permission_key IN (
  'device.read',
  'device.approve',
  'company.read',
  'company.manage',
  'user.read',
  'user.manage',
  'system.manage',
  'security.audit.read'
)
ON CONFLICT (role, permission_id) DO NOTHING;

INSERT INTO role_permissions (role, permission_id)
SELECT 'admin', p.id
FROM permissions p
WHERE p.permission_key IN (
  'company.read',
  'user.read',
  'user.manage',
  'inbound.read',
  'inbound.create',
  'grn.read',
  'grn.create',
  'qc.read',
  'qc.manage',
  'putaway.read',
  'putaway.manage',
  'product.read',
  'product.manage',
  'warehouse.read',
  'warehouse.manage',
  'inventory.read',
  'inventory.manage',
  'stock_transfer.read','stock_transfer.manage','stock_transfer.approve','stock_transfer.pick','stock_transfer.receive',
  'order.read',
  'order.create',
  'order.manage',
  'picking.read',
  'picking.manage',
  'packing.read',
  'packing.manage',
  'dispatch.read',
  'dispatch.manage',
  'return.read',
  'return.manage',
  'invoice.read',
  'invoice.create',
  'invoice.manage',
  'report.read',
  'client.read',
  'client.manage',
  'profile.read',
  'profile.update'
)
ON CONFLICT (role, permission_id) DO NOTHING;

INSERT INTO role_permissions (role, permission_id)
SELECT r.role, p.id
FROM (VALUES
 ('warehouse_manager'),('warehouse_supervisor'),('warehouse_operator')
) AS r(role)
CROSS JOIN permissions p
WHERE p.permission_key IN ('packing.read')
ON CONFLICT (role, permission_id) DO NOTHING;

INSERT INTO role_permissions (role, permission_id)
SELECT r.role, p.id
FROM (VALUES
 ('warehouse_manager'),('warehouse_supervisor'),('warehouse_operator')
) AS r(role)
CROSS JOIN permissions p
WHERE p.permission_key = 'packing.manage'
ON CONFLICT (role, permission_id) DO NOTHING;

INSERT INTO role_permissions (role, permission_id)
SELECT r.role, p.id
FROM (VALUES
 ('warehouse_manager'),('warehouse_supervisor'),('warehouse_operator'),
 ('warehouse_qc'),('gate_operator'),('inventory_user'),('dispatch_user')
) AS r(role)
CROSS JOIN permissions p
WHERE p.permission_key IN (
 'profile.read','profile.update','warehouse.read','product.read','inbound.read',
 'grn.read','qc.read','putaway.read','inventory.read','order.read','picking.read',
 'packing.read','dispatch.read','invoice.read','invoice.create','return.read','report.read'
)
ON CONFLICT (role, permission_id) DO NOTHING;

INSERT INTO role_permissions (role, permission_id)
SELECT r.role, p.id
FROM (VALUES
 ('warehouse_manager'),('warehouse_supervisor'),('warehouse_operator'),
 ('warehouse_qc'),('gate_operator'),('inventory_user')
) AS r(role)
CROSS JOIN permissions p
WHERE p.permission_key = 'return.manage'
ON CONFLICT (role, permission_id) DO NOTHING;

INSERT INTO role_permissions (role, permission_id)
SELECT r.role, p.id
FROM (VALUES
 ('warehouse_manager'),('warehouse_supervisor'),('warehouse_operator'),
 ('warehouse_qc'),('gate_operator'),('inventory_user'),('dispatch_user')
) AS r(role)
CROSS JOIN permissions p
WHERE p.permission_key = CASE r.role
 WHEN 'warehouse_manager' THEN 'warehouse.manage'
 WHEN 'warehouse_supervisor' THEN 'inbound.create'
 WHEN 'warehouse_operator' THEN 'putaway.manage'
 WHEN 'warehouse_qc' THEN 'qc.manage'
 WHEN 'gate_operator' THEN 'inbound.create'
 WHEN 'inventory_user' THEN 'inventory.manage'
 WHEN 'dispatch_user' THEN 'dispatch.manage'
END
ON CONFLICT (role, permission_id) DO NOTHING;

INSERT INTO role_permissions (role, permission_id)
SELECT r.role, p.id
FROM (VALUES
 ('warehouse_manager','stock_transfer.manage'),
 ('warehouse_manager','stock_transfer.approve'),
 ('warehouse_supervisor','stock_transfer.pick'),
 ('inventory_user','stock_transfer.receive')
) AS r(role, permission_key)
JOIN permissions p ON p.permission_key=r.permission_key
ON CONFLICT (role, permission_id) DO NOTHING;

INSERT INTO role_permissions (role, permission_id)
SELECT 'client', p.id
FROM permissions p
WHERE p.permission_key IN (
  'product.read',
  'order.read',
  'order.create',
  'dispatch.read',
  'return.read',
  'return.create',
  'invoice.read',
  'profile.read',
  'profile.update'
)
ON CONFLICT (role, permission_id) DO NOTHING;

