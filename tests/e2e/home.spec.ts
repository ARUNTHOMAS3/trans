import { test, expect } from '@playwright/test';
import { gotoFlutterRoute } from './helpers/flutter';

test.describe('Home Page', () => {
  test.beforeEach(async ({ page }) => {
    await gotoFlutterRoute(page, '/', { readyText: 'Business Overview' });
  });

  test('should load the home dashboard', async ({ page }) => {
    await expect(page).toHaveTitle('Zerpai ERP');
    
    // Flutter semantics mapping: 'Zerpai' brand in sidebar
    const brand = page.getByText('Zerpai', { exact: true }).first();
    await expect(brand).toBeVisible({ timeout: 15000 });
    
    // Dashboard title
    const title = page.getByText('Business Overview', { exact: true }).first();
    await expect(title).toBeVisible();
  });

  test('should display the main layout modules', async ({ page }) => {
    const menuItems = ['Items', 'Inventory', 'Sales', 'Purchases', 'Accountant', 'Reports', 'Documents'];
    
    for (const item of menuItems) {
      // We check for visibility of the menu labels
      await expect(page.getByText(item).first()).toBeVisible({ timeout: 10000 });
    }
  });

  test('should have a working search input', async ({ page }) => {
    // In HTML mode with accessibility enabled, TextFields are role="textbox"
    const searchField = page.getByRole('textbox').first();
    await expect(searchField).toBeVisible({ timeout: 15000 });
  });
});
