from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.enums import TA_CENTER, TA_RIGHT, TA_LEFT
from io import BytesIO
from datetime import datetime
from app.schemas.report import (
    SalesReportResponse,
    ProductReportResponse,
    CustomerReportResponse
)


class PDFGenerator:
    
    @staticmethod
    def _create_header(business_name: str, report_title: str, from_date: str = None, to_date: str = None):
        styles = getSampleStyleSheet()
        
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=18,
            textColor=colors.HexColor('#1a1a1a'),
            spaceAfter=12,
            alignment=TA_CENTER,
            fontName='Helvetica-Bold'
        )
        
        subtitle_style = ParagraphStyle(
            'CustomSubtitle',
            parent=styles['Normal'],
            fontSize=12,
            textColor=colors.HexColor('#666666'),
            spaceAfter=6,
            alignment=TA_CENTER
        )
        
        elements = []
        elements.append(Paragraph(business_name, title_style))
        elements.append(Paragraph(report_title, subtitle_style))
        
        if from_date or to_date:
            date_range = f"Period: {from_date or 'Start'} to {to_date or 'End'}"
            elements.append(Paragraph(date_range, subtitle_style))
        
        generated_text = f"Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
        elements.append(Paragraph(generated_text, subtitle_style))
        elements.append(Spacer(1, 0.3 * inch))
        
        return elements
    
    @staticmethod
    def generate_sales_report(report_data: SalesReportResponse) -> BytesIO:
        buffer = BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4, rightMargin=40, leftMargin=40, topMargin=40, bottomMargin=40)
        elements = []
        
        elements.extend(PDFGenerator._create_header(
            report_data.business_name,
            "Sales Report",
            report_data.from_date,
            report_data.to_date
        ))
        
        styles = getSampleStyleSheet()
        summary_style = ParagraphStyle(
            'Summary',
            parent=styles['Normal'],
            fontSize=11,
            spaceAfter=6
        )
        
        elements.append(Paragraph(f"<b>Total Orders:</b> {report_data.total_orders}", summary_style))
        elements.append(Paragraph(f"<b>Total Revenue:</b> ₹{report_data.total_revenue:,.2f}", summary_style))
        elements.append(Paragraph(f"<b>Total Tax:</b> ₹{report_data.total_tax:,.2f}", summary_style))
        elements.append(Paragraph(f"<b>Total Discount:</b> ₹{report_data.total_discount:,.2f}", summary_style))
        elements.append(Spacer(1, 0.3 * inch))
        
        if report_data.orders:
            table_data = [['Order #', 'Customer', 'Date', 'Status', 'Payment', 'Total (₹)']]
            
            for order in report_data.orders:
                table_data.append([
                    order.order_number,
                    order.customer_name or 'Walk-in',
                    order.order_date[:10] if order.order_date else '',
                    order.status,
                    order.payment_status,
                    f'{order.total_amount:,.2f}'
                ])
            
            table = Table(table_data, colWidths=[1.2*inch, 1.3*inch, 1.0*inch, 1.0*inch, 0.9*inch, 1.0*inch])
            table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#2c3e50')),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                ('ALIGN', (-1, 0), (-1, -1), 'RIGHT'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, 0), 10),
                ('FONTSIZE', (0, 1), (-1, -1), 8),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                ('TOPPADDING', (0, 1), (-1, -1), 6),
                ('BOTTOMPADDING', (0, 1), (-1, -1), 6),
                ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
                ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f8f9fa')])
            ]))
            elements.append(table)
        
        doc.build(elements)
        buffer.seek(0)
        return buffer
    
    @staticmethod
    def generate_product_report(report_data: ProductReportResponse) -> BytesIO:
        buffer = BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4, rightMargin=40, leftMargin=40, topMargin=40, bottomMargin=40)
        elements = []
        
        elements.extend(PDFGenerator._create_header(
            report_data.business_name,
            "Product Sales Report",
            report_data.from_date,
            report_data.to_date
        ))
        
        styles = getSampleStyleSheet()
        summary_style = ParagraphStyle(
            'Summary',
            parent=styles['Normal'],
            fontSize=11,
            spaceAfter=6
        )
        
        elements.append(Paragraph(f"<b>Total Products Sold:</b> {report_data.total_products_sold}", summary_style))
        elements.append(Paragraph(f"<b>Total Revenue:</b> ₹{report_data.total_revenue:,.2f}", summary_style))
        elements.append(Spacer(1, 0.3 * inch))
        
        if report_data.products:
            table_data = [['Product Name', 'SKU', 'Category', 'Qty Sold', 'Orders', 'Revenue (₹)']]
            
            for product in report_data.products:
                table_data.append([
                    product.product_name[:30],
                    product.product_sku or '-',
                    product.category_name or '-',
                    str(product.total_quantity_sold),
                    str(product.orders_count),
                    f'{product.total_revenue:,.2f}'
                ])
            
            table = Table(table_data, colWidths=[2.0*inch, 0.9*inch, 1.0*inch, 0.8*inch, 0.8*inch, 1.0*inch])
            table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#2c3e50')),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                ('ALIGN', (3, 0), (-1, -1), 'RIGHT'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, 0), 10),
                ('FONTSIZE', (0, 1), (-1, -1), 8),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                ('TOPPADDING', (0, 1), (-1, -1), 6),
                ('BOTTOMPADDING', (0, 1), (-1, -1), 6),
                ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
                ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f8f9fa')])
            ]))
            elements.append(table)
        
        doc.build(elements)
        buffer.seek(0)
        return buffer
    
    @staticmethod
    def generate_customer_report(report_data: CustomerReportResponse) -> BytesIO:
        buffer = BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4, rightMargin=40, leftMargin=40, topMargin=40, bottomMargin=40)
        elements = []
        
        elements.extend(PDFGenerator._create_header(
            report_data.business_name,
            "Customer Report",
            report_data.from_date,
            report_data.to_date
        ))
        
        styles = getSampleStyleSheet()
        summary_style = ParagraphStyle(
            'Summary',
            parent=styles['Normal'],
            fontSize=11,
            spaceAfter=6
        )
        
        elements.append(Paragraph(f"<b>Total Customers:</b> {report_data.total_customers}", summary_style))
        elements.append(Paragraph(f"<b>Total Revenue:</b> ₹{report_data.total_revenue:,.2f}", summary_style))
        elements.append(Spacer(1, 0.3 * inch))
        
        if report_data.customers:
            table_data = [['Customer Name', 'Phone', 'Email', 'Orders', 'Total Spent (₹)', 'Last Order']]
            
            for customer in report_data.customers:
                table_data.append([
                    customer.customer_name[:25],
                    customer.customer_phone,
                    (customer.customer_email or '-')[:20],
                    str(customer.total_orders),
                    f'{customer.total_spent:,.2f}',
                    customer.last_order_date[:10] if customer.last_order_date else '-'
                ])
            
            table = Table(table_data, colWidths=[1.5*inch, 1.0*inch, 1.3*inch, 0.7*inch, 1.0*inch, 1.0*inch])
            table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#2c3e50')),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                ('ALIGN', (3, 0), (-1, -1), 'RIGHT'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, 0), 10),
                ('FONTSIZE', (0, 1), (-1, -1), 8),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                ('TOPPADDING', (0, 1), (-1, -1), 6),
                ('BOTTOMPADDING', (0, 1), (-1, -1), 6),
                ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
                ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#f8f9fa')])
            ]))
            elements.append(table)
        
        doc.build(elements)
        buffer.seek(0)
        return buffer
