import 'package:flutter/material.dart';

/// A resident-facing local service shortcut (city services, permits, etc).
///
/// This used to be defined twice — once inline in `HomeScreen` (6 items)
/// and once inline in `ResidentHubScreen` (7 items, slightly different
/// names/icons) — so the two screens quietly disagreed with each other.
/// It now lives in one place and both screens read from it.
class HubService {
  final String title;
  final String subtitle;
  final IconData icon;

  const HubService({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

const List<HubService> hubServices = [
  HubService(
    title: 'City services',
    subtitle: 'Trash, parks, streets, and permits',
    icon: Icons.location_city_outlined,
  ),
  HubService(
    title: 'Permits',
    subtitle: 'Building, zoning, and inspections',
    icon: Icons.assignment_outlined,
  ),
  HubService(
    title: 'Utilities',
    subtitle: 'Water, power, billing, and outages',
    icon: Icons.water_drop_outlined,
  ),
  HubService(
    title: 'Public records',
    subtitle: 'Requests, documents, and meetings',
    icon: Icons.folder_open_outlined,
  ),
  HubService(
    title: 'Transit info',
    subtitle: 'Routes, passes, and schedules',
    icon: Icons.directions_bus_outlined,
  ),
  HubService(
    title: 'County offices',
    subtitle: 'Assessors, health, and elections',
    icon: Icons.account_balance_outlined,
  ),
  HubService(
    title: 'Community programs',
    subtitle: 'Events, alerts, and local help',
    icon: Icons.groups_outlined,
  ),
];
