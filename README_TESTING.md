# 🧪 Zerpai ERP - E2E Testing with Playwright

This project uses **Playwright** for End-to-End (E2E) testing of the Flutter Web interface. Playwright provides a fast, reliable, and cross-browser testing environment.

---

## 🚀 Getting Started

### 1. Prerequisites
Ensure you have **Node.js** (v18+) installed on your system.

### 2. Installation
Install the dependencies and Playwright browsers:

```bash
# Install NPM dependencies
npm install

# Install Playwright browsers (Chromium, Firefox, WebKit)
npx playwright install
```

---

## 🏃 Running Tests

Before running E2E tests, ensure your **Flutter Web** application is running locally.

```bash
# Start Flutter Web on the default port (3000)
flutter run -d chrome --web-renderer canvaskit --web-port 3000
```

Once the app is running, use the following commands:

### Run all tests
```bash
npm run test:e2e
```

### Run tests in UI Mode (Interactive)
```bash
npm run test:e2e:ui
```

### Debug tests
```bash
npm run test:e2e:debug
```

### View Test Report
```bash
npm run test:e2e:report
```

---

## 📁 Project Structure

- `tests/e2e/`: Contains all E2E test files.
  - `home.spec.ts`: Basic smoke tests for the dashboard and sidebar.
- `playwright.config.ts`: Configuration file for Playwright (timeouts, browsers, baseURL).

---

## 💡 Flutter Web Testing Tips

1. **Wait for Initialization**: Flutter Web takes a few seconds to initialize. The tests are configured to wait for the `#loading_indicator` to disappear.
2. **Semantics**: For the best testing experience, ensure your Flutter widgets have proper `Semantics` labels. Playwright's `getByText` and `getByRole` work best when semantics are enabled.
3. **CanvasKit vs HTML**: While these tests work with both, **CanvasKit** (the default) is more performant but can sometimes be trickier for standard DOM selectors. If selectors fail, consider using the HTML renderer for tests or adding `Semantics` widgets.

---

## 🛠️ Adding New Tests

To add a new test, create a file ending in `.spec.ts` in the `tests/e2e` directory.

Example:
```typescript
import { test, expect } from '@playwright/test';

test('should navigate to Items', async ({ page }) => {
  await page.goto('/');
  await page.waitForSelector('#loading_indicator', { state: 'detached' });
  
  await page.getByText('Items', { exact: true }).click();
  await expect(page).toHaveURL(/.*items/);
});
```
