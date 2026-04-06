-- Update products table to reference tax_groups for intra_state_tax_id
ALTER TABLE products DROP CONSTRAINT IF EXISTS products_intra_state_tax_id_associate_taxes_id_fk;
ALTER TABLE products ADD CONSTRAINT products_intra_state_tax_id_tax_groups_id_fk 
    FOREIGN KEY (intra_state_tax_id) REFERENCES tax_groups(id);
-- Inter-state remains referencing associate_taxes (IGST)
