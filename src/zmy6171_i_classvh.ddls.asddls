@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Class Value Help'
@ObjectModel.dataCategory: #VALUE_HELP
@Search.searchable: true

define view entity ZMY6171_I_CLASSVH
  as select distinct from zmy6171_tritem
{
  @Search.defaultSearchElement: true
  key zzclasszit as ClassID
}
