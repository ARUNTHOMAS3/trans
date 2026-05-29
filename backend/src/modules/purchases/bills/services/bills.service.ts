import { Injectable, HttpException, HttpStatus } from "@nestjs/common";
import { SupabaseService } from "../../../supabase/supabase.service";
import { v4 as uuidv4 } from "uuid";

@Injectable()
export class BillsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async createBill(entityId: string, dto: any) {
    const supabase = this.supabaseService.getClient();
    
    // 1. Create Bill
    const billId = uuidv4();
    
    const { data: billData, error: billError } = await supabase
      .from('bills')
      .insert({
        id: billId,
        entity_id: entityId,
        vendor_id: dto.vendorId,
        bill_number: dto.billNumber || `BILL-${Date.now()}`,
        order_number: dto.orderNumber,
        bill_date: dto.billDate,
        due_date: dto.dueDate,
        payment_term_id: dto.paymentTerms,
        reverse_charge_applicable: dto.isReverseCharge,
        warehouse_id: dto.warehouseId,
        price_list_id: dto.priceListId,
        subject: dto.subject,
        notes: dto.notes,
        subtotal: dto.subTotal?.toString(),
        discount_total: dto.discountAmount?.toString(),
        tax_total: dto.taxAmount?.toString(),
        adjustment_amount: dto.adjustment?.toString(),
        grand_total: dto.total?.toString(),
        status: dto.status || "draft",
      })
      .select()
      .single();

    if (billError) {
      throw new HttpException(`Failed to create bill: ${billError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
    }

    // 2. Create Items
    if (dto.lineItems && dto.lineItems.length > 0) {
      const itemsToInsert = dto.lineItems.map(item => ({
        id: uuidv4(),
        bill_id: billId,
        product_id: item.item_id,
        account_id: item.account_id,
        customer_id: item.customer_id,
        description: item.description,
        quantity: item.quantity?.toString() || "0",
        rate: item.rate?.toString() || "0",
        discount_type: item.discount_type,
        discount_amount: item.discount?.toString() || "0",
        tax_id: item.tax_id,
        tax_amount: item.tax_amount?.toString() || "0",
        line_total: item.amount?.toString() || "0",
      }));

      const { data: itemsData, error: itemsError } = await supabase
        .from('bill_items')
        .insert(itemsToInsert)
        .select();

      if (itemsError) {
        throw new HttpException(`Failed to create bill items: ${itemsError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
      }

      // 3. Create Batches (If provided)
      const batchesToInsert = [];
      for (let i = 0; i < dto.lineItems.length; i++) {
        const item = dto.lineItems[i];
        const insertedItem = itemsData[i];
        
        if (item.batches && item.batches.length > 0) {
          for (const batch of item.batches) {
            batchesToInsert.push({
              id: uuidv4(),
              bill_item_id: insertedItem.id,
              batch_id: batch.batchId || uuidv4(),
              quantity: batch.quantity?.toString(),
            });
          }
        }
      }

      if (batchesToInsert.length > 0) {
        const { error: batchError } = await supabase
          .from('bill_item_batches')
          .insert(batchesToInsert);
          
        if (batchError) {
          throw new HttpException(`Failed to create item batches: ${batchError.message}`, HttpStatus.INTERNAL_SERVER_ERROR);
        }
      }
    }
    
    return { message: "Bill created successfully", data: billData };
  }
}
