import { test, expect } from '@playwright/test';

test.describe('Home Page', () => {
  test.beforeEach(async ({ page }) => {
    // 1. Navigate with the query param to force accessibility (Semantics) on
    // This is more reliable than clicking the "Enable Accessibility" button manually
    await page.goto('http://localhost:3000/?enable-accessibility=true', { 
      waitUntil: 'domcontentloaded', 
      timeout: 60000 
    });
    
    // 2. Wait for the splash screen to be removed
    await page.waitForSelector('#loading_indicator', { state: 'detached', timeout: 60000 });

    // 3. Wait for the Flutter Glass Pane to be ready
    // This element is the root of all Flutter Web apps
    const glassPane = page.locator('flt-glass-pane');
    await glassPane.waitFor({ state: 'attached', timeout: 30000 });
    
    // 4. Wait for a specific text to appear in the accessibility tree
    // We'll look for "Home" as it's the default route
    await page.getByText('Home').first().waitFor({ state: 'visible', timeout: 30000 });
  });

  test('should load the home dashboard', async ({ page }) => {
    await expect(page).toHaveTitle('Zerpai ERP');
    
    // Flutter semantics mapping: 'Zerpai' brand in sidebar
    const brand = page.getByText('Zerpai', { exact: true }).first();
    await expect(brand).toBeVisible({ timeout: 15000 });
    
    // Dashboard title
    const title = page.getByText('Dashboard', { exact: true }).first();
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
