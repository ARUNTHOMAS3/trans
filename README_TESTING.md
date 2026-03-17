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

Playwright can now start a local Flutter web server automatically when the target URL is local.
If you do nothing, it will use `http://localhost:3000`.
The current setup builds Flutter web and serves `build/web` through Playwright's `webServer` hook.

Once the target URL is decided, use the following commands:

### Run all tests
```bash
npm run test:e2e
```

### Run Flutter unit tests
```bash
npm run test:flutter
```

### Run backend Jest tests
```bash
npm run test:backend
```

### Run the whole suite
```bash
npm run test:all
```

If your app is running on a different port, set the Playwright base URL first.

PowerShell:
```powershell
$env:PLAYWRIGHT_BASE_URL = 'http://localhost:53431'
npm run test:e2e
```

If `PLAYWRIGHT_BASE_URL` points to `localhost` or `127.0.0.1`, Playwright will try to start Flutter automatically with the matching port unless something is already running there.

Optional direct item-route validation:
```powershell
$env:PLAYWRIGHT_BASE_URL = 'http://localhost:53431'
$env:PW_ITEM_ID = 'your-item-id'
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
  - `accountant.spec.ts`: Smoke tests for manual journals, recurring journals, chart of accounts, and transaction locking.
  - `items.spec.ts`: Smoke tests for item report/create routes and optional direct item detail/edit route hydration.
  - `helpers/flutter.ts`: Shared route/bootstrap helper for Flutter Web hash routes.
- `test/`: Flutter unit tests.
  - `core/utils/error_handler_test.dart`
  - `modules/accountant/manual_journals/models/manual_journal_model_test.dart`
- `backend/src/**/*.spec.ts`: backend Jest tests.
  - `common/interceptors/standard_response.interceptor.spec.ts`
  - `modules/health/health.controller.spec.ts`
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
