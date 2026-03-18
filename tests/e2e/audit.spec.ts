import { test, expect } from '@playwright/test';
import { gotoFlutterRoute } from './helpers/flutter';

test.describe('Audit Logs', () => {
  test.beforeEach(async ({ page }) => {
    await gotoFlutterRoute(page, '/audit-logs', { readyText: 'Audit Logs' });
  });

  test('should load the audit logs workspace shell', async ({ page }) => {
    await expect(page.getByText('Audit Logs', { exact: true }).first()).toBeVisible();
    await expect(page.getByText('Activity Explorer', { exact: true })).toBeVisible();
    await expect(page.getByText('All Logs', { exact: true })).toBeVisible();
    await expect(page.getByText('Entry Inspector', { exact: true })).toBeVisible();
  });
});
