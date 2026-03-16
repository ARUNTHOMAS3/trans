// PATH: lib/modules/auth/presentation/organization_management_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import '../models/organization_model.dart';

class OrganizationManagementPage extends ConsumerStatefulWidget {
  const OrganizationManagementPage({super.key});

  @override
  ConsumerState<OrganizationManagementPage> createState() =>
      _OrganizationManagementPageState();
}

class _OrganizationManagementPageState
    extends ConsumerState<OrganizationManagementPage> {
  List<Organization> _organizations = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  Future<void> _loadOrganizations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(Duration(seconds: 1));

      // Mock data for demonstration
      final mockOrgs = [
        Organization(
          id: 'org1',
          name: 'ABC Corporation',
          legalName: 'ABC Corporation Pvt Ltd',
          gstin: '27AABCCDEEFFGHH',
          pan: 'ABCDE1234F',
          phone: '+91 9876543210',
          email: 'info@abccorp.com',
          website: 'www.abccorp.com',
          address: Address(
            street: '123 Business Park',
            city: 'Mumbai',
            state: 'Maharashtra',
            country: 'India',
            postalCode: '400001',
          ),
          currency: 'INR',
          timezone: 'Asia/Kolkata',
          isActive: true,
          createdAt: DateTime.now().subtract(Duration(days: 365)),
          updatedAt: DateTime.now(),
        ),
        Organization(
          id: 'org2',
          name: 'XYZ Enterprises',
          legalName: 'XYZ Enterprises Ltd',
          gstin: '29ZZZYYYYXXXXWWW',
          pan: 'XYZAB5678C',
          phone: '+91 9876543211',
          email: 'contact@xyzenterprises.com',
          website: 'www.xyzenterprises.com',
          address: Address(
            street: '456 Industrial Area',
            city: 'Bangalore',
            state: 'Karnataka',
            country: 'India',
            postalCode: '560001',
          ),
          currency: 'INR',
          timezone: 'Asia/Kolkata',
          isActive: true,
          createdAt: DateTime.now().subtract(Duration(days: 180)),
          updatedAt: DateTime.now(),
        ),
      ];

      setState(() {
        _organizations = mockOrgs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load organizations: $e')),
      );
    }
  }

  void _showAddOrgDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add organization functionality coming soon')),
    );
  }

  void _showEditOrgDialog(Organization org) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit organization functionality coming soon')),
    );
  }

  Future<void> _deleteOrg(Organization org) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Organization'),
        content: Text(
          'Are you sure you want to delete ${org.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _organizations.removeWhere((o) => o.id == org.id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Organization deleted successfully')),
      );
    }
  }

  List<Organization> get _filteredOrganizations {
    if (_searchQuery.isEmpty) return _organizations;

    return _organizations.where((org) {
      final query = _searchQuery.toLowerCase();
      return org.name.toLowerCase().contains(query) ||
          org.legalName?.toLowerCase().contains(query) == true ||
          org.gstin?.toLowerCase().contains(query) == true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Organization Management'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search organizations...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Add Organization Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _showAddOrgDialog,
                  icon: Icon(Icons.add),
                  label: Text('Add Organization'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Organizations List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredOrganizations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No organizations found',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Add your first organization to get started'
                              : 'No organizations match your search',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _filteredOrganizations.length,
                    itemBuilder: (context, index) {
                      final org = _filteredOrganizations[index];
                      return _buildOrgCard(org);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrgCard(Organization org) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.business,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        org.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (org.legalName != null) ...[
                        SizedBox(height: 4),
                        Text(
                          org.legalName!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditOrgDialog(org);
                        break;
                      case 'delete':
                        _deleteOrg(org);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            size: 20,
                            color: AppTheme.errorRed,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: AppTheme.errorRed),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 16),

            // Details Grid
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                if (org.gstin != null)
                  _buildDetailChip(Icons.account_balance, 'GSTIN', org.gstin!),
                if (org.pan != null)
                  _buildDetailChip(Icons.credit_card, 'PAN', org.pan!),
                _buildDetailChip(
                  Icons.location_on,
                  'Location',
                  '${org.address.city}, ${org.address.state}',
                ),
                _buildDetailChip(Icons.language, 'Currency', org.currency),
              ],
            ),

            SizedBox(height: 16),

            // Contact Info
            if (org.phone != null || org.email != null) ...[
              Divider(),
              SizedBox(height: 8),
              Wrap(
                spacing: 16,
                children: [
                  if (org.phone != null)
                    _buildContactItem(Icons.phone, org.phone!),
                  if (org.email != null)
                    _buildContactItem(Icons.email, org.email!),
                ],
              ),
            ],

            // Status
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: org.isActive
                    ? Colors.green.withValues(alpha: 0.1)
                    : AppTheme.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                org.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: org.isActive ? Colors.green : AppTheme.errorRed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        SizedBox(width: 6),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
