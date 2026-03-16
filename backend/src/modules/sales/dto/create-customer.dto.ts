import {
  IsString,
  IsOptional,
  IsEmail,
  IsEnum,
  IsNumber,
  Min,
  IsArray,
  ValidateNested,
  IsBoolean,
} from "class-validator";
import { Type } from "class-transformer";

export enum CustomerType {
  BUSINESS = "business",
  INDIVIDUAL = "individual",
}

export enum GstTreatment {
  REGISTERED_BUSINESS = "registered_business",
  UNREGISTERED_BUSINESS = "unregistered_business",
  OVERSEAS = "overseas",
  CONSUMER = "consumer",
}

export class ContactPersonDto {
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
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  workPhone?: string;

  @IsOptional()
  @IsNumber()
  displayOrder?: number;

  @IsOptional()
  @IsString()
  mobilePhone?: string;
}

export class CreateCustomerDto {
  @IsString()
  displayName: string;

  @IsEnum(CustomerType)
  customerType: CustomerType;

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
  website?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ContactPersonDto)
  contactPersons?: ContactPersonDto[];

  @IsOptional()
  billingAddress?: any;

  @IsOptional()
  shippingAddress?: any;

  @IsOptional()
  @IsEnum(GstTreatment)
  gstTreatment?: GstTreatment;

  @IsOptional()
  @IsString()
  gstin?: string;

  @IsOptional()
  @IsString()
  pan?: string;

  @IsOptional()
  @IsString()
  placeOfSupply?: string;

  @IsOptional()
  @IsString()
  currencyId?: string;

  @IsOptional()
  @IsString()
  paymentTerms?: string;

  @IsOptional()
  @IsString()
  priceListId?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  receivableBalance?: number;

  @IsOptional()
  @IsString()
  remarks?: string;

  @IsOptional()
  @IsString()
  drugLicense20DocUrl?: string;

  @IsOptional()
  @IsString()
  drugLicense21DocUrl?: string;

  @IsOptional()
  @IsString()
  drugLicense20BDocUrl?: string;

  @IsOptional()
  @IsString()
  drugLicense21BDocUrl?: string;

  @IsOptional()
  @IsString()
  fssaiDocUrl?: string;

  @IsOptional()
  @IsString()
  msmeDocUrl?: string;

  @IsOptional()
  @IsString()
  documentUrls?: string;

  @IsOptional()
  isRecurring?: boolean;

  // Personal/Contact Details
  @IsOptional()
  @IsString()
  salutation?: string;

  @IsOptional()
  @IsString()
  customerNumber?: string;

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
  businessType?: string;

  @IsOptional()
  @IsString()
  customerLanguage?: string;

  // Individual Customer Fields
  @IsOptional()
  dateOfBirth?: Date;

  @IsOptional()
  @IsNumber()
  age?: number;

  @IsOptional()
  @IsString()
  gender?: string;

  @IsOptional()
  @IsString()
  placeOfCustomer?: string;

  @IsOptional()
  @IsString()
  privilegeCardNumber?: string;

  @IsOptional()
  @IsString()
  parentCustomerId?: string;

  // Tax & Regulatory
  @IsOptional()
  @IsString()
  taxPreference?: string;

  @IsOptional()
  @IsString()
  exemptionReason?: string;

  // License Details
  @IsOptional()
  @IsBoolean()
  isDrugRegistered?: boolean;

  @IsOptional()
  @IsBoolean()
  isFssaiRegistered?: boolean;

  @IsOptional()
  @IsBoolean()
  isMsmeRegistered?: boolean;

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
  drugLicense20B?: string;

  @IsOptional()
  @IsString()
  drugLicense21B?: string;

  @IsOptional()
  @IsString()
  fssai?: string;

  @IsOptional()
  @IsString()
  msmeRegistrationType?: string;

  @IsOptional()
  @IsString()
  msmeNumber?: string;

  // Financial
  @IsOptional()
  @IsNumber()
  openingBalance?: number;

  @IsOptional()
  @IsNumber()
  creditLimit?: number;

  // Social & CRM
  @IsOptional()
  enablePortal?: boolean;

  @IsOptional()
  @IsString()
  facebookHandle?: string;

  @IsOptional()
  @IsString()
  twitterHandle?: string;

  @IsOptional()
  @IsString()
  whatsappNumber?: string;
}
