@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Flight Travel (Data Model)'
define root view entity ZMY6171_R_Travel
  as select from zmy6171_travel
  composition [0..*] of ZMY6171_R_TRAVELITEM as _TravelItem
  {
    key agency_id   as AgencyId,
    key travel_id   as TravelId,
        description as Description,
        customer_id as CustomerId,
        begin_date  as BeginDate,
        end_date    as EndDate,
        status      as Status,
        @Semantics.systemDateTime.lastChangedAt
        changed_at  as ChangedAt,
        @Semantics.user.lastChangedBy
        changed_by  as ChangedBy,
        @Semantics.systemDateTime.localInstanceLastChangedAt
        loc_changed_at as LocChangedAt,
        _TravelItem
  }

