const router = require('express').Router();
const { z } = require('zod');
const pool = require('../config/db');
const { requireAuth } = require('../middleware/auth');
const { requireApprovedDevice } = require('../middleware/device');
const { requirePermission } = require('../middleware/permission');
const { requireTenantContext } = require('../middleware/tenant');
const { getAssignedWarehouseIds } = require('../middleware/warehouse_access');

const sourceSchema=z.object({
  sourceType:z.enum(['grn','production']),
  sourceItemId:z.string().uuid(),
  quantity:z.coerce.number().positive(),
  locationId:z.string().uuid(),
});
const processSchema=z.object({locationId:z.string().uuid()});

function scope(assigned, params){ return assigned.length ? ' AND w.id = ANY($'+(params.length+1)+'::uuid[])' : ''; }

router.get('/pending',requireAuth,requireApprovedDevice,requireTenantContext,requirePermission('putaway.read'),async(req,res,next)=>{
  try{
    const assigned=await getAssignedWarehouseIds(req.user.sub,req.tenant.companyId);
    const params=[req.tenant.companyId];
    const wh=scope(assigned,params); if(assigned.length) params.push(assigned);
    const r=await pool.query(
      `SELECT 'grn' source_type, gi.id source_item_id, g.id source_id, g.grn_no reference_no,
              p.id product_id,p.sku,p.name product_name,gi.received_qty,
              COALESCE(q.accepted_qty,0) accepted_qty,
              COALESCE((SELECT SUM(pt.quantity) FROM putaway_tasks pt WHERE pt.grn_item_id=gi.id AND pt.status<>'cancelled'),0) putaway_qty,
              w.id warehouse_id,w.code warehouse_code,w.name warehouse_name
       FROM grn_items gi JOIN grns g ON g.id=gi.grn_id JOIN products p ON p.id=gi.product_id
       JOIN warehouses w ON w.id=g.warehouse_id
       LEFT JOIN LATERAL (SELECT SUM(qr.accepted_qty) accepted_qty FROM qc_records qr WHERE qr.grn_item_id=gi.id AND qr.result IN ('approved','partial')) q ON TRUE
       WHERE g.company_id=$1 AND gi.qc_status IN ('approved','partial') ${wh}
       UNION ALL
       SELECT 'production', pri.id, pr.id, pr.receipt_no,
              p.id,p.sku,p.name,pri.received_qty,
              COALESCE(q.accepted_qty,0),
              COALESCE((SELECT SUM(pt.quantity) FROM putaway_tasks pt WHERE pt.production_receipt_item_id=pri.id AND pt.status<>'cancelled'),0),
              w.id,w.code,w.name
       FROM production_receipt_items pri JOIN production_receipts pr ON pr.id=pri.receipt_id JOIN products p ON p.id=pri.product_id
       JOIN warehouses w ON w.id=pr.warehouse_id
       LEFT JOIN LATERAL (SELECT SUM(qr.accepted_qty) accepted_qty FROM qc_records qr WHERE qr.production_receipt_item_id=pri.id AND qr.result IN ('approved','partial')) q ON TRUE
       WHERE pr.company_id=$1 AND pri.qc_status IN ('approved','partial') ${wh}
       ORDER BY reference_no DESC`,params);
    return res.json({items:r.rows.filter(x=>Number(x.accepted_qty)>Number(x.putaway_qty))});
  }catch(e){return next(e);}
});

router.get('/',requireAuth,requireApprovedDevice,requireTenantContext,requirePermission('putaway.read'),async(req,res,next)=>{
  try{
    const assigned=await getAssignedWarehouseIds(req.user.sub,req.tenant.companyId);
    const params=[req.tenant.companyId]; let wh='';
    if(assigned.length){params.push(assigned);wh=' AND w.id=ANY($2::uuid[])';}
    const r=await pool.query(
      `SELECT pt.*, COALESCE(g.grn_no,pr.receipt_no) reference_no,
              COALESCE(p1.sku,p2.sku) sku,COALESCE(p1.name,p2.name) product_name,
              w.code warehouse_code,w.name warehouse_name,wl.code location_code,
              u.full_name processed_by_name
       FROM putaway_tasks pt
       LEFT JOIN grn_items gi ON gi.id=pt.grn_item_id
       LEFT JOIN grns g ON g.id=gi.grn_id
       LEFT JOIN production_receipt_items pri ON pri.id=pt.production_receipt_item_id
       LEFT JOIN production_receipts pr ON pr.id=pri.receipt_id
       LEFT JOIN products p1 ON p1.id=gi.product_id
       LEFT JOIN products p2 ON p2.id=pri.product_id
       JOIN warehouse_locations wl ON wl.id=pt.location_id
       JOIN warehouses w ON w.id=wl.warehouse_id
       LEFT JOIN users u ON u.id=pt.processed_by
       WHERE pt.company_id=$1 ${wh} ORDER BY pt.created_at DESC`,params);
    return res.json({tasks:r.rows});
  }catch(e){return next(e);}
});

