// @ts-check
const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './tests',
  timeout: 60000,
  retries: 0,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: 'http://localhost:8080',
    headless: true,
    screenshot: 'on',
    video: 'off',
    // Flutter CanvasKit needs longer wait times
    actionTimeout: 20000,
    navigationTimeout: 30000,
  },
  projects: [
    {
      name: 'chromium',
      use: { channel: 'chromium' },
    },
  ],
});
