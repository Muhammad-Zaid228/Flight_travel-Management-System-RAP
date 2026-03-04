CLASS zmycl_6171_eml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .

    CONSTANTS c_agency_id TYPE /dmo/agency_id VALUE '70041'.
    CONSTANTS c_travel_id TYPE /dmo/travel_id VALUE '8925'.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zmycl_6171_eml IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    READ ENTITIES OF ZMY6171_R_TRAVEL
        ENTITY Travel
         ALL FIELDS WITH
          VALUE #( ( AgencyId = c_agency_id
                     TravelId = c_travel_id ) )

          RESULT DATA(travels)
          FAILED DATA(failed).

   IF failed IS NOT INITIAL.
        out->write( 'Travel not found' ).

   ELSE.
        MODIFY ENTITIES OF ZMY6171_R_TRAVEL
        ENTITY Travel
          UPDATE FIELDS ( Description )
            WITH VALUE #( ( AgencyId = c_agency_id
                            TravelId = c_travel_id
                            Description = 'My New Description' ) )

            FAILED failed.

         IF failed IS INITIAL.
            COMMIT ENTITIES.
            out->write( 'Description Successfully updated' ).
         ELSE.
            ROLLBACK ENTITIES.
            out->write( 'Failed to update Description' ).
         ENDIF.
    ENDIF.

  ENDMETHOD.

ENDCLASS.

