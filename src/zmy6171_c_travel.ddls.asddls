@EndUserText.label: 'Flight Travel (Projection)'
@Search.searchable: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity ZMY6171_C_Travel
  provider contract transactional_query
  as projection on ZMY6171_R_Travel
  {
    key AgencyId,
    key TravelId,
    @Search.defaultSearchElement: true
    Description,
    @Search.defaultSearchElement: true
    @Consumption.valueHelpDefinition: [
    { entity : { name: '/DMO/I_Customer_StdVH',
                 element: 'CustomerID' }}
                                      ]
    CustomerId,
    BeginDate,
    EndDate,
    Status,
    ChangedAt,
    ChangedBy,
    LocChangedAt,
    _TravelItem : redirected to composition child ZMY6171_C_TRAVELITEM
  }

