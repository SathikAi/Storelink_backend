import csv
from io import StringIO
from datetime import datetime, timezone
from app.schemas.report import (
    SalesReportResponse,
    ProductReportResponse,
    CustomerReportResponse
)


class CSVGenerator:
    
    @staticmethod
    def generate_sales_report(report_data: SalesReportResponse) -> StringIO:
        output = StringIO()
        writer = csv.writer(output)
        
        writer.writerow([f"Sales Report - {report_data.business_name}"])
        writer.writerow([f"Period: {report_data.from_date or 'Start'} to {report_data.to_date or 'End'}"])
        writer.writerow([f"Generated: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}"])
        writer.writerow([])
        
        writer.writerow(['Summary'])
        writer.writerow(['Total Orders', report_data.total_orders])
        writer.writerow(['Total Revenue (₹)', f'{report_data.total_revenue:.2f}'])
        writer.writerow(['Total Tax (₹)', f'{report_data.total_tax:.2f}'])
        writer.writerow(['Total Discount (₹)', f'{report_data.total_discount:.2f}'])
        writer.writerow([])
        
        writer.writerow(['Order Number', 'Customer Name', 'Order Date', 'Status', 'Payment Status', 
                        'Subtotal (₹)', 'Tax (₹)', 'Discount (₹)', 'Total Amount (₹)'])
        
        for order in report_data.orders:
            writer.writerow([
                order.order_number,
                order.customer_name or 'Walk-in',
                order.order_date,
                order.status,
                order.payment_status,
                f'{order.subtotal:.2f}',
                f'{order.tax_amount:.2f}',
                f'{order.discount_amount:.2f}',
                f'{order.total_amount:.2f}'
            ])
        
        output.seek(0)
        return output
    
    @staticmethod
    def generate_product_report(report_data: ProductReportResponse) -> StringIO:
        output = StringIO()
        writer = csv.writer(output)
        
        writer.writerow([f"Product Sales Report - {report_data.business_name}"])
        writer.writerow([f"Period: {report_data.from_date or 'Start'} to {report_data.to_date or 'End'}"])
        writer.writerow([f"Generated: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}"])
        writer.writerow([])
        
        writer.writerow(['Summary'])
        writer.writerow(['Total Products Sold', report_data.total_products_sold])
        writer.writerow(['Total Revenue (₹)', f'{report_data.total_revenue:.2f}'])
        writer.writerow([])
        
        writer.writerow(['Product Name', 'SKU', 'Category', 'Quantity Sold', 'Orders Count', 'Total Revenue (₹)'])
        
        for product in report_data.products:
            writer.writerow([
                product.product_name,
                product.product_sku or '-',
                product.category_name or '-',
                product.total_quantity_sold,
                product.orders_count,
                f'{product.total_revenue:.2f}'
            ])
        
        output.seek(0)
        return output
    
    @staticmethod
    def generate_customer_report(report_data: CustomerReportResponse) -> StringIO:
        output = StringIO()
        writer = csv.writer(output)
        
        writer.writerow([f"Customer Report - {report_data.business_name}"])
        writer.writerow([f"Period: {report_data.from_date or 'Start'} to {report_data.to_date or 'End'}"])
        writer.writerow([f"Generated: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}"])
        writer.writerow([])
        
        writer.writerow(['Summary'])
        writer.writerow(['Total Customers', report_data.total_customers])
        writer.writerow(['Total Revenue (₹)', f'{report_data.total_revenue:.2f}'])
        writer.writerow([])
        
        writer.writerow(['Customer Name', 'Phone', 'Email', 'Total Orders', 'Total Spent (₹)', 'Last Order Date'])
        
        for customer in report_data.customers:
            writer.writerow([
                customer.customer_name,
                customer.customer_phone,
                customer.customer_email or '-',
                customer.total_orders,
                f'{customer.total_spent:.2f}',
                customer.last_order_date or '-'
            ])
        
        output.seek(0)
        return output
