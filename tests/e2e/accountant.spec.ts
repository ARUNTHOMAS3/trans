import { test, expect } from '@playwright/test';
import { gotoFlutterRoute } from './helpers/flutter';

test.describe('Accountant Smoke', () => {
  test('should load manual journals list', async ({ page }) => {
    await gotoFlutterRoute(page, '/accountant/manual-journals', {
      readyText: 'All Manual Journals',
    });

    await expect(page.getByText('New').first()).toBeVisible();
    await expect(page.getByText('Period: All').first()).toBeVisible();
  });

  test('should load manual journal create screen', async ({ page }) => {
    await gotoFlutterRoute(page, '/accountant/manual-journals/create', {
      readyText: 'New Journal',
    });

    await expect(page.getByText('Choose Template').first()).toBeVisible();
    await expect(page.getByText('Reporting Method').first()).toBeVisible();
  });

  test('should load recurring journals list', async ({ page }) => {
    await gotoFlutterRoute(page, '/accountant/recurring-journals', {
      readyText: 'All Recurring Journals',
    });

    await expect(page.getByText('New').first()).toBeVisible();
  });

  test('should load chart of accounts overview', async ({ page }) => {
    await gotoFlutterRoute(page, '/accounts/chart-of-accounts', {
      readyText: 'Chart of Accounts',
    });

    await expect(page.getByText('All Accounts').first()).toBeVisible();
    await expect(page.getByText('New').first()).toBeVisible();
  });

  test('should load transaction locking screen', async ({ page }) => {
    await gotoFlutterRoute(page, '/accountant/transaction-locking', {
      readyText: 'Transaction Locking',
    });

    await expect(page.getByText('Sales').first()).toBeVisible();
    await expect(page.getByText('Purchases').first()).toBeVisible();
    await expect(page.getByText('Banking').first()).toBeVisible();
  });
});
