const router = require('express').Router();
const { z } = require('zod');
const pool = require('../config/db');
const { requireAuth } = require('../middleware/auth');
const { requireApprovedDevice } = require('../middleware/device');
const { requirePermission } = require('../middleware/permission');
const { requireTenantContext } = require('../middleware/tenant');
const { getAssignedWarehouseIds } = require('../middleware/warehouse_access');

router.use(requireAuth, requireApprovedDevice, requireTenantContext);

function warehouseFilter(assigned, params, column = 'i.warehouse_id') {
  if (!assigned.length) return '';
  params.push(assigned);
  return ` AND ${column} = ANY($${params.length}::uuid[])`;
}

router.get('/', requirePermission('inventory.read'), async (req,res,next)=>{
  try {
    const assigned=await getAssignedWarehouseIds(req.user.sub,req.tenant.companyId);
    const params=[req.tenant.companyId];
    let wh=warehouseFilter(assigned,params);
    if(req.query.warehouseId) {
      const id=z.string().uuid().parse(req.query.warehouseId.toString());
      params.push(id); wh += ` AND i.warehouse_id=$${params.length}`;
    }
    if(req.query.productId) {
      const id=z.string().uuid().parse(req.query.productId.toString());
      params.push(id); wh += ` AND i.product_id=$${params.length}`;
    }
    const r=await pool.query(`
      SELECT i.id,i.product_id,p.sku,p.name product_name,p.uom,
             i.warehouse_id,w.code warehouse_code,w.name warehouse_name,
             i.location_id,wl.code location_code,wl.zone,wl.bin,
             i.quantity,i.reserved_quantity,i.damaged_quantity,
             GREATEST(i.quantity-i.reserved_quantity,0) available_quantity,
             i.updated_at
      FROM inventory i
      JOIN products p ON p.id=i.product_id
      JOIN warehouses w ON w.id=i.warehouse_id
      LEFT JOIN warehouse_locations wl ON wl.id=i.location_id
      WHERE i.company_id=$1 ${wh}
      ORDER BY w.code,p.sku,wl.code NULLS LAST
      LIMIT 500`,params);
    return res.json({data:r.rows});
  } catch(e) { if(e.name==='ZodError') return res.status(400).json({error:{code:'VALIDATION_ERROR',message:'Invalid inventory filter.'}}); return next(e); }
});

router.get('/transactions', requirePermission('inventory.read'), async (req,res,next)=>{
  try {
    const assigned=await getAssignedWarehouseIds(req.user.sub,req.tenant.companyId);
    const params=[req.tenant.companyId];
    let wh=warehouseFilter(assigned,params,'t.warehouse_id');
    if(req.query.warehouseId){ const id=z.string().uuid().parse(req.query.warehouseId.toString()); params.push(id); wh+=` AND t.warehouse_id=$${params.length}`; }
    const r=await pool.query(`
      SELECT t.*,p.sku,p.name product_name,w.code warehouse_code,wl.code location_code,u.full_name created_by_name
      FROM inventory_transactions t
      JOIN products p ON p.id=t.product_id
      LEFT JOIN warehouses w ON w.id=t.warehouse_id
      LEFT JOIN warehouse_locations wl ON wl.id=t.location_id
      LEFT JOIN users u ON u.id=t.created_by
      WHERE t.company_id=$1 ${wh}
      ORDER BY t.created_at DESC LIMIT 500`,params);
    return res.json({data:r.rows});
  } catch(e){ if(e.name==='ZodError')return res.status(400).json({error:{code:'VALIDATION_ERROR',message:'Invalid transaction filter.'}}); return next(e); }
});

const adjustSchema=z.object({
  productId:z.string().uuid(),
  warehouseId:z.string().uuid(),
  locationId:z.string().uuid().nullable().optional(),
  quantity:z.coerce.number(),
  remarks:z.string().trim().max(1000).optional(),
});

