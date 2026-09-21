-- Kopersay WMS: STO migration
-- Safe to run against the existing kopersay_wms database.
-- Existing tables/data are preserved.

CREATE TABLE IF NOT EXISTS stock_transfer_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id),
  sto_no VARCHAR(60) NOT NULL,
  source_warehouse_id UUID NOT NULL REFERENCES warehouses(id),
  destination_warehouse_id UUID NOT NULL REFERENCES warehouses(id),
  status VARCHAR(30) NOT NULL DEFAULT 'draft'
    CHECK (status IN (
      'draft','pending_approval','approved','picking',
      'in_transit','partially_received','received','rejected','cancelled'
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
