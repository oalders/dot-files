import { test, expect } from '@playwright/test';
test("GPU hardware acceleration", async ({ page }) => {
  await page.goto("chrome://gpu")
  let featureStatusList = page.locator(".feature-status-list")
  await expect(featureStatusList).toContainText("Hardware accelerated")
})
