export interface CustomerDetailTransactionItemDto {
  id: string;
  number: string;
  title: string;
  status: string;
  amount: number;
  date: string | null;
}

export interface CustomerDetailTransactionGroupDto {
  key: string;
  label: string;
  count: number;
  items: CustomerDetailTransactionItemDto[];
}

export interface CustomerDetailActivityDto {
  id: string;
  actor: string;
  action: string;
  description: string;
  createdAt: string | null;
}

export interface CustomerDetailMailDto {
  id: string;
  to: string;
  subject: string;
  status: string;
  sentAt: string | null;
}

export interface CustomerDetailCommentDto {
  id: string;
  author: string;
  body: string;
  createdAt: string | null;
}

export interface CustomerStatementEntryDto {
  id: string;
  date: string | null;
  type: string;
  number: string;
  reference: string | null;
  status: string | null;
  debit: number;
  credit: number;
  balance: number;
}

export interface CustomerDetailContextDto {
  transactions: CustomerDetailTransactionGroupDto[];
  activities: CustomerDetailActivityDto[];
  comments: CustomerDetailCommentDto[];
  mails: CustomerDetailMailDto[];
  statementEntries: CustomerStatementEntryDto[];
}
