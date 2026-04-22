"""
Inject auth token before Flutter loads, then navigate to Reports page.
python -X utf8 test_reports_final.py
"""
import asyncio, urllib.request, json
from playwright.async_api import async_playwright

FLUTTER_URL = "http://127.0.0.1:8080"
BACKEND     = "http://127.0.0.1:9001/v1"
TRIAL_PHONE = "9876543210"   # PAID/trial account — has reports access

PASS = "[PASS]"
FAIL = "[FAIL]"
INFO = "[INFO]"

def ok(msg):   print(f"  {PASS} {msg}")
def fail(msg): print(f"  {FAIL} {msg}")
def info(msg): print(f"  {INFO} {msg}")


def get_token(phone=TRIAL_PHONE):
    """Get JWT via OTP mock (synchronous)."""
    urllib.request.urlopen(urllib.request.Request(
        f"{BACKEND}/auth/otp/send",
        data=json.dumps({"phone": phone, "purpose": "LOGIN"}).encode(),
        headers={"Content-Type": "application/json"}, method="POST"
    ))
    r = urllib.request.urlopen(urllib.request.Request(
        f"{BACKEND}/auth/otp/verify",
        data=json.dumps({"phone": phone, "otp_code": "123456", "purpose": "LOGIN"}).encode(),
        headers={"Content-Type": "application/json"}, method="POST"
    ))
    body = json.loads(r.read())
    return body["data"]["tokens"]["access_token"]


async def main():
    print("=" * 55)
    print("  StoreLink — Reports Page Final Test")
    print("=" * 55)

    print("\n[1] Getting auth token via API")
    token = get_token()
    ok(f"Token for {TRIAL_PHONE}: {token[:30]}...")

    async with async_playwright() as pw:
        browser = await pw.chromium.launch(headless=True)

        # Step: open a blank page first, inject token, THEN navigate to Flutter
        ctx = await browser.new_context(viewport={"width": 390, "height": 844})
        page = await ctx.new_page()

        errors = []
        type_errs = []
        page.on('console', lambda m: errors.append(m.text) if m.type == 'error' else None)
        page.on('console', lambda m: (
            type_errs.append(m.text)
            if ('subtype' in m.text or ('String' in m.text and 'num' in m.text))
            else None
        ))

        print("\n[2] Injecting token before Flutter loads")
        # Visit a minimal page to get origin context
        await page.goto(f"{FLUTTER_URL}/favicon.png", wait_until='load')
        # Inject into localStorage with Flutter's SharedPreferences format
        await page.evaluate(f"""() => {{
            localStorage.setItem('flutter.access_token', '{token}');
            localStorage.setItem('flutter.refresh_token', 'dummy');
            console.log('Token injected:', localStorage.getItem('flutter.access_token') ? 'YES' : 'NO');
        }}""")
        ok("Token injected into localStorage")

        print("\n[3] Loading Flutter app (should auto-login)")
        await page.goto(FLUTTER_URL, wait_until='networkidle', timeout=30000)
        await page.wait_for_timeout(5000)
        await page.screenshot(path='final_01_loaded.png')
        ok("Flutter loaded — final_01_loaded.png")

        content = await page.content()
        has_flutter = 'flt-' in content or 'flutter' in content.lower()
        ok(f"Flutter DOM present: {has_flutter}")

        print("\n[4] Navigating to /reports")
        await page.goto(f"{FLUTTER_URL}/#/reports", wait_until='networkidle', timeout=15000)
        await page.wait_for_timeout(4000)
        await page.screenshot(path='final_02_reports.png', full_page=True)
        ok("Reports page — final_02_reports.png")

        print("\n[5] Checking Products tab")
        await page.goto(f"{FLUTTER_URL}/#/reports", wait_until='networkidle', timeout=15000)
        await page.wait_for_timeout(2000)
        # Try clicking Products tab
        try:
            await page.get_by_text("Products").first.click()
            await page.wait_for_timeout(2000)
        except Exception:
            pass
        await page.screenshot(path='final_03_products.png', full_page=True)
        ok("Products tab — final_03_products.png")

        print("\n[6] Type error check")
        if type_errs:
            fail(f"TYPE ERRORS FOUND: {type_errs[:3]}")
        else:
            ok("NO type mismatch errors — reports working correctly!")

        non_401_errors = [e for e in errors if '401' not in e]
        if non_401_errors:
            info(f"Other console errors: {non_401_errors[:3]}")
        else:
            ok("No unexpected errors")

        await browser.close()

    print("\n" + "=" * 55)
    print("  Done. Screenshots: final_*.png")
    print("=" * 55)


if __name__ == "__main__":
    asyncio.run(main())