router.post('/',requireAuth,requireApprovedDevice,requireTenantContext,requirePermission('putaway.manage'),async(req,res,next)=>{
  const db=await pool.connect();
  try{
    const input=sourceSchema.parse(req.body);
    const assigned=await getAssignedWarehouseIds(req.user.sub,req.tenant.companyId);
    await db.query('BEGIN');
    let item;
    if(input.sourceType==='grn'){
      const r=await db.query(`SELECT gi.id,gi.received_qty,gi.qc_status,g.warehouse_id FROM grn_items gi JOIN grns g ON g.id=gi.grn_id WHERE gi.id=$1 AND g.company_id=$2 FOR UPDATE`,[input.sourceItemId,req.tenant.companyId]);
      if(!r.rowCount) return res.status(404).json({error:{code:'SOURCE_NOT_FOUND',message:'GRN item not found.'}});
      item=r.rows[0];
    }else{
      const r=await db.query(`SELECT pri.id,pri.received_qty,pri.qc_status,pr.warehouse_id FROM production_receipt_items pri JOIN production_receipts pr ON pr.id=pri.receipt_id WHERE pri.id=$1 AND pr.company_id=$2 FOR UPDATE`,[input.sourceItemId,req.tenant.companyId]);
      if(!r.rowCount) return res.status(404).json({error:{code:'SOURCE_NOT_FOUND',message:'Production receipt item not found.'}});
      item=r.rows[0];
    }
    if(!['approved','partial'].includes(item.qc_status)) return res.status(400).json({error:{code:'QC_REQUIRED',message:'Only QC-approved material can be put away.'}});
    if(assigned.length && !assigned.includes(item.warehouse_id)) return res.status(403).json({error:{code:'WAREHOUSE_ACCESS_DENIED',message:'You are not assigned to this warehouse.'}});
    const loc=await db.query('SELECT id,warehouse_id,is_active FROM warehouse_locations WHERE id=$1 FOR UPDATE',[input.locationId]);
    if(!loc.rowCount||!loc.rows[0].is_active||loc.rows[0].warehouse_id!==item.warehouse_id) return res.status(400).json({error:{code:'INVALID_LOCATION',message:'Location is not active or does not belong to the source warehouse.'}});
    const accepted=await db.query(`SELECT COALESCE(SUM(q.accepted_qty),0) accepted FROM qc_records q WHERE ${input.sourceType==='grn'?'q.grn_item_id':'q.production_receipt_item_id'}=$1 AND q.result IN ('approved','partial')`,[input.sourceItemId]);
    const put=await db.query(`SELECT COALESCE(SUM(quantity),0) qty FROM putaway_tasks WHERE ${input.sourceType==='grn'?'grn_item_id':'production_receipt_item_id'}=$1 AND status<>'cancelled'`,[input.sourceItemId]);
    const remaining=Number(accepted.rows[0].accepted)-Number(put.rows[0].qty);
    if(input.quantity>remaining+0.000001) return res.status(400).json({error:{code:'PUTAWAY_QTY_EXCEEDED',message:'Putaway quantity exceeds QC accepted quantity.'}});
    const no='PUT-'+Date.now();
    const col=input.sourceType==='grn'?'grn_item_id':'production_receipt_item_id';
    const r=await db.query(`INSERT INTO putaway_tasks(company_id,putaway_no,${col},location_id,quantity,status) VALUES($1,$2,$3,$4,$5,'pending') RETURNING *`,[req.tenant.companyId,no,input.sourceItemId,input.locationId,input.quantity]);
    await db.query(`INSERT INTO audit_logs(company_id,user_id,action,entity_type,entity_id,metadata) VALUES($1,$2,'PUTAWAY_CREATED','putaway_task',$3,$4)`,[req.tenant.companyId,req.user.sub,r.rows[0].id,JSON.stringify({sourceType:input.sourceType,sourceItemId:input.sourceItemId,quantity:input.quantity})]);
    await db.query('COMMIT'); return res.status(201).json({task:r.rows[0]});
  }catch(e){await db.query('ROLLBACK').catch(()=>{});if(e.name==='ZodError')return res.status(400).json({error:{code:'VALIDATION_ERROR',message:'Invalid putaway request.'}});return next(e);}
  finally{db.release();}
});

