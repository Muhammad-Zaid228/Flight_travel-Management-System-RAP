"! <p class="shorttext synchronized" lang="en">Fill DB Table with data</p>
"! Use a copy of this class to reset your data
"! Fill the constant c_travel_table with the name of your DB tables
"! And execute as console app (F9)
CLASS zmycl_6171_travel_fill DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .

    CONSTANTS c_travel_table  TYPE tabname VALUE 'ZMY6171_TRAVEL'.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS zmycl_6171_travel_fill IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    TRY.
        DATA(dbtable) = NEW lcl_dbtable( c_travel_table ).

        IF dbtable->check_compatible( ) <> abap_true.

        ENDIF.

        IF dbtable->is_empty( ) <> abap_true.
          dbtable->delete_data( ).
        ENDIF.

        dbtable->generate_data( ).


        "Assign an existing travel agency to the current user
        DATA(lv_user) =
          cl_abap_context_info=>get_user_technical_name( ).

        DATA lv_agency_id TYPE zuser_agency-agency_id.

        "Get an agency ID from the generated travel records
        SELECT MIN( agency_id )
          FROM zmy6171_travel
          INTO @lv_agency_id.

        IF lv_user IS INITIAL OR lv_agency_id IS INITIAL.
          out->write( 'User or agency ID could not be determined.' ).
          RETURN.
        ENDIF.

        "Prepare the user-agency assignment
        DATA(ls_user_agency) = VALUE zuser_agency(
          user_name = lv_user
          agency_id = lv_agency_id
        ).

        "Replace the current user's assignment
        DELETE FROM zuser_agency
          WHERE user_name = @lv_user.

        INSERT zuser_agency FROM @ls_user_agency.

        IF sy-subrc = 0.
          out->write(
            |Agency { lv_agency_id } assigned to user { lv_user }.|
          ).
        ELSE.
          out->write( 'Failed to insert the user-agency assignment.' ).
        ENDIF.


      CATCH cx_abap_not_a_table.
        out->write( |{ c_travel_table } is not the name of a database table| ).
      CATCH cx_abap_not_in_package.
        out->write( |{ c_travel_table } is not a table in software component ZLOCAL| ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
