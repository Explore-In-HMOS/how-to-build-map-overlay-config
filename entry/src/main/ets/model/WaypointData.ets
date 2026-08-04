import { mapCommon } from '@kit.MapKit';

export enum WaypointCategory {
  STANDARD = 'standard',
  HIDDEN_GEM = 'hidden_gem'
}

export interface Waypoint {
  id: string;
  name: string;
  category: WaypointCategory;
  position: mapCommon.LatLng;
  priority: number;
}

export const WAYPOINTS: Waypoint[] = [
  {
    id: 'bosbaan-start',
    name: 'Bosbaan Start',
    category: WaypointCategory.STANDARD,
    position: { latitude: 52.3183, longitude: 4.8306 },
    priority: 1
  },
  {
    id: 'watertoren-view',
    name: 'Watertoren Viewpoint',
    category: WaypointCategory.STANDARD,
    position: { latitude: 52.3145, longitude: 4.8280 },
    priority: 1
  },
  {
    id: 'hidden-orchard',
    name: 'Hidden Orchard Clearing',
    category: WaypointCategory.HIDDEN_GEM,
    position: { latitude: 52.3110, longitude: 4.8250 },
    priority: 2
  },
  {
    id: 'bosmuseum-rest',
    name: 'Bosmuseum Rest Area',
    category: WaypointCategory.STANDARD,
    position: { latitude: 52.3080, longitude: 4.8230 },
    priority: 1
  }
];

export const REST_ZONE_POLYGON: mapCommon.LatLng[] = [
  { latitude: 52.3086, longitude: 4.8222 },
  { latitude: 52.3086, longitude: 4.8240 },
  { latitude: 52.3072, longitude: 4.8240 },
  { latitude: 52.3072, longitude: 4.8222 }
];

export const TRAIL_CENTER: mapCommon.LatLng = { latitude: 52.3145, longitude: 4.8280 };
