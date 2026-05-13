import { Injectable } from "@nestjs/common";
import { Queue } from "bullmq";
import { BullMQAdapter } from "@bull-board/api/bullMQAdapter";

type QueueAdapter = BullMQAdapter;
type QueueSyncHandler = (queues: QueueAdapter[]) => void;

@Injectable()
export class BullBoardService {
  private readonly queueAdapters = new Map<string, QueueAdapter>();
  private syncHandler?: QueueSyncHandler;

  registerQueue(queue: Queue): Queue {
    const queueName = queue.name;

    if (!this.queueAdapters.has(queueName)) {
      this.queueAdapters.set(queueName, new BullMQAdapter(queue));
      this.syncQueues();
    }

    return queue;
  }

  attachSyncHandler(syncHandler: QueueSyncHandler): void {
    this.syncHandler = syncHandler;
    this.syncQueues();
  }

  getAdapters(): QueueAdapter[] {
    return Array.from(this.queueAdapters.values());
  }

  private syncQueues(): void {
    this.syncHandler?.(this.getAdapters());
  }
}
