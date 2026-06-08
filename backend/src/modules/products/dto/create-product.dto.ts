import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsBoolean,
  IsNumber,
  IsEnum,
  IsArray,
} from "class-validator";

export enum ProductType {
  GOODS = "goods",
  SERVICE = "service",
}

export enum TaxPreference {
  TAXABLE = "taxable",
  NON_TAXABLE = "non-taxable",
  EXEMPT = "exempt",
}

export enum InventoryValuationMethod {
  FIFO = "FIFO",
  LIFO = "LIFO",
  FEFO = "FEFO",
  WEIGHTED_AVERAGE = "Weighted Average",
  SPECIFIC_IDENTIFICATION = "Specific Identification",
}

export class CreateProductDto {
  // Basic Information
  @IsEnum(ProductType)
  @IsNotEmpty()
  type: ProductType;

  @IsString()
  @IsNotEmpty()
  product_name: string;

  @IsString()
  @IsOptional()
  billing_name?: string;

  @IsString()
  @IsNotEmpty()
  item_code: string;

  @IsString()
  @IsOptional()
  sku?: string;

  @IsString()
  @IsNotEmpty()
  unit_id: string;

  @IsString()
  @IsOptional()
  category_id?: string;

  @IsBoolean()
  @IsOptional()
  is_returnable?: boolean;

  @IsBoolean()
  @IsOptional()
  push_to_ecommerce?: boolean;

  // Tax & Regulatory
  @IsString()
  @IsOptional()
  hsn_code?: string;

  @IsEnum(TaxPreference)
  @IsOptional()
  tax_preference?: TaxPreference;

  @IsString()
  @IsOptional()
  intra_state_tax_id?: string;

  @IsString()
  @IsOptional()
  inter_state_tax_id?: string;

  @IsString()
  @IsOptional()
  primary_image_url?: string;

  @IsArray()
  @IsOptional()
  image_urls?: string[];

  // Tax Exemption
  @IsString()
  @IsOptional()
  exemption_reason?: string;

  // Sales Information
  @IsNumber()
  @IsOptional()
  selling_price?: number;

  @IsString()
  @IsOptional()
  selling_price_currency?: string;

  @IsNumber()
  @IsOptional()
  mrp?: number;

  @IsNumber()
  @IsOptional()
  ptr?: number;

  @IsString()
  @IsOptional()
  sales_account_id?: string;

  @IsString()
  @IsOptional()
  sales_description?: string;

  // Purchase Information
  @IsNumber()
  @IsOptional()
  cost_price?: number;

  @IsString()
  @IsOptional()
  cost_price_currency?: string;

  @IsString()
  @IsOptional()
  purchase_account_id?: string;

  @IsString()
  @IsOptional()
  rep_id?: string;

  @IsString()
  @IsOptional()
  preferred_vendor_id?: string;

  @IsString()
  @IsOptional()
  purchase_description?: string;

  // Formulation
  @IsNumber()
  @IsOptional()
  length?: number;

  @IsNumber()
  @IsOptional()
  width?: number;

  @IsNumber()
  @IsOptional()
  height?: number;

  @IsString()
  @IsOptional()
  dimension_unit?: string;

  @IsNumber()
  @IsOptional()
  weight?: number;

  @IsString()
  @IsOptional()
  weight_unit?: string;

  @IsString()
  @IsOptional()
  manufacturer_id?: string;

  @IsString()
  @IsOptional()
  brand_id?: string;

  @IsString()
  @IsOptional()
  unit_pack?: string;

  @IsString()
  @IsOptional()
  unit_pack_id?: string;

  @IsString()
  @IsOptional()
  mpn?: string;

  @IsString()
  @IsOptional()
  upc?: string;

  @IsString()
  @IsOptional()
  isbn?: string;

  @IsString()
  @IsOptional()
  ean?: string;

  // Composition
  @IsBoolean()
  @IsOptional()
  track_assoc_ingredients?: boolean;

  @IsString()
  @IsOptional()
  buying_rule_id?: string;

  @IsString()
  @IsOptional()
  schedule_of_drug_id?: string;

  @IsString()
  @IsOptional()
  product_type_id?: string;

  // Inventory Settings
  @IsBoolean()
  @IsOptional()
  is_track_inventory?: boolean;

  @IsBoolean()
  @IsOptional()
  track_bin_location?: boolean;

  @IsBoolean()
  @IsOptional()
  track_batches?: boolean;

