import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/business_provider.dart';
import 'business_edit_screen.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BusinessProvider>(context, listen: false).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Profile'),
        actions: [
          Consumer<BusinessProvider>(
            builder: (context, provider, _) {
              if (provider.business != null) {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BusinessEditScreen(),
                      ),
                    );
                    if (result == true) {
                      provider.loadProfile();
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<BusinessProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadProfile(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final business = provider.business;
          if (business == null) {
            return const Center(child: Text('No business profile found'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadProfile(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.blue.shade100,
                          backgroundImage: business.logoUrl != null
                              ? NetworkImage(business.logoUrl!)
                              : null,
                          child: business.logoUrl == null
                              ? Text(
                                  business.businessName[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 48),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          business.businessName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: business.plan == 'PAID'
                                ? Colors.green
                                : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${business.plan} Plan',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (business.planExpiryDate != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Expires: ${DateFormat('MMM dd, yyyy').format(business.planExpiryDate!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildInfoCard(
                    context,
                    'Contact Information',
                    [
                      if (business.phone != null)
                        _buildInfoRow(Icons.phone, 'Phone', business.phone!),
                      if (business.email != null)
                        _buildInfoRow(Icons.email, 'Email', business.email!),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    'Business Details',
                    [
                      if (business.businessType != null)
                        _buildInfoRow(
                          Icons.business,
                          'Type',
                          business.businessType!,
                        ),
                      if (business.gstin != null)
                        _buildInfoRow(Icons.receipt, 'GSTIN', business.gstin!),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    'Address',
                    [
                      if (business.address != null)
                        _buildInfoRow(
                          Icons.location_on,
                          'Street',
                          business.address!,
                        ),
                      if (business.city != null)
                        _buildInfoRow(Icons.location_city, 'City', business.city!),
                      if (business.state != null)
                        _buildInfoRow(Icons.map, 'State', business.state!),
                      if (business.pincode != null)
                        _buildInfoRow(
                          Icons.pin_drop,
                          'Pincode',
                          business.pincode!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
