import { IsString, IsOptional, IsEmail, IsBoolean } from "class-validator";

export enum VendorType {
  MANUFACTURER = "manufacturer",
  DISTRIBUTOR = "distributor",
  WHOLESALER = "wholesaler",
}

export class CreateVendorDto {
  @IsString()
  displayName: string;

  // @IsOptional()
  // @IsEnum(VendorType)
  // vendorType?: VendorType;

  @IsOptional()
  @IsString()
  vendorNumber?: string;

  @IsOptional()
  @IsString()
  salutation?: string;

  @IsOptional()
  @IsString()
  firstName?: string;

  @IsOptional()
  @IsString()
  lastName?: string;

  @IsOptional()
  @IsString()
  companyName?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsString()
  mobilePhone?: string;

  @IsOptional()
  @IsString()
  designation?: string;

  @IsOptional()
  @IsString()
  department?: string;

  @IsOptional()
  @IsString()
  website?: string;

  @IsOptional()
  @IsString()
  vendorLanguage?: string;

  @IsOptional()
  billingAddress?: any;

  @IsOptional()
  shippingAddress?: any;

  @IsOptional()
  @IsString()
  gstTreatment?: string;

  @IsOptional()
  @IsString()
  gstin?: string;

  @IsOptional()
  @IsString()
  sourceOfSupply?: string;

  @IsOptional()
  @IsString()
  pan?: string;

  // @IsOptional()
  // @IsString()
  // taxPreference?: string;
  //
  // @IsOptional()
  // @IsString()
  // exemptionReason?: string;
  //
  // @IsOptional()
  // @IsString()
  // drugLicenseNo?: string;

  @IsOptional()
  @IsString()
  currency?: string;

  @IsOptional()
  @IsString()
  paymentTerms?: string;

  @IsOptional()
  @IsString()
  priceListId?: string;

  @IsOptional()
  @IsBoolean()
  isMsmeRegistered?: boolean;

  @IsOptional()
  @IsString()
  tdsRateId?: string;

  @IsOptional()
  @IsBoolean()
  enablePortal?: boolean;

  @IsOptional()
  @IsBoolean()
  isDrugRegistered?: boolean;

  @IsOptional()
  @IsString()
  drugLicenceType?: string;

  @IsOptional()
  @IsString()
  drugLicense20?: string;

  @IsOptional()
  @IsString()
  drugLicense21?: string;

  @IsOptional()
  @IsString()
  drugLicense20b?: string;

  @IsOptional()
  @IsString()
  drugLicense21b?: string;

  @IsOptional()
  @IsBoolean()
  isFssaiRegistered?: boolean;

  @IsOptional()
  @IsString()
  fssaiNumber?: string;

  @IsOptional()
  @IsString()
  msmeRegistrationType?: string;

  @IsOptional()
  @IsString()
  msmeRegistrationNumber?: string;

  @IsOptional()
  contactPersons?: any[];

  @IsOptional()
  bankDetails?: any[];

  @IsOptional()
  @IsString()
  remarks?: string;

  @IsOptional()
  @IsString()
  xHandle?: string;

  @IsOptional()
  @IsString()
  facebookHandle?: string;

  @IsOptional()
  @IsString()
  whatsappNumber?: string;

  @IsOptional()
  @IsString()
  source?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
