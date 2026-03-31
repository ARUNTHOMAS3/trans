import { Injectable, Logger, NotFoundException } from "@nestjs/common";
import { db } from "../../../db/db";
import { inventoryPicklists, inventoryPicklistItems } from "../../../db/schema";
import { eq, desc } from "drizzle-orm";

@Injectable()
export class PicklistsService {
  private readonly logger = new Logger(PicklistsService.name);

  async findAll(page: number = 1, limit: number = 100, search?: string, status?: string) {
    const offset = (page - 1) * limit;
    
    const data = await db.query.inventoryPicklists.findMany({
      limit,
      offset,
      orderBy: [desc(inventoryPicklists.createdAt)],
    });

    const allRecords = await db.select().from(inventoryPicklists);
    const total = allRecords.length;

    return {
      data,
      meta: {
        total,
        page,
        limit,
      }
    };
  }

  async findOne(id: string) {
    const data = await db.query.inventoryPicklists.findFirst({
      where: eq(inventoryPicklists.id, id),
    });
    if (!data) throw new NotFoundException('Picklist not found');
    return data;
  }

  async create(createDto: any) {
    const newPicklist = await db.insert(inventoryPicklists).values({
      picklistNumber: createDto.picklist_number || `PL-${Date.now().toString().slice(-6)}`,
      date: createDto.date ? new Date(createDto.date) : new Date(),
      status: createDto.status || 'Yet to Start',
      assignee: createDto.assignee,
      location: createDto.location,
      notes: createDto.notes,
    }).returning();
    
    return newPicklist[0];
  }

  async update(id: string, updateDto: any) {
    const updated = await db.update(inventoryPicklists).set({
      status: updateDto.status,
      notes: updateDto.notes,
      assignee: updateDto.assignee,
      location: updateDto.location,
    }).where(eq(inventoryPicklists.id, id)).returning();

    if (!updated.length) throw new NotFoundException('Picklist not found');
    return updated[0];
  }

  async remove(id: string) {
    const deleted = await db.delete(inventoryPicklists).where(eq(inventoryPicklists.id, id)).returning();
    if (!deleted.length) throw new NotFoundException('Picklist not found');
    return deleted[0];
  }
}