router.post('/:id/process',requireAuth,requireApprovedDevice,requireTenantContext,requirePermission('putaway.manage'),async(req,res,next)=>{
  const db=await pool.connect();
  try{
    const input=processSchema.parse(req.body); await db.query('BEGIN');
    const r=await db.query(`SELECT pt.*,wl.warehouse_id,wl.is_active location_active,
      COALESCE(gi.product_id,pri.product_id) product_id
      FROM putaway_tasks pt
      JOIN warehouse_locations wl ON wl.id=pt.location_id
      LEFT JOIN grn_items gi ON gi.id=pt.grn_item_id
      LEFT JOIN production_receipt_items pri ON pri.id=pt.production_receipt_item_id
      WHERE pt.id=$1 AND pt.company_id=$2 FOR UPDATE`,[req.params.id,req.tenant.companyId]);
    if(!r.rowCount)return res.status(404).json({error:{code:'PUTAWAY_NOT_FOUND',message:'Putaway task not found.'}});
    const task=r.rows[0];
    const assigned=await getAssignedWarehouseIds(req.user.sub,req.tenant.companyId);
    if(assigned.length&&!assigned.includes(task.warehouse_id))return res.status(403).json({error:{code:'WAREHOUSE_ACCESS_DENIED',message:'You are not assigned to this warehouse.'}});
    if(!task.location_active)return res.status(400).json({error:{code:'INVALID_LOCATION',message:'Putaway location is inactive.'}});
    if(input.locationId!==task.location_id)return res.status(400).json({error:{code:'LOCATION_MISMATCH',message:'Selected location does not match the task location.'}});
    if(task.status==='completed')return res.status(400).json({error:{code:'ALREADY_COMPLETED',message:'Putaway is already completed.'}});
    await db.query('UPDATE putaway_tasks SET status=$1,processed_by=$2,processed_at=NOW() WHERE id=$3',['completed',req.user.sub,task.id]);
    const inv=await db.query(`SELECT id FROM inventory WHERE company_id=$1 AND product_id=$2 AND warehouse_id=$3 AND location_id=$4 FOR UPDATE`,[req.tenant.companyId,task.product_id,task.warehouse_id,task.location_id]);
    if(inv.rowCount) await db.query('UPDATE inventory SET quantity=quantity+$1,updated_at=NOW() WHERE id=$2',[task.quantity,inv.rows[0].id]);
    else await db.query('INSERT INTO inventory(company_id,product_id,warehouse_id,location_id,quantity) VALUES($1,$2,$3,$4,$5)',[req.tenant.companyId,task.product_id,task.warehouse_id,task.location_id,task.quantity]);
    await db.query(`INSERT INTO inventory_transactions(company_id,product_id,warehouse_id,location_id,transaction_type,quantity,reference_type,reference_id,created_by) VALUES($1,$2,$3,$4,'putaway',$5,'putaway_task',$6,$7)`,[req.tenant.companyId,task.product_id,task.warehouse_id,task.location_id,task.quantity,task.id,req.user.sub]);
    await db.query(`INSERT INTO audit_logs(company_id,user_id,action,entity_type,entity_id,metadata) VALUES($1,$2,'PUTAWAY_COMPLETED','putaway_task',$3,$4)`,[req.tenant.companyId,req.user.sub,task.id,JSON.stringify({quantity:task.quantity,locationId:task.location_id})]);
    await db.query('COMMIT'); return res.json({task:{...task,status:'completed'}});
  }catch(e){await db.query('ROLLBACK').catch(()=>{});if(e.name==='ZodError')return res.status(400).json({error:{code:'VALIDATION_ERROR',message:'Invalid process request.'}});return next(e);}
  finally{db.release();}
});

module.exports=router;
