import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { ArcButton, ArcButtonOptions, ArcButtonPosition, ArcButtonStyleMode } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  WAYPOINTS, REST_ZONE_POLYGON, TRAIL_CENTER, Waypoint, WaypointCategory
} from '../model/WaypointData';
import { Constants } from '../constants/Constants';

const DOMAIN = 0x0000;
const TAG = 'TrailWaypointConfig';

@Entry
@Component
struct Index {
  @State activeIndex: number = 0;
  @State isInRestZone: boolean = false;
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private mapEventManager?: map.MapEventManager;
  private mapCallback?: AsyncCallback<map.MapComponentController>;
  private annotations: map.PointAnnotation[] = [];
  private alertAnnotation?: map.PointAnnotation;
  private restZonePolygon?: map.MapPolygon;
  private previousActiveIndex: number = -1;

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: TRAIL_CENTER,
        zoom: Constants.MAP_DEFAULT_ZOOM
      },
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true
    };

    this.mapCallback = async (err, mapController) => {
      if (err) {
        hilog.error(DOMAIN, TAG, 'Map init failed. Code: %{public}d', err.code);
        return;
      }
      this.mapController = mapController;
      this.mapEventManager = this.mapController.getEventManager();
      this.mapEventManager.on('pointAnnotationClick', (annotation: map.PointAnnotation) => {
        this.onMarkerTapped(annotation);
      });

      await this.setupRestZonePolygon();
      await this.setupWaypointOverlays();
      await this.setupAlertOverlay();
      this.selectWaypoint(0);
    };
  }

  onPageShow(): void {
    if (this.mapController) {
      this.mapController.show();
    }
  }

  onPageHide(): void {
    if (this.mapController) {
      this.mapController.hide();
    }
  }

  private async setupRestZonePolygon(): Promise<void> {
    if (!this.mapController) {
      return;
    }
    const polygonOptions: mapCommon.MapPolygonOptions = {
      points: REST_ZONE_POLYGON,
      fillColor: Constants.REST_ZONE_FILL_COLOR,
      strokeColor: Constants.REST_ZONE_STROKE_COLOR,
      strokeWidth: Constants.REST_ZONE_STROKE_WIDTH,
      visible: true,
      zIndex: Constants.Z_INDEX_BASE
    };
    try {
      this.restZonePolygon = await this.mapController.addPolygon(polygonOptions);
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Polygon add failed. Code: %{public}d', e.code);
    }
  }

  /** Adds one PointAnnotation per waypoint and configures BaseOverlay /
   *  BasePriorityOverlay properties plus the looping idle-pulse animation. */
  private async setupWaypointOverlays(): Promise<void> {
    if (!this.mapController) {
      return;
    }
    for (let i = 0; i < WAYPOINTS.length; i++) {
      const waypoint: Waypoint = WAYPOINTS[i];
      const params: mapCommon.PointAnnotationParams = {
        position: waypoint.position,
        titles: [{
          content: waypoint.name,
          fontSize: Constants.TITLE_FONT_SIZE_BASE,
          strokeColor: Constants.TITLE_STROKE_COLOR,
          strokeWidth: Constants.TITLE_STROKE_WIDTH
        }],
        icon: '',
        priority: waypoint.priority,
        visible: true,
        zIndex: Constants.Z_INDEX_BASE
      };

      try {
        const annotation: map.PointAnnotation =
          await this.mapController.addPointAnnotation(params);
        annotation.setTag(waypoint.id);
        if (waypoint.category === WaypointCategory.HIDDEN_GEM) {
          annotation.setZoom(Constants.HIDDEN_GEM_MIN_ZOOM, Constants.HIDDEN_GEM_MAX_ZOOM);
        }

        this.startIdlePulse(annotation);
        this.annotations.push(annotation);
      } catch (e) {
        hilog.error(DOMAIN, TAG, 'Annotation add failed. Code: %{public}d', e.code);
      }
    }
  }

  /** Adds the "Resting point nearby" alert overlay, initially invisible.
   *  Its visibility is toggled by setVisible() (BaseOverlay). */
  private async setupAlertOverlay(): Promise<void> {
    if (!this.mapController) {
      return;
    }
    const centroid: mapCommon.LatLng = {
      latitude: (REST_ZONE_POLYGON[0].latitude + REST_ZONE_POLYGON[2].latitude) / 2,
      longitude: (REST_ZONE_POLYGON[0].longitude + REST_ZONE_POLYGON[2].longitude) / 2
    };
    const params: mapCommon.PointAnnotationParams = {
      position: centroid,
      titles: [{
        content: 'Rest Zone',
        fontSize: Constants.ALERT_FONT_SIZE
      }],
      icon: '',
      priority: 0,
      visible: false,
      zIndex: Constants.Z_INDEX_ALERT
    };
    try {
      this.alertAnnotation = await this.mapController.addPointAnnotation(params);
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Alert annotation failed. Code: %{public}d', e.code);
    }
  }

  // ────────────────────────── ANIMATIONS ──────────────────────────────────

  /** BasePriorityOverlay.setAnimation(): a soft looping transparency pulse
   *  configured with AnimationFillMode.BACKWARDS + AnimationRepeatMode.RESTART. */
  private startIdlePulse(annotation: map.PointAnnotation): void {
    const anim: map.AlphaAnimation =
      new map.AlphaAnimation(Constants.PULSE_ALPHA_FROM, Constants.PULSE_ALPHA_TO);
    anim.setDuration(Constants.PULSE_DURATION_MS);
    anim.setFillMode(map.AnimationFillMode.BACKWARDS);
    anim.setRepeatMode(map.AnimationRepeatMode.RESTART);
    anim.setRepeatCount(Constants.PULSE_REPEAT_COUNT);
    annotation.setAnimation(anim);
    annotation.startAnimation();
  }

  /** FontSizeAnimation via setTitleAnimation() + startTitleAnimation():
   *  grows the active waypoint's label then eases back (REVERSE). */
  private playTitleEmphasis(annotation: map.PointAnnotation): void {
    const anim: map.FontSizeAnimation =
      new map.FontSizeAnimation(Constants.TITLE_FONT_SIZE_BASE, Constants.TITLE_FONT_SIZE_ACTIVE);
    anim.setDuration(Constants.TITLE_ANIM_DURATION_MS);
    anim.setFillMode(map.AnimationFillMode.FORWARDS);
    anim.setRepeatMode(map.AnimationRepeatMode.REVERSE);
    anim.setRepeatCount(Constants.TITLE_ANIM_REPEAT_COUNT);
    annotation.setTitleAnimation(anim);
    annotation.startTitleAnimation();
  }

  private selectWaypoint(newIndex: number): void {
    if (newIndex < 0 || newIndex >= WAYPOINTS.length) {
      return;
    }
    if (this.previousActiveIndex >= 0 && this.previousActiveIndex < this.annotations.length) {
      const prev: map.PointAnnotation = this.annotations[this.previousActiveIndex];
      if (prev) {
        prev.setZIndex(Constants.Z_INDEX_BASE);
      }
    }

    this.activeIndex = newIndex;
    this.previousActiveIndex = newIndex;

    if (newIndex < this.annotations.length) {
      const active: map.PointAnnotation = this.annotations[newIndex];
      if (active) {
        active.setZIndex(Constants.Z_INDEX_ACTIVE);
        this.playTitleEmphasis(active);
      }
    }

    this.updateProximityAlert(newIndex);
  }

  /** SpatialRelationUtil.isPointContainedInPolygon(): checks whether the
   *  simulated hiker position has entered the rest-zone polygon, and
   *  toggles the alert overlay via setVisible() (BaseOverlay). */
  private updateProximityAlert(index: number): void {
    const hikerPos: mapCommon.LatLng = WAYPOINTS[index].position;
    const isInside: boolean =
      map.SpatialRelationUtil.isPointContainedInPolygon(REST_ZONE_POLYGON, hikerPos);
    this.isInRestZone = isInside;
    if (this.alertAnnotation) {
      this.alertAnnotation.setVisible(isInside);
    }
  }

  private onMarkerTapped(annotation: map.PointAnnotation): void {
    const tag: string = annotation.getTag() as string;
    const idx: number = WAYPOINTS.findIndex((wp: Waypoint) => wp.id === tag);
    if (idx >= 0) {
      this.selectWaypoint(idx);
    }
  }

  private goPrevious(): void {
    this.selectWaypoint(Math.max(0, this.activeIndex - 1));
  }

  private goNext(): void {
    this.selectWaypoint(Math.min(WAYPOINTS.length - 1, this.activeIndex + 1));
  }

  build() {
    Stack() {
      MapComponent({ mapOptions: this.mapOptions, mapCallback: this.mapCallback })
        .width('100%')
        .height('100%');

      RelativeContainer() {
        Column() {
          Text(WAYPOINTS[this.activeIndex].name)
            .fontSize($r('app.float.chip_name_size'))
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.chip_text'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });

          Text(`${this.activeIndex + 1} / ${WAYPOINTS.length}`)
            .fontSize($r('app.float.chip_step_size'))
            .fontColor($r('app.color.chip_step_text'))
            .margin({ top: 2 });
        }
        .backgroundColor($r('app.color.chip_bg'))
        .borderRadius($r('app.float.chip_radius'))
        .padding({
          left: $r('app.float.chip_padding_h'),
          right: $r('app.float.chip_padding_h'),
          top: $r('app.float.chip_padding_v'),
          bottom: $r('app.float.chip_padding_v')
        })
        .alignItems(HorizontalAlign.Center)
        .id('waypointChip')
        .alignRules({
          top: { anchor: '__container__', align: VerticalAlign.Top },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .margin({ top: $r('app.float.chip_margin_top') });

        if (this.isInRestZone) {
          Row() {
            Text($r('app.string.rest_zone_alert'))
              .fontSize($r('app.float.alert_font_size'))
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.alert_text'));
          }
          .backgroundColor($r('app.color.alert_bg'))
          .borderRadius($r('app.float.alert_radius'))
          .padding({
            left: $r('app.float.alert_padding_h'),
            right: $r('app.float.alert_padding_h'),
            top: $r('app.float.alert_padding_v'),
            bottom: $r('app.float.alert_padding_v')
          })
          .justifyContent(FlexAlign.Center)
          .id('restZoneAlert')
          .alignRules({
            center: { anchor: '__container__', align: VerticalAlign.Center },
            middle: { anchor: '__container__', align: HorizontalAlign.Center }
          });
        }

        ArcButton({
          options: new ArcButtonOptions({
            label: $r('app.string.btn_previous'),
            position: ArcButtonPosition.TOP_EDGE,
            styleMode: ArcButtonStyleMode.EMPHASIZED_LIGHT,
            onClick: () => {
              this.goPrevious();
            }
          })
        })
          .id('arcBtnPrevious')
          .alignRules({
            top: { anchor: '__container__', align: VerticalAlign.Top },
            middle: { anchor: '__container__', align: HorizontalAlign.Center }
          });

        ArcButton({
          options: new ArcButtonOptions({
            label: $r('app.string.btn_next'),
            position: ArcButtonPosition.BOTTOM_EDGE,
            styleMode: ArcButtonStyleMode.EMPHASIZED_LIGHT,
            onClick: () => {
              this.goNext();
            }
          })
        })
          .id('arcBtnNext')
          .alignRules({
            bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
            middle: { anchor: '__container__', align: HorizontalAlign.Center }
          });
      }
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.Transparent);
    }
    .width('100%')
    .height('100%');
  }
}
