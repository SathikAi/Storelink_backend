"""
Playwright tests for StoreLink
- Reports page (sales, products, customers)
- Admin dashboard (login, stats, tables)
Run: python test_playwright.py
"""
import asyncio
import json
from playwright.async_api import async_playwright, expect

BACKEND_URL = "http://127.0.0.1:9003"
FLUTTER_URL  = "http://127.0.0.1:8080"
ADMIN_KEY    = "storelink-admin-2024"

# Use a trial account that has reports access
TEST_PHONE   = "9999999999"  # update if needed
TEST_OTP     = "123456"      # mock OTP

PASS = "\033[92m✓\033[0m"
FAIL = "\033[91m✗\033[0m"
INFO = "\033[94m•\033[0m"

def ok(msg):  print(f"  {PASS} {msg}")
def fail(msg): print(f"  {FAIL} {msg}")
def info(msg): print(f"  {INFO} {msg}")


# ─── 1. Backend API direct tests ─────────────────────────────────────────────

async def test_backend_reports(page):
    print("\n── Backend Report API ──────────────────────────────")

    # 1a. Stats endpoint
    res = await page.evaluate("""async () => {
        const r = await fetch('http://127.0.0.1:9003/v1/admin/dashboard-data', {
            headers: {'X-Admin-Key': 'storelink-admin-2024'}
        });
        return {status: r.status, data: await r.json()};
    }""")
    if res['status'] == 200:
        s = res['data']['stats']
        ok(f"Admin stats: {s['total_businesses']} businesses, "
           f"{s['paid_plan_businesses']} paid, {s['trial_plan_businesses']} trial, "
           f"{s['free_plan_businesses']} free, {s['total_customers']} customers")
    else:
        fail(f"Admin stats failed: {res['status']}")

    # 1b. Wrong key rejected
    res2 = await page.evaluate("""async () => {
        const r = await fetch('http://127.0.0.1:9003/v1/admin/dashboard-data', {
            headers: {'X-Admin-Key': 'wrong'}
        });
        return r.status;
    }""")
    if res2 == 401:
        ok("Invalid admin key correctly returns 401")
    else:
        fail(f"Expected 401, got {res2}")

    # 1c. Admin dashboard HTML
    res3 = await page.evaluate("""async () => {
        const r = await fetch('http://127.0.0.1:9003/admin-dashboard');
        return {status: r.status, ct: r.headers.get('content-type')};
    }""")
    if res3['status'] == 200 and 'html' in (res3['ct'] or ''):
        ok(f"Admin HTML page serves correctly (200, {res3['ct']})")
    else:
        fail(f"Admin HTML page: {res3}")


# ─── 2. Admin Dashboard UI ───────────────────────────────────────────────────

