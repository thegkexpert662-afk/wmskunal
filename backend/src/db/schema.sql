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
  username VARCHAR(100) NOT NULL UNIQUE,
  email VARCHAR(200) UNIQUE,
  password_hash TEXT NOT NULL,
  full_name VARCHAR(150) NOT NULL,
  role VARCHAR(30) NOT NULL CHECK (role IN ('master_admin','admin','client')),
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

CREATE TABLE IF NOT EXISTS putaway_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  grn_item_id UUID NOT NULL REFERENCES grn_items(id),
  location_id UUID REFERENCES warehouse_locations(id),
  quantity NUMERIC(18,4) NOT NULL CHECK (quantity >= 0),
  status VARCHAR(30) NOT NULL DEFAULT 'pending',
  processed_by UUID REFERENCES users(id),
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  product_id UUID NOT NULL REFERENCES products(id),
  warehouse_id UUID NOT NULL REFERENCES warehouses(id),
  location_id UUID REFERENCES warehouse_locations(id),
  quantity NUMERIC(18,4) NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  reserved_quantity NUMERIC(18,4) NOT NULL DEFAULT 0 CHECK (reserved_quantity >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, product_id, warehouse_id, location_id)
);

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

CREATE TABLE IF NOT EXISTS packing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  order_id UUID NOT NULL REFERENCES orders(id),
  status VARCHAR(30) NOT NULL DEFAULT 'pending',
  packed_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS dispatch (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  order_id UUID NOT NULL REFERENCES orders(id),
  dispatch_no VARCHAR(60) NOT NULL,
  vehicle_no VARCHAR(50),
  lr_no VARCHAR(100),
  status VARCHAR(30) NOT NULL DEFAULT 'pending',
  dispatched_at TIMESTAMPTZ,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, dispatch_no)
);

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
  return_no VARCHAR(60) NOT NULL,
  reason TEXT,
  status VARCHAR(30) NOT NULL DEFAULT 'requested',
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  UNIQUE (company_id, return_no)
);

CREATE TABLE IF NOT EXISTS return_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  return_id UUID NOT NULL REFERENCES returns(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  returned_qty NUMERIC(18,4) NOT NULL CHECK (returned_qty > 0),
  qc_result VARCHAR(30),
  accepted_qty NUMERIC(18,4) NOT NULL DEFAULT 0,
  damaged_qty NUMERIC(18,4) NOT NULL DEFAULT 0,
  rejected_qty NUMERIC(18,4) NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  client_id UUID NOT NULL REFERENCES clients(id),
  order_id UUID REFERENCES orders(id),
  dispatch_id UUID REFERENCES dispatch(id),
  invoice_no VARCHAR(80) NOT NULL,
  invoice_date DATE NOT NULL DEFAULT CURRENT_DATE,
  taxable_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  cgst_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  sgst_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  igst_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  total_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
  pdf_path TEXT,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (company_id, invoice_no)
);

CREATE TABLE IF NOT EXISTS invoice_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  description TEXT NOT NULL,
  hsn_code VARCHAR(30),
  quantity NUMERIC(18,4) NOT NULL DEFAULT 0,
  weight NUMERIC(18,4) NOT NULL DEFAULT 0,
  rate NUMERIC(18,4) NOT NULL DEFAULT 0,
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

