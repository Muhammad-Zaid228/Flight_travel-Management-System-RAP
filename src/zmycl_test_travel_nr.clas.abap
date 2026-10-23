CLASS zmycl_test_travel_nr DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.


CLASS zmycl_test_travel_nr IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    DATA lt_interval TYPE cl_numberrange_intervals=>nr_interval.
    DATA ls_interval TYPE cl_numberrange_intervals=>nr_nriv_line.

    DATA lv_error     TYPE cl_numberrange_intervals=>nr_error.
    DATA lv_warning   TYPE cl_numberrange_intervals=>nr_warning.
    DATA lv_error_iv  TYPE cl_numberrange_intervals=>nr_error_iv.
    DATA lv_error_inf TYPE cl_numberrange_intervals=>nr_error_inf.

    DATA lv_number       TYPE cl_numberrange_runtime=>nr_number.
    DATA lv_returncode   TYPE cl_numberrange_runtime=>nr_returncode.
    DATA lv_returned_qty TYPE cl_numberrange_runtime=>nr_returned_quantity.

    "--------------------------------------------------
    " TASK 1: Create interval 01
    "--------------------------------------------------
    TRY.

        cl_numberrange_intervals=>read(
          EXPORTING
            object       = 'ZTRAVEL_NR'
            nr_range_nr1 = '01'
          IMPORTING
            interval     = lt_interval
        ).

        out->write( 'Interval 01 already exists. Skipping creation.' ).

      CATCH cx_nr_object_not_found.
      CATCH cx_nr_subobject.
      CATCH cx_number_ranges.

        CLEAR lt_interval.

        ls_interval-nrrangenr  = '01'.
        ls_interval-fromnumber = '00000001'.
        ls_interval-tonumber   = '99999999'.
        ls_interval-nrlevel    = '00000000'.
        ls_interval-externind  = space.
        ls_interval-procind    = 'I'.

        APPEND ls_interval TO lt_interval.

        TRY.
            cl_numberrange_intervals=>create(
              EXPORTING
                object   = 'ZTRAVEL_NR'
                interval = lt_interval
              IMPORTING
                error     = lv_error
                error_inf = lv_error_inf
                error_iv  = lv_error_iv
                warning   = lv_warning
            ).

            IF lv_error = abap_true.
              out->write( 'TASK 1 FAILED: Interval creation reported an error.' ).
              RETURN.
            ENDIF.

            out->write( 'TASK 1: Interval creation completed.' ).

          CATCH cx_nr_object_not_found INTO DATA(lx_create_object).
            out->write( lx_create_object->get_text( ) ).
            RETURN.

          CATCH cx_number_ranges INTO DATA(lx_create_range).
            out->write( lx_create_range->get_text( ) ).
            RETURN.
        ENDTRY.

    ENDTRY.

    "--------------------------------------------------
    " TASK 2: Get the next number
    "--------------------------------------------------
    TRY.

        cl_numberrange_runtime=>number_get(
          EXPORTING
            object           = 'ZTRAVEL_NR'
            nr_range_nr      = '01'
            quantity         = 1
          IMPORTING
            number           = lv_number
            returncode       = lv_returncode
            returned_quantity = lv_returned_qty
        ).

        IF lv_returned_qty = 1.
          out->write( |TASK 2: Generated number = { lv_number }| ).
          out->write( |Return code = { lv_returncode }| ).
        ELSE.
          out->write( 'TASK 2 FAILED: No number was returned.' ).
        ENDIF.

      CATCH cx_nr_object_not_found INTO DATA(lx_get_object).
        out->write( lx_get_object->get_text( ) ).

      CATCH cx_number_ranges INTO DATA(lx_get_range).
        out->write( lx_get_range->get_text( ) ).
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