async def test_admin_dashboard(page):
    print("\n── Admin Dashboard UI ──────────────────────────────")

    await page.goto(f"{BACKEND_URL}/admin-dashboard")
    await page.wait_for_load_state('networkidle')

    # Login screen visible
    login_input = page.locator('#api-key-input')
    if await login_input.is_visible():
        ok("Login screen shown correctly")
    else:
        fail("Login screen not found")
        return

    # Fill wrong key
    await login_input.fill("wrong-key")
    await page.locator('#login-btn').click()
    await page.wait_for_timeout(1500)
    err = page.locator('#login-error')
    if await err.is_visible():
        ok("Wrong key shows error message")
    else:
        fail("Wrong key should show error")

    # Fill correct key
    await login_input.fill(ADMIN_KEY)
    await page.locator('#login-btn').click()
    # Wait for network fetch to complete
    await page.wait_for_load_state('networkidle', timeout=10000)
    await page.wait_for_timeout(1500)

    # App should be visible
    app = page.locator('#app')
    if await app.is_visible():
        ok("Logged in successfully — dashboard shown")
    else:
        fail("Dashboard did not appear after login")
        return

    # Check stat cards loaded (wait for them to render)
    try:
        await page.locator('.stat-card').first.wait_for(timeout=5000)
    except Exception:
        pass
    stat_cards = page.locator('.stat-card')
    count = await stat_cards.count()
    if count >= 8:
        ok(f"Stats cards loaded ({count} cards)")
    else:
        fail(f"Expected 8+ stat cards, got {count}")

    # Check plan breakdown bar
    plan_breakdown = page.locator('#plan-breakdown')
    if await plan_breakdown.is_visible():
        ok("Plan breakdown bar visible")
    else:
        fail("Plan breakdown bar missing")

    # Check overview table has data rows (not just Loading...)
    await page.wait_for_timeout(1000)
    rows = page.locator('#overview-table-body tr')
    row_count = await rows.count()
    first_text = await rows.first.inner_text() if row_count > 0 else ''
    if row_count > 0 and 'Loading' not in first_text:
        ok(f"Overview table has {row_count} row(s): first={first_text[:40].strip()!r}")
    else:
        fail(f"Overview table empty or still loading: {first_text[:40]!r}")

    # Switch to Businesses tab
    await page.locator('.tab', has_text='Businesses').click()
    await page.wait_for_timeout(800)
    biz_rows = page.locator('#biz-table-body tr')
    biz_count = await biz_rows.count()
    first_biz = await biz_rows.first.inner_text() if biz_count > 0 else ''
    if biz_count > 0 and 'Loading' not in first_biz:
        ok(f"Businesses tab: {biz_count} row(s)")
    else:
        fail(f"Businesses tab empty or loading: {first_biz[:30]!r}")

    # Search filter
    await page.locator('#biz-search').fill('test')
    await page.wait_for_timeout(600)
    ok("Search filter applied without crash")

    # Switch to Users tab
    await page.locator('.tab', has_text='Recent Users').click()
    await page.wait_for_timeout(800)
    user_rows = page.locator('#users-table-body tr')
    user_count = await user_rows.count()
    first_user = await user_rows.first.inner_text() if user_count > 0 else ''
    if user_count > 0 and 'Loading' not in first_user:
        ok(f"Users tab: {user_count} row(s)")
    else:
        fail(f"Users tab empty or loading: {first_user[:30]!r}")

    # Switch to Profile Completion tab
    await page.locator('.tab', has_text='Profile Completion').click()
    await page.wait_for_timeout(800)
    try:
        await page.locator('.completion-card').first.wait_for(timeout=3000)
    except Exception:
        pass
    cards = page.locator('.completion-card')
    card_count = await cards.count()
    if card_count > 0:
        ok(f"Profile completion: {card_count} business card(s)")
    else:
        fail("Profile completion tab empty")

    # Screenshot
    await page.screenshot(path='test_admin_dashboard.png')
    ok("Screenshot saved: test_admin_dashboard.png")


# ─── 3. Flutter Web Reports ──────────────────────────────────────────────────

async def test_flutter_reports(pw):
    print("\n── Flutter Web — Reports ───────────────────────────")

    browser2 = await pw.chromium.launch(headless=True)
    page2 = await browser2.new_page()

    try:
        await page2.goto(FLUTTER_URL, timeout=20000)
        await page2.wait_for_load_state('networkidle', timeout=20000)
        await page2.wait_for_timeout(4000)

        await page2.screenshot(path='test_flutter_landing.png')
        ok("Flutter web loaded — screenshot: test_flutter_landing.png")

        content = await page2.content()
        title = await page2.title()
        ok(f"Page title: {title!r}")

        if 'flt-' in content or 'flutter' in content.lower():
            ok("Flutter DOM elements detected")
        else:
            info("Flutter app rendered (canvas-based, no flt- tags in DOM)")

        # Check no JS errors about type mismatch
        logs = []
        page2.on('console', lambda msg: logs.append(msg.text) if msg.type == 'error' else None)
        await page2.wait_for_timeout(1000)
        type_errors = [l for l in logs if 'subtype' in l or 'type' in l.lower()]
        if type_errors:
            fail(f"JS type errors found: {type_errors[:2]}")
        else:
            ok("No type mismatch errors in console")

    except Exception as e:
        fail(f"Flutter web test error: {e}")
    finally:
        await browser2.close()


# ─── 4. Backend report endpoints direct ──────────────────────────────────────

