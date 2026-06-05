import { expect, type Page } from '@playwright/test';

export function buildFlutterRoute(hashPath = '/') {
  const normalized = hashPath.startsWith('/') ? hashPath : `/${hashPath}`;
  return `/?enable-accessibility=true#${normalized}`;
}

export async function gotoFlutterRoute(
  page: Page,
  hashPath = '/',
  options?: { readyText?: string },
) {
  await page.goto(buildFlutterRoute(hashPath), {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });

  await page.waitForSelector('#loading_indicator', {
    state: 'detached',
    timeout: 60000,
  });

  const accessibilityButton = page.getByRole('button', {
    name: 'Enable accessibility',
  });
  if (await accessibilityButton.isVisible().catch(() => false)) {
    await accessibilityButton.evaluate((node) => {
      (node as HTMLElement).click();
    });
    await accessibilityButton.waitFor({
      state: 'detached',
      timeout: 30000,
    });
  }

  if (options?.readyText) {
    await expect(page.getByText(options.readyText).first()).toBeVisible({
      timeout: 60000,
    });
  }
}
