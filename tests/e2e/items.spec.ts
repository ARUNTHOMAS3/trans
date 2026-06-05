import { test, expect } from '@playwright/test';
import { gotoFlutterRoute } from './helpers/flutter';

const itemId = process.env.PW_ITEM_ID;

test.describe('Items Smoke', () => {
  test('should load items report', async ({ page }) => {
    await gotoFlutterRoute(page, '/items/report', { readyText: 'Items' });

    await expect(page.getByText('All Items').first()).toBeVisible();
    await expect(page.getByRole('textbox').first()).toBeVisible();
  });

  test('should load item create screen', async ({ page }) => {
    await gotoFlutterRoute(page, '/items/create', { readyText: 'New Item' });

    await expect(page.getByText('Type').first()).toBeVisible();
    await expect(page.getByText('Default Tax Rates').first()).toBeVisible();
  });

  test('should load item edit screen directly when PW_ITEM_ID is provided', async ({
    page,
  }) => {
    test.skip(!itemId, 'Set PW_ITEM_ID to validate direct item edit hydration.');

    await gotoFlutterRoute(page, `/items/edit/${itemId}`, {
      readyText: 'Edit Item',
    });

    await expect(page.getByText('Default Tax Rates').first()).toBeVisible();
    await expect(page.getByText('Composition Information').first()).toBeVisible();
  });

  test('should load item detail screen directly when PW_ITEM_ID is provided', async ({
    page,
  }) => {
    test.skip(!itemId, 'Set PW_ITEM_ID to validate direct item detail hydration.');

    await gotoFlutterRoute(page, `/items/detail/${itemId}`, {
      readyText: 'Overview',
    });

    await expect(page.getByText('Item Information').first()).toBeVisible();
    await expect(page.getByText('Salt Composition').first()).toBeVisible();
  });
});
