eate table public.bill_attachments (
  id uuid not null default gen_random_uuid (),
  bill_id uuid not null,
  file_name character varying(255) not null,
  original_file_name character varying(255) null,
  file_url text not null,
  file_type character varying(100) null,
  file_size bigint null,
  uploaded_by uuid null,
  remarks text null,
  created_at timestamp with time zone null default now(),
  constraint bill_attachments_pkey primary key (id),
  constraint fk_bill_attachments_bill foreign KEY (bill_id) references bills (id) on delete CASCADE
) TABLESPACE pg_default;

create trigger trg_audit_row
after INSERT
or DELETE
or
update on bill_attachments for EACH row
execute FUNCTION audit_row_changes ();

create trigger trg_audit_truncate
after
truncate on bill_attachments for EACH STATEMENT
execute FUNCTION audit_table_truncate ();