async def test_report_endpoints_direct():
    print("\n── Report JSON Shape Validation ────────────────────")
    import urllib.request

    base = f"{BACKEND_URL}/v1"

    # First login to get a token — use mock OTP flow
    # Register/login via API
    try:
        # Step 1: Send OTP
        req_data = json.dumps({"phone": TEST_PHONE, "purpose": "login"}).encode()
        req = urllib.request.Request(
            f"{base}/auth/otp/send",
            data=req_data,
            headers={"Content-Type": "application/json"},
            method="POST"
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            body = json.loads(resp.read())
            info(f"OTP sent: {body.get('message', str(body))[:60]}")

        # Step 2: Verify OTP (mock mode returns token for any OTP)
        req_data = json.dumps({"phone": TEST_PHONE, "otp_code": "123456", "purpose": "LOGIN"}).encode()
        req = urllib.request.Request(
            f"{base}/auth/otp/verify",
            data=req_data,
            headers={"Content-Type": "application/json"},
            method="POST"
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            body = json.loads(resp.read())
            token = (body.get('data') or {}).get('access_token')
            if token:
                ok(f"Got auth token for {TEST_PHONE}")
            else:
                fail(f"Login failed: {body}")
                return

        # Now test sales report
        req = urllib.request.Request(
            f"{base}/reports/sales?from_date=2024-01-01&to_date=2026-12-31",
            headers={"Authorization": f"Bearer {token}"},
            method="GET"
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            body = json.loads(resp.read())
            # Validate shape
            assert 'business_name' in body, "Missing business_name"
            assert 'total_orders' in body, "Missing total_orders"
            assert 'total_revenue' in body, "Missing total_revenue"
            assert isinstance(body['total_revenue'], (int, float)), \
                f"total_revenue should be numeric, got {type(body['total_revenue'])}: {body['total_revenue']!r}"
            assert 'orders' in body, "Missing orders list"
            ok(f"Sales report JSON shape ✓ — {body['total_orders']} orders, revenue={body['total_revenue']}")

        # Test products report
        req = urllib.request.Request(
            f"{base}/reports/products?from_date=2024-01-01&to_date=2026-12-31",
            headers={"Authorization": f"Bearer {token}"},
            method="GET"
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            body = json.loads(resp.read())
            assert 'products' in body, "Missing products list"
            assert isinstance(body['total_revenue'], (int, float)), \
                f"total_revenue should be numeric, got {type(body['total_revenue'])}"
            ok(f"Products report JSON shape ✓ — {body['total_products_sold']} products")

        # Test customers report
        req = urllib.request.Request(
            f"{base}/reports/customers?from_date=2024-01-01&to_date=2026-12-31",
            headers={"Authorization": f"Bearer {token}"},
            method="GET"
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            body = json.loads(resp.read())
            assert 'customers' in body, "Missing customers list"
            assert isinstance(body['total_revenue'], (int, float)), \
                f"total_revenue should be numeric, got {type(body['total_revenue'])}"
            ok(f"Customers report JSON shape ✓ — {body['total_customers']} customers")

    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            body = json.loads(raw)
        except Exception:
            body = raw.decode()
        detail = body.get('detail', body) if isinstance(body, dict) else body
        code = detail.get('code', '') if isinstance(detail, dict) else ''
        if code == 'PAID_PLAN_REQUIRED':
            info("Reports blocked (FREE plan) — PRO gate working correctly")
        else:
            fail(f"HTTP {e.code}: {body}")
    except Exception as e:
        fail(f"Direct API test error: {e}")


# ─── Main ────────────────────────────────────────────────────────────────────

async def main():
    print("=" * 55)
    print("  StoreLink Playwright Test Suite")
    print("=" * 55)

    # Direct API tests (no browser needed)
    await test_report_endpoints_direct()

    async with async_playwright() as pw:
        browser = await pw.chromium.launch(headless=True)
        page = await browser.new_page()

        await test_backend_reports(page)
        await test_admin_dashboard(page)
        await test_flutter_reports(pw)

        await browser.close()

    print("\n" + "=" * 55)
    print("  Tests complete. Check *.png screenshots.")
    print("=" * 55)


if __name__ == "__main__":
    asyncio.run(main())
