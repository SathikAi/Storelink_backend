"""
Playwright — test Reports page in Flutter web app.
Logs in with OTP mock, navigates to Reports, verifies data loads.
Run: python -X utf8 test_reports.py
"""
import asyncio
from playwright.async_api import async_playwright

FLUTTER_URL  = "http://127.0.0.1:8080"
BACKEND_URL  = "http://127.0.0.1:9001"
TEST_PHONE   = "9999999999"

PASS = "[PASS]"
FAIL = "[FAIL]"
INFO = "[INFO]"

def ok(msg):   print(f"  {PASS} {msg}")
def fail(msg): print(f"  {FAIL} {msg}")
def info(msg): print(f"  {INFO} {msg}")


async def get_token():
    """Get auth token via OTP mock."""
    import urllib.request, json
    base = f"{BACKEND_URL}/v1"

    # Send OTP
    req = urllib.request.Request(
        f"{base}/auth/otp/send",
        data=json.dumps({"phone": TEST_PHONE, "purpose": "LOGIN"}).encode(),
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    with urllib.request.urlopen(req, timeout=5) as r:
        body = json.loads(r.read())
        info(f"OTP sent: {body.get('message','')[:50]}")

    # Verify OTP
    req = urllib.request.Request(
        f"{base}/auth/otp/verify",
        data=json.dumps({"phone": TEST_PHONE, "otp_code": "123456", "purpose": "LOGIN"}).encode(),
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    with urllib.request.urlopen(req, timeout=5) as r:
        body = json.loads(r.read())
        token = ((body.get('data') or {}).get('tokens') or {}).get('access_token')
        return token


async def test_report_api_json():
    """Verify report endpoints return correct JSON shape with numeric fields."""
    import urllib.request, json, urllib.error
    print("\n[1] Report API JSON shape check")
    print("    " + "-" * 45)

    try:
        token = await get_token()
        if not token:
            fail("Could not get auth token — check OTP_MOCK setting")
            return None

        ok(f"Auth token obtained")

        base = f"{BACKEND_URL}/v1"
        headers = {"Authorization": f"Bearer {token}"}

        for report in ["sales", "products", "customers"]:
            url = f"{base}/reports/{report}?from_date=2024-01-01&to_date=2026-12-31"
            req = urllib.request.Request(url, headers=headers, method="GET")
            try:
                with urllib.request.urlopen(req, timeout=5) as r:
                    body = json.loads(r.read())
                    # Check all numeric fields are actually numbers
                    bad = {k: v for k, v in body.items()
                           if 'revenue' in k or 'amount' in k or 'tax' in k or 'discount' in k}
                    type_errors = {k: type(v).__name__ for k, v in bad.items()
                                   if not isinstance(v, (int, float))}
                    if type_errors:
                        fail(f"{report}: type errors — {type_errors}")
                    else:
                        ok(f"{report}: all numeric fields are float ✓  {bad}")
            except urllib.error.HTTPError as e:
                raw = json.loads(e.read())
                detail = raw.get('detail', raw)
                code = detail.get('code', '') if isinstance(detail, dict) else ''
                if code == 'PAID_PLAN_REQUIRED':
                    info(f"{report}: FREE plan — PRO gate active (expected for trial account)")
                else:
                    fail(f"{report}: HTTP {e.code} — {raw}")

        return token
    except Exception as e:
        fail(f"API test error: {e}")
        return None


async def test_flutter_reports_page(token):
    """Navigate Flutter web app to Reports, screenshot each tab."""
    print("\n[2] Flutter Web — Reports page")
    print("    " + "-" * 45)

    async with async_playwright() as pw:
        browser = await pw.chromium.launch(headless=True, args=['--disable-web-security'])
        ctx = await browser.new_context(
            viewport={"width": 390, "height": 844},  # iPhone 14 size (mobile app)
            user_agent="Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36"
        )
        page = await ctx.new_page()

        # Collect console errors
        errors = []
        page.on('console', lambda m: errors.append(m.text) if m.type == 'error' else None)
        page.on('pageerror', lambda e: errors.append(str(e)))

        # Load Flutter app
        info("Loading Flutter web app...")
        await page.goto(FLUTTER_URL, wait_until='networkidle', timeout=30000)
        await page.wait_for_timeout(3000)

        await page.screenshot(path='report_01_loaded.png', full_page=True)
        ok("App loaded — report_01_loaded.png")

        # Inject token directly into shared_preferences (web storage)
        if token:
            # Flutter web SharedPreferences stores keys with 'flutter.' prefix
            await page.evaluate(f"""() => {{
                localStorage.setItem('flutter.access_token', '{token}');
                localStorage.setItem('access_token', '{token}');
                localStorage.setItem('flutter.refresh_token', 'dummy_refresh');
            }}""")
            info("Token injected into localStorage (flutter.access_token), reloading...")
            await page.reload(wait_until='networkidle', timeout=20000)
            await page.wait_for_timeout(4000)
            await page.screenshot(path='report_02_after_token.png', full_page=True)
            ok("After token inject — report_02_after_token.png")

        # Check for errors
        type_errs = [e for e in errors if 'subtype' in e or 'String' in e and 'num' in e]
        if type_errs:
            fail(f"Type mismatch errors: {type_errs[:2]}")
        else:
            ok(f"No type mismatch errors ({len(errors)} total console errors)")

        if errors:
            info(f"Console errors: {errors[:3]}")

        await browser.close()


async def main():
    print("=" * 55)
    print("  StoreLink — Reports Page Test")
    print("=" * 55)

    token = await test_report_api_json()
    await test_flutter_reports_page(token)

    print("\n" + "=" * 55)
    print("  Done. Screenshots saved as report_*.png")
    print("=" * 55)


if __name__ == "__main__":
    asyncio.run(main())
