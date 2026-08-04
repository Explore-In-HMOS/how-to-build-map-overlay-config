/**
 * Map Kit works with plain numbers/enums for zoom levels, animation timing,
 * and priorities (its APIs don't accept ArkUI Resource objects), so these
 * live here as named constants instead of in resources/base/element.
 */
export class Constants {
  static readonly MAP_DEFAULT_ZOOM: number = 15;
  static readonly HIDDEN_GEM_MIN_ZOOM: number = 16;
  static readonly HIDDEN_GEM_MAX_ZOOM: number = 20;

  // BaseOverlay.setZIndex() layering
  static readonly Z_INDEX_BASE: number = 10;
  static readonly Z_INDEX_ACTIVE: number = 100;
  static readonly Z_INDEX_ALERT: number = 200;

  // AlphaAnimation
  static readonly PULSE_ALPHA_FROM: number = 0.35;
  static readonly PULSE_ALPHA_TO: number = 1;
  static readonly PULSE_DURATION_MS: number = 1400;
  static readonly PULSE_REPEAT_COUNT: number = -1; // infinite

  static readonly TITLE_FONT_SIZE_BASE: number = 15;
  static readonly TITLE_FONT_SIZE_ACTIVE: number = 26;
  static readonly TITLE_ANIM_DURATION_MS: number = 500;
  static readonly TITLE_ANIM_REPEAT_COUNT: number = 1;
  static readonly TITLE_STROKE_COLOR: number = 0xFFFFFFFF;
  static readonly TITLE_STROKE_WIDTH: number = 2;

  static readonly ALERT_FONT_SIZE: number = 14;

  static readonly REST_ZONE_FILL_COLOR: number = 0x3300C853;
  static readonly REST_ZONE_STROKE_COLOR: number = 0xFF00C853;
  static readonly REST_ZONE_STROKE_WIDTH: number = 4;
}
