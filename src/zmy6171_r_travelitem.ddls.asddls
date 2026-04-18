@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Flight Travel Item'
define view entity ZMY6171_R_TRAVELITEM
  as select from zmy6171_tritem
  association to parent ZMY6171_R_Travel as _Travel
  on $projection.AgencyId = _Travel.AgencyId
  and $projection.TravelId = _Travel.TravelId
  {
    key item_uuid            as ItemUuid,
        agency_id            as AgencyId,
        travel_id            as TravelId,
        carrier_id           as CarrierId,
        connection_id        as ConnectionId,
        flight_date          as FlightDate,
        booking_id           as BookingId,
        passenger_first_name as PassengerFirstName,
        passenger_last_name  as PassengerLastName,
        @Semantics.systemDateTime.lastChangedAt: true
        changed_at           as ChangedAt,
        @Semantics.user.lastChangedBy: true
        changed_by           as ChangedBy,
        @Semantics.systemDateTime.localInstanceLastChangedAt: true
        loc_changed_at       as LocChangedAt,
        _Travel
  }
