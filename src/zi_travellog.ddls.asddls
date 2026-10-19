@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel Log'

define root view entity ZI_TRAVELLOG
  as select from ztravellog
{
  key log_uuid  as LogUuid,
      agency_id as AgencyId,
      travel_id as TravelId,
      origin    as Origin
}
