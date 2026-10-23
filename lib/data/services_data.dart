/// Shared list of resident-facing service shortcuts (permits, utilities, ...).
///
/// Both the Home screen's horizontal tiles and the Resident hub list read
/// `hubServices`, so the two screens always show the same items. Tapping a
/// service opens a sheet in the hub listing the offices for the user's county
/// (`serviceContactsFor`, backed by `countyServiceDirectory` in
/// `county_data.dart`).
library;

import 'package:flutter/material.dart';

import '../models/contact.dart';
import 'county_data.dart';

/// A resident-facing local service shortcut (city services, permits, etc).
///
/// This used to be defined twice — once inline in `HomeScreen` (6 items)
/// and once inline in `ResidentHubScreen` (7 items, slightly different
/// names/icons) — so the two screens quietly disagreed with each other.
/// It now lives in one place and both screens read from it.
class HubService {
  /// Short name shown on the tile; also the lookup key in the county service directory.
  final String title;
  /// One-line hint about what the service covers.
  final String subtitle;
  /// Icon shown on the tile.
  final IconData icon;

  /// Creates a service shortcut; all fields are required.
  const HubService({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// The service shortcuts, in display order. The `title` doubles as the key into
/// `countyServiceDirectory`, so the two must be kept in sync.
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
    title: 'Household Utilities',
    subtitle: 'Street lights, power, water, and outages',
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
    title: 'Animal services',
    subtitle: 'Strays, leash laws, licenses, and rabies',
    icon: Icons.pets_outlined,
  ),
  HubService(
    title: 'Safety & emergency',
    subtitle: '911, police, fire, and storm planning',
    icon: Icons.emergency_outlined,
  ),
  HubService(
    title: 'Social services',
    subtitle: 'Food, cash, child care, and seniors',
    icon: Icons.volunteer_activism_outlined,
  ),
  HubService(
    title: 'Community programs',
    subtitle: 'Events, alerts, and local help',
    icon: Icons.groups_outlined,
  ),
];

/// Offices to contact for a hub service in the given county ("County, ST" key). Empty when that
/// county has no entries yet, so the hub can say so instead of showing a blank.
List<Contact> serviceContactsFor(String? countyKey, String serviceTitle) {
  if (countyKey == null) return const [];
  return countyServiceDirectory[countyKey]?[serviceTitle] ?? const [];
}