  @IsBoolean()
  @IsOptional()
  track_serial_number?: boolean;

  @IsString()
  @IsOptional()
  inventory_account_id?: string;

  @IsEnum(InventoryValuationMethod)
  @IsOptional()
  inventory_valuation_method?: InventoryValuationMethod;

  @IsString()
  @IsOptional()
  storage_id?: string;

  @IsString()
  @IsOptional()
  rack_id?: string;

  @IsNumber()
  @IsOptional()
  reorder_point?: number;

  @IsString()
  @IsOptional()
  reorder_term_id?: string;

  @IsNumber()
  @IsOptional()
  lock_unit_pack?: number;

  // eCommerce Information
  @IsString()
  @IsOptional()
  storage_description?: string;

  @IsString()
  @IsOptional()
  about?: string;

  @IsString()
  @IsOptional()
  uses_description?: string;

  @IsString()
  @IsOptional()
  how_to_use?: string;

  @IsString()
  @IsOptional()
  dosage_description?: string;

  @IsString()
  @IsOptional()
  missed_dose_description?: string;

  @IsString()
  @IsOptional()
  safety_advice?: string;

  @IsString()
  @IsOptional()
  how_it_works?: string;

  @IsString()
  @IsOptional()
  drug_interactions?: string;

  @IsString()
  @IsOptional()
  contraindications?: string;

  @IsString()
  @IsOptional()
  side_effects_management?: string;

  @IsString()
  @IsOptional()
  good_to_know?: string;

  @IsString()
  @IsOptional()
  quick_tips?: string;

  @IsString()
  @IsOptional()
  allergy_information?: string;

  @IsString()
  @IsOptional()
  product_highlights?: string;

  @IsArray()
  @IsOptional()
  side_effects?: string[];

  @IsArray()
  @IsOptional()
  faq_text?: string[];

  @IsString()
  @IsOptional()
  ingredients_list?: string;

  @IsString()
  @IsOptional()
  safety_measures_warnings_pregnancy?: string;

  @IsString()
  @IsOptional()
  safety_measures_warnings_breastfeeding?: string;

  @IsString()
  @IsOptional()
  safety_measures_warnings_alcohol?: string;

  @IsString()
  @IsOptional()
  safety_measures_warnings_liver?: string;

  @IsString()
  @IsOptional()
  safety_measures_warnings_kidney?: string;

  @IsString()
  @IsOptional()
  safety_measures_warnings_use_in_driving_and_operating_machinery?: string;

  @IsString()
  @IsOptional()
  safety_measures_warnings_allergy?: string;

  @IsString()
  @IsOptional()
  safety_measures_warnings_children?: string;

  @IsString()
  @IsOptional()
  safety_measures_warnings_older_patients?: string;

  @IsString()
  @IsOptional()
  interactions_drug_drug_interactions?: string;

  @IsString()
  @IsOptional()
  interactions_drug_disease_interactions?: string;

  @IsString()
  @IsOptional()
  dosage_daily_dose?: string;

  @IsString()
  @IsOptional()
  dosage_over_dose?: string;

  @IsString()
  @IsOptional()
  dosage_missed_dose?: string;

  @IsString()
  @IsOptional()
  references_text?: string;

  @IsString()
  @IsOptional()
  product_description?: string;

  @IsString()
  @IsOptional()
  additional_info_allergy?: string;

  @IsString()
  @IsOptional()
  additional_info_concerns?: string;

  @IsString()
  @IsOptional()
  additional_info_good_to_know?: string;

  @IsString()
  @IsOptional()
  additional_info_quick_tips?: string;

  @IsString()
  @IsOptional()
  directions_for_use?: string;

  // Status Flags
  @IsBoolean()
  @IsOptional()
  is_active?: boolean;

  @IsBoolean()
  @IsOptional()
  is_lock?: boolean;

  @IsArray()
  @IsOptional()
  compositions?: CompositionDto[];

  @IsArray()
  @IsOptional()
  parts?: ProductPartDto[];
}

export class ProductPartDto {
  @IsString()
  @IsNotEmpty()
  component_product_id: string;

  @IsNumber()
  @IsNotEmpty()
  quantity: number;

  @IsNumber()
  @IsOptional()
  selling_price_override?: number;

  @IsNumber()
  @IsOptional()
  cost_price_override?: number;
}

export class CompositionDto {
  @IsString()
  @IsOptional()
  content_id?: string;

  @IsString()
  @IsOptional()
  strength_id?: string;
}
