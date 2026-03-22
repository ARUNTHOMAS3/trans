import { Injectable } from '@nestjs/common';

const SANDBOX_BASE = 'https://api.sandbox.co.in';
const SANDBOX_API_KEY = process.env.SANDBOX_API_KEY ?? 'key_live_b16392a0519d4364a6ee5262af50bacb';

// Simple in-memory token cache (refreshed on expiry/failure)
let _cachedToken: string | null = null;
let _tokenExpiry = 0;

@Injectable()
export class GstService {
  // ─── Auth ────────────────────────────────────────────────────────────────

  private async getAccessToken(): Promise<string> {
    if (_cachedToken && Date.now() < _tokenExpiry) return _cachedToken;

    const res = await fetch(`${SANDBOX_BASE}/authenticate`, {
      method: 'POST',
      headers: {
        Authorization: SANDBOX_API_KEY,
        'x-api-key': SANDBOX_API_KEY,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({}),
    });

    if (!res.ok) {
      throw new Error(`Sandbox auth failed: ${res.status}`);
    }

    const json: any = await res.json();
    const token: string =
      json?.access_token ?? json?.data?.access_token ?? json?.accessToken ?? '';

    if (!token) throw new Error('Sandbox auth: no access_token in response');

    _cachedToken = token;
    // Treat token as valid for 55 minutes
    _tokenExpiry = Date.now() + 55 * 60 * 1000;
    return token;
  }

  // ─── GSTIN lookup ────────────────────────────────────────────────────────

  async lookupGstin(gstin: string): Promise<{
    gstin: string;
    legalName: string;
    tradeName: string;
    registrationType: string;
    registeredOn: string;
    status: string;
    constitutionOfBusiness: string;
    stateJurisdiction: string;
  }> {
    const token = await this.getAccessToken();

    const res = await fetch(`${SANDBOX_BASE}/gst/compliance/public/gstin/search`, {
      method: 'POST',
      headers: {
        Authorization: token,
        'x-api-key': SANDBOX_API_KEY,
        'x-api-version': '1.0.0',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ gstin }),
    });

    if (!res.ok) {
      throw new Error(`Sandbox GSTIN search failed: ${res.status}`);
    }

    const json: any = await res.json();
    const d = json?.data?.data;

    if (!d || json?.data?.error?.error_cd) {
      const msg = json?.data?.error?.message ?? 'GSTIN not found';
      throw new Error(msg);
    }

    // Map dty (taxpayer type) → our registration type id
    const dtyMap: Record<string, string> = {
      Regular: 'registered_regular',
      'Composition': 'composition',
      'Input Service Distributor (ISD)': 'isd',
      'SEZ Developer': 'sez',
      'SEZ Unit': 'sez',
      'Non-Resident Taxable Person': 'overseas',
      'Non-Resident Online Services Provider and/or Non-Resident Online Money Gaming Supplier': 'overseas',
    };

    const regType = dtyMap[d.dty ?? ''] ?? 'registered_regular';

    // rgdt comes as dd/MM/yyyy — convert to dd-MM-yyyy
    const registeredOn = (d.rgdt ?? '').replace(/\//g, '-');

    return {
      gstin: d.gstin ?? gstin,
      legalName: d.lgnm ?? '',
      tradeName: d.tradeNam ?? '',
      registrationType: regType,
      registeredOn,
      status: d.sts ?? '',
      constitutionOfBusiness: d.ctb ?? '',
      stateJurisdiction: d.stj ?? '',
    };
  }
}
