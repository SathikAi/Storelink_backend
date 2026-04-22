"""
Full UI login + navigate to Reports page using Playwright.
python -X utf8 test_reports_ui.py
"""
import asyncio
from playwright.async_api import async_playwright

FLUTTER_URL = "http://127.0.0.1:8080"
TEST_PHONE  = "9876543210"   # trial account (PAID plan — has reports access)

PASS = "[PASS]"
FAIL = "[FAIL]"
INFO = "[INFO]"

def ok(msg):   print(f"  {PASS} {msg}")
def fail(msg): print(f"  {FAIL} {msg}")
def info(msg): print(f"  {INFO} {msg}")


async def main():
    print("=" * 55)
    print("  StoreLink — Reports UI Test (Playwright)")
    print("=" * 55)

    async with async_playwright() as pw:
        browser = await pw.chromium.launch(headless=False, slow_mo=300)
        ctx = await browser.new_context(
            viewport={"width": 390, "height": 844},
        )
        page = await ctx.new_page()

        errors = []
        type_errors = []
        page.on('console', lambda m: (
            errors.append(m.text) if m.type == 'error' else None
        ))
        page.on('console', lambda m: (
            type_errors.append(m.text)
            if ('subtype' in m.text or ("String" in m.text and "num" in m.text))
            else None
        ))

        print("\n[1] Loading Flutter web app")
        print("    " + "-" * 45)
        await page.goto(FLUTTER_URL, wait_until='networkidle', timeout=30000)
        await page.wait_for_timeout(4000)
        await page.screenshot(path='ui_01_login_screen.png')
        ok("Login screen loaded — ui_01_login_screen.png")

        print("\n[2] Clicking 'Sign in with OTP'")
        print("    " + "-" * 45)

        # Find and click OTP button — Flutter renders to canvas/flt-glass-pane
        # Try clicking by text
        try:
            otp_btn = page.get_by_text("Sign In with OTP", exact=False)
            if await otp_btn.count() > 0:
                await otp_btn.first.click()
                ok("Clicked 'Sign In with OTP'")
            else:
                # Try by approximate coordinates (Sign In with OTP is lower button)
                await page.mouse.click(195, 650)
                ok("Clicked OTP button by position")
        except Exception as e:
            info(f"OTP button click: {e}")

        await page.wait_for_timeout(2000)
        await page.screenshot(path='ui_02_otp_screen.png')
        ok("After OTP click — ui_02_otp_screen.png")

        print("\n[3] Entering phone number")
        print("    " + "-" * 45)
        # Type phone number
        await page.keyboard.type(TEST_PHONE)
        await page.wait_for_timeout(500)
        await page.screenshot(path='ui_03_phone_entered.png')
        ok(f"Typed phone: {TEST_PHONE}")

        # Click send OTP / next button
        await page.keyboard.press("Enter")
        await page.wait_for_timeout(2000)
        await page.screenshot(path='ui_04_otp_sent.png')
        ok("Pressed Enter — ui_04_otp_sent.png")

        print("\n[4] Entering OTP")
        print("    " + "-" * 45)
        # Type OTP (mock returns 123456)
        await page.keyboard.type("123456")
        await page.wait_for_timeout(500)
        await page.keyboard.press("Enter")
        await page.wait_for_timeout(3000)
        await page.screenshot(path='ui_05_after_otp.png')
        ok("OTP entered — ui_05_after_otp.png")

        print("\n[5] Checking dashboard state")
        print("    " + "-" * 45)
        await page.wait_for_timeout(3000)
        content = await page.content()
        title = await page.title()
        ok(f"Page title: {title!r}")
        await page.screenshot(path='ui_06_dashboard.png')
        ok("Dashboard state — ui_06_dashboard.png")

        print("\n[6] Navigating to Reports page")
        print("    " + "-" * 45)
        # Try to find Reports nav item
        try:
            reports = page.get_by_text("Reports", exact=False)
            if await reports.count() > 0:
                await reports.first.click()
                ok("Clicked Reports nav")
            else:
                # Try by URL navigation
                await page.goto(f"{FLUTTER_URL}/#/reports", wait_until='networkidle', timeout=10000)
                ok("Navigated to /reports URL")
        except Exception as e:
            info(f"Reports nav: {e}")

        await page.wait_for_timeout(3000)
        await page.screenshot(path='ui_07_reports.png', full_page=True)
        ok("Reports page — ui_07_reports.png")

        print("\n[7] Type error check")
        print("    " + "-" * 45)
        if type_errors:
            fail(f"Type mismatch errors: {type_errors[:3]}")
        else:
            ok(f"No type mismatch errors in console!")

        if errors:
            info(f"Other console errors: {errors[:3]}")

        await page.wait_for_timeout(2000)
        await browser.close()

    print("\n" + "=" * 55)
    print("  Done. Check ui_*.png screenshots")
    print("=" * 55)


if __name__ == "__main__":
    asyncio.run(main())
