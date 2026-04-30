from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.enums import TA_CENTER, TA_RIGHT, TA_LEFT
from io import BytesIO
from datetime import datetime, timezone
from app.schemas.report import (
    SalesReportResponse,
    ProductReportResponse,
    CustomerReportResponse
)

# A4 usable width: 595.27pt - 40pt left - 40pt right = 515.27pt = 7.156 inches
PAGE_WIDTH = A4[0] - 80  # points


def _alternating_bg(num_rows: int, start_row: int = 1):
    """Return BACKGROUND TableStyle commands for alternating row colours."""
    styles = []
    for i in range(num_rows):
        row = start_row + i
        bg = colors.white if i % 2 == 0 else colors.HexColor('#f8f9fa')
        styles.append(('BACKGROUND', (0, row), (-1, row), bg))
    return styles


def _base_table_style(num_data_rows: int):
    """Shared table style for all report tables."""
    style = [
        # Header row
        ('BACKGROUND',    (0, 0), (-1, 0),  colors.HexColor('#2c3e50')),
        ('TEXTCOLOR',     (0, 0), (-1, 0),  colors.whitesmoke),
        ('FONTNAME',      (0, 0), (-1, 0),  'Helvetica-Bold'),
        ('FONTSIZE',      (0, 0), (-1, 0),  9),
        ('ALIGN',         (0, 0), (-1, 0),  'CENTER'),
        ('VALIGN',        (0, 0), (-1, 0),  'MIDDLE'),
        ('BOTTOMPADDING', (0, 0), (-1, 0),  10),
        ('TOPPADDING',    (0, 0), (-1, 0),  10),
        # Data rows
        ('FONTSIZE',      (0, 1), (-1, -1), 8),
        ('VALIGN',        (0, 1), (-1, -1), 'MIDDLE'),
        ('TOPPADDING',    (0, 1), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 1), (-1, -1), 6),
        ('LEFTPADDING',   (0, 0), (-1, -1), 6),
        ('RIGHTPADDING',  (0, 0), (-1, -1), 6),
        # Grid
        ('GRID',          (0, 0), (-1, -1), 0.5, colors.HexColor('#dee2e6')),
        ('LINEBELOW',     (0, 0), (-1, 0),  1.5, colors.HexColor('#1a252f')),
    ]
    style.extend(_alternating_bg(num_data_rows))
    return style