router.post('/adjust', requirePermission('inventory.manage'), async(req,res,next)=>{
  const db=await pool.connect();
  try{
    const input=adjustSchema.parse(req.body);
    if(input.quantity===0) return res.status(400).json({error:{code:'ZERO_ADJUSTMENT',message:'Adjustment quantity cannot be zero.'}});
    const assigned=await getAssignedWarehouseIds(req.user.sub,req.tenant.companyId);
    if(assigned.length&&!assigned.includes(input.warehouseId)) return res.status(403).json({error:{code:'WAREHOUSE_ACCESS_DENIED',message:'You are not assigned to this warehouse.'}});
    await db.query('BEGIN');
    const wh=await db.query('SELECT id FROM warehouses WHERE id=$1 AND company_id=$2 AND is_active=TRUE FOR UPDATE',[input.warehouseId,req.tenant.companyId]);
    if(!wh.rowCount) return res.status(400).json({error:{code:'INVALID_WAREHOUSE',message:'Warehouse is invalid.'}});
    const p=await db.query('SELECT id FROM products WHERE id=$1 AND company_id=$2 AND is_active=TRUE',[input.productId,req.tenant.companyId]);
    if(!p.rowCount) return res.status(400).json({error:{code:'INVALID_PRODUCT',message:'Product is invalid.'}});
    if(input.locationId){
      const loc=await db.query('SELECT id FROM warehouse_locations WHERE id=$1 AND warehouse_id=$2 AND is_active=TRUE',[input.locationId,input.warehouseId]);
      if(!loc.rowCount)return res.status(400).json({error:{code:'INVALID_LOCATION',message:'Location is invalid.'}});
    }
    const inv=await db.query(`SELECT id,quantity,reserved_quantity FROM inventory WHERE company_id=$1 AND product_id=$2 AND warehouse_id=$3 AND location_id IS NOT DISTINCT FROM $4::uuid FOR UPDATE`,[req.tenant.companyId,input.productId,input.warehouseId,input.locationId||null]);
    const current=inv.rowCount?Number(inv.rows[0].quantity):0;
    const reserved=inv.rowCount?Number(inv.rows[0].reserved_quantity):0;
    const next=current+input.quantity;
    if(next<0 || next<reserved) return res.status(400).json({error:{code:'INSUFFICIENT_STOCK',message:'Adjustment would make stock lower than reserved quantity.'}});
    let inventoryId;
    if(inv.rowCount){ await db.query('UPDATE inventory SET quantity=$1,updated_at=NOW() WHERE id=$2',[next,inv.rows[0].id]); inventoryId=inv.rows[0].id; }
    else { const x=await db.query('INSERT INTO inventory(company_id,product_id,warehouse_id,location_id,quantity) VALUES($1,$2,$3,$4,$5) RETURNING id',[req.tenant.companyId,input.productId,input.warehouseId,input.locationId||null,next]); inventoryId=x.rows[0].id; }
    const tx=await db.query(`INSERT INTO inventory_transactions(company_id,product_id,warehouse_id,location_id,transaction_type,quantity,reference_type,reference_id,created_by) VALUES($1,$2,$3,$4,'adjustment',$5,'manual_adjustment',$6,$7) RETURNING *`,[req.tenant.companyId,input.productId,input.warehouseId,input.locationId||null,input.quantity,inventoryId,req.user.sub]);
    await db.query(`INSERT INTO audit_logs(company_id,user_id,action,entity_type,entity_id,metadata) VALUES($1,$2,'INVENTORY_ADJUSTED','inventory',$3,$4::jsonb)`,[req.tenant.companyId,req.user.sub,inventoryId,JSON.stringify({quantity:input.quantity,remarks:input.remarks||null,warehouseId:input.warehouseId,locationId:input.locationId||null})]);
    await db.query('COMMIT');
    return res.status(201).json({data:{inventoryId,transaction:tx.rows[0]}});
  }catch(e){await db.query('ROLLBACK').catch(()=>{});if(e.name==='ZodError')return res.status(400).json({error:{code:'VALIDATION_ERROR',message:'Invalid inventory adjustment.'}});return next(e);}
  finally{db.release();}
});
module.exports=router;