class PDFGenerator:

    @staticmethod
    def _create_header(business_name: str, report_title: str,
                       from_date: str = None, to_date: str = None):
        styles = getSampleStyleSheet()

        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=18,
            textColor=colors.HexColor('#1a1a1a'),
            spaceAfter=8,
            alignment=TA_CENTER,
            fontName='Helvetica-Bold'
        )
        subtitle_style = ParagraphStyle(
            'CustomSubtitle',
            parent=styles['Normal'],
            fontSize=11,
            textColor=colors.HexColor('#555555'),
            spaceAfter=4,
            alignment=TA_CENTER
        )
        meta_style = ParagraphStyle(
            'Meta',
            parent=styles['Normal'],
            fontSize=9,
            textColor=colors.HexColor('#888888'),
            spaceAfter=4,
            alignment=TA_CENTER
        )

        elements = [
            Paragraph(business_name, title_style),
            Paragraph(report_title, subtitle_style),
        ]
        if from_date or to_date:
            elements.append(Paragraph(
                f"Period: {from_date or 'All time'} to {to_date or 'Present'}",
                meta_style
            ))
        elements.append(Paragraph(
            f"Generated: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M')} UTC",
            meta_style
        ))
        elements.append(Spacer(1, 0.25 * inch))
        return elements

    @staticmethod
    def _summary_para(text: str):
        styles = getSampleStyleSheet()
        return Paragraph(text, ParagraphStyle(
            'Summary', parent=styles['Normal'],
            fontSize=10, spaceAfter=4,
            leftIndent=4
        ))

    # ── Sales Report ──────────────────────────────────────────────
    @staticmethod
    def generate_sales_report(report_data: SalesReportResponse) -> BytesIO:
        buffer = BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4,
                                rightMargin=40, leftMargin=40,
                                topMargin=40, bottomMargin=40)
        elements = []

        elements.extend(PDFGenerator._create_header(
            report_data.business_name, "Sales Report",
            report_data.from_date, report_data.to_date
        ))

        elements += [
            PDFGenerator._summary_para(f"<b>Total Orders:</b> {report_data.total_orders}"),
            PDFGenerator._summary_para(f"<b>Total Revenue:</b> ₹{report_data.total_revenue:,.2f}"),
            PDFGenerator._summary_para(f"<b>Total Tax:</b> ₹{report_data.total_tax:,.2f}"),
            PDFGenerator._summary_para(f"<b>Total Discount:</b> ₹{report_data.total_discount:,.2f}"),
            Spacer(1, 0.2 * inch),
        ]

        if report_data.orders:
            # Widths sum = PAGE_WIDTH (515.27 pt ≈ 7.156 in)
            # Order# | Customer | Date | Status | Payment | Total
            col_w = [
                1.1 * inch,   # Order #
                1.5 * inch,   # Customer
                0.9 * inch,   # Date
                1.0 * inch,   # Status
                1.0 * inch,   # Payment
                PAGE_WIDTH - (1.1 + 1.5 + 0.9 + 1.0 + 1.0) * inch,  # Total
            ]

            header = [['Order #', 'Customer', 'Date', 'Status', 'Payment', 'Total (₹)']]
            rows = []
            for order in report_data.orders:
                rows.append([
                    order.order_number or '-',
                    order.customer_name or 'Walk-in',
                    order.order_date[:10] if order.order_date else '-',
                    order.status,
                    order.payment_status,
                    f'{order.total_amount:,.2f}',
                ])

            table_data = header + rows
            style = _base_table_style(len(rows))
            # Right-align numeric/amount column
            style += [
                ('ALIGN', (0, 1), (0, -1), 'LEFT'),    # Order #
                ('ALIGN', (1, 1), (1, -1), 'LEFT'),    # Customer
                ('ALIGN', (2, 1), (2, -1), 'CENTER'),  # Date
                ('ALIGN', (3, 1), (3, -1), 'CENTER'),  # Status
                ('ALIGN', (4, 1), (4, -1), 'CENTER'),  # Payment
                ('ALIGN', (5, 1), (5, -1), 'RIGHT'),   # Total
            ]
            table = Table(table_data, colWidths=col_w, repeatRows=1)
            table.setStyle(TableStyle(style))
            elements.append(table)

        doc.build(elements)
        buffer.seek(0)
        return buffer

    # ── Product Report ────────────────────────────────────────────
    @staticmethod
    def generate_product_report(report_data: ProductReportResponse) -> BytesIO:
        buffer = BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4,
                                rightMargin=40, leftMargin=40,
                                topMargin=40, bottomMargin=40)
        elements = []

        elements.extend(PDFGenerator._create_header(
            report_data.business_name, "Product Sales Report",
            report_data.from_date, report_data.to_date
        ))

        elements += [
            PDFGenerator._summary_para(f"<b>Total Products with Sales:</b> {report_data.total_products_sold}"),
            PDFGenerator._summary_para(f"<b>Total Revenue:</b> ₹{report_data.total_revenue:,.2f}"),
            Spacer(1, 0.2 * inch),
        ]

        if report_data.products:
            # Product Name | SKU | Category | Qty Sold | Orders | Revenue
            col_w = [
                2.0 * inch,   # Product Name
                0.9 * inch,   # SKU
                1.0 * inch,   # Category
                0.75 * inch,  # Qty Sold
                0.75 * inch,  # Orders
                PAGE_WIDTH - (2.0 + 0.9 + 1.0 + 0.75 + 0.75) * inch,  # Revenue
            ]

            header = [['Product Name', 'SKU', 'Category', 'Qty Sold', 'Orders', 'Revenue (₹)']]
            rows = []
            for p in report_data.products:
                rows.append([
                    p.product_name,          # No truncation — table wraps
                    p.product_sku or '-',
                    p.category_name or '-',
                    str(p.total_quantity_sold),
                    str(p.orders_count),
                    f'{p.total_revenue:,.2f}',
                ])

            table_data = header + rows
            style = _base_table_style(len(rows))
            style += [
                ('ALIGN', (0, 1), (0, -1), 'LEFT'),    # Product Name
                ('ALIGN', (1, 1), (1, -1), 'LEFT'),    # SKU
                ('ALIGN', (2, 1), (2, -1), 'LEFT'),    # Category
                ('ALIGN', (3, 1), (3, -1), 'CENTER'),  # Qty Sold
                ('ALIGN', (4, 1), (4, -1), 'CENTER'),  # Orders
                ('ALIGN', (5, 1), (5, -1), 'RIGHT'),   # Revenue
            ]
            table = Table(table_data, colWidths=col_w, repeatRows=1)
            table.setStyle(TableStyle(style))
            elements.append(table)

        doc.build(elements)
        buffer.seek(0)
        return buffer

    # ── Customer Report ───────────────────────────────────────────
    @staticmethod
    def generate_customer_report(report_data: CustomerReportResponse) -> BytesIO:
        buffer = BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4,
                                rightMargin=40, leftMargin=40,
                                topMargin=40, bottomMargin=40)
        elements = []

        elements.extend(PDFGenerator._create_header(
            report_data.business_name, "Customer Report",
            report_data.from_date, report_data.to_date
        ))

        elements += [
            PDFGenerator._summary_para(f"<b>Total Customers:</b> {report_data.total_customers}"),
            PDFGenerator._summary_para(f"<b>Total Revenue:</b> ₹{report_data.total_revenue:,.2f}"),
            Spacer(1, 0.2 * inch),
        ]

        if report_data.customers:
            # Name | Phone | Email | Orders | Total Spent | Last Order
            col_w = [
                1.5 * inch,   # Name
                1.0 * inch,   # Phone
                1.5 * inch,   # Email
                0.65 * inch,  # Orders
                1.0 * inch,   # Total Spent
                PAGE_WIDTH - (1.5 + 1.0 + 1.5 + 0.65 + 1.0) * inch,  # Last Order
            ]

            header = [['Customer Name', 'Phone', 'Email', 'Orders', 'Total Spent (₹)', 'Last Order']]
            rows = []
            for c in report_data.customers:
                rows.append([
                    c.customer_name,
                    c.customer_phone or '-',
                    c.customer_email or '-',
                    str(c.total_orders),
                    f'{c.total_spent:,.2f}',
                    c.last_order_date[:10] if c.last_order_date else '-',
                ])

            table_data = header + rows
            style = _base_table_style(len(rows))
            style += [
                ('ALIGN', (0, 1), (0, -1), 'LEFT'),    # Name
                ('ALIGN', (1, 1), (1, -1), 'LEFT'),    # Phone
                ('ALIGN', (2, 1), (2, -1), 'LEFT'),    # Email
                ('ALIGN', (3, 1), (3, -1), 'CENTER'),  # Orders
                ('ALIGN', (4, 1), (4, -1), 'RIGHT'),   # Total Spent
                ('ALIGN', (5, 1), (5, -1), 'CENTER'),  # Last Order
            ]
            table = Table(table_data, colWidths=col_w, repeatRows=1)
            table.setStyle(TableStyle(style))
            elements.append(table)

        doc.build(elements)
        buffer.seek(0)
        return buffer
