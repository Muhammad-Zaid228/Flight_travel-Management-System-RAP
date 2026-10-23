*"* Local helper class for database table operations

CLASS lcl_dbtable DEFINITION.

  PUBLIC SECTION.

    DATA tabname TYPE tabname READ-ONLY.

    METHODS constructor
      IMPORTING
        i_tabname TYPE tabname
      RAISING
        cx_abap_not_a_table
        cx_abap_not_in_package.

    METHODS is_empty
      RETURNING VALUE(r_result) TYPE abap_bool.

    METHODS check_compatible
      RETURNING VALUE(r_consistent) TYPE abap_bool.

    METHODS has_totetag_field
      RETURNING VALUE(r_result) TYPE abap_bool.

    METHODS generate_data.

    METHODS delete_data.

  PRIVATE SECTION.

    CONSTANTS c_template TYPE tabname
      VALUE 'ZMY6171_TRAVEL'.

    CONSTANTS c_user TYPE abp_lastchange_user
      VALUE 'GENERATOR'.

    TYPES tt_data TYPE STANDARD TABLE OF zmy6171_travel
      WITH NON-UNIQUE DEFAULT KEY.

    DATA today TYPE cl_abap_context_info=>ty_system_date.

    DATA data_ref TYPE REF TO data.

    DATA components TYPE abap_compdescr_tab.

    DATA totetag_field TYPE abap_compname.

    METHODS add_totetag_field.

    METHODS dbselect.

    METHODS dbsync.

ENDCLASS.


CLASS lcl_dbtable IMPLEMENTATION.

  METHOD constructor.

    TRY.
        cl_abap_dyn_prg=>check_table_name_tab(
          val = i_tabname
          packages = VALUE #(
            ( `ZLOCAL` )
            ( `ZSAP_ABAP_RAP` )
          )
          incl_sub_packages = abap_true
        ).

      CATCH cx_abap_not_in_package.
        RAISE EXCEPTION NEW cx_abap_not_a_table( ).
    ENDTRY.

    tabname = i_tabname.

    components = CAST cl_abap_structdescr(
      cl_abap_typedescr=>describe_by_name( i_tabname )
    )->components.

    IF lines( components ) > 0.
      IF components[ lines( components ) ]-type_kind
           <> cl_abap_typedescr=>typekind_char.

        totetag_field = components[ lines( components ) ]-name.

      ENDIF.
    ENDIF.

    CREATE DATA data_ref TYPE TABLE OF (tabname).

    dbselect( ).

    today = cl_abap_context_info=>get_system_date( ).

  ENDMETHOD.


  METHOD check_compatible.

    DATA(template_components) =
      CAST cl_abap_structdescr(
        cl_abap_typedescr=>describe_by_name( c_template )
      )->components.

    "Allow the target table to omit the final local-change field
    IF lines( template_components ) = lines( components ) + 1.
      DELETE template_components INDEX lines( template_components ).
    ENDIF.

    r_consistent = abap_true.

    IF components <> template_components.
      r_consistent = abap_false.
    ENDIF.

  ENDMETHOD.


  METHOD is_empty.

    r_result = abap_true.

    SELECT SINGLE FROM (tabname)
      FIELDS @abap_false
      INTO @r_result.

  ENDMETHOD.


  METHOD has_totetag_field.

    r_result = COND abap_bool(
      WHEN totetag_field IS NOT INITIAL
      THEN abap_true
      ELSE abap_false
    ).

  ENDMETHOD.


  METHOD generate_data.

    FIELD-SYMBOLS <lt_data> TYPE ANY TABLE.

    "Use an existing agency ID from your own application.
    DATA lv_agency TYPE zmy6171_travel-agency_id
      VALUE '070041'.

    DATA lv_max_travel_id TYPE zmy6171_travel-travel_id.

    "Find the highest existing travel ID.
    SELECT MAX( travel_id )
      FROM zmy6171_travel
      INTO @lv_max_travel_id.

    GET TIME STAMP FIELD DATA(lv_changed_at).

    "Generate five sample travel records.
    DATA(lt_data) = VALUE tt_data(

      "Travel in the past
      (
        agency_id   = lv_agency
        travel_id   = lv_max_travel_id + 1
        description = 'Travel in the past'
        customer_id = 1
        begin_date  = today - 28
        end_date    = today - 14
        status      = ' '
        changed_at  = lv_changed_at
        changed_by  = c_user
      )

      "Ongoing travel
      (
        agency_id   = lv_agency
        travel_id   = lv_max_travel_id + 2
        description = 'Travel ongoing'
        customer_id = 2
        begin_date  = today - 7
        end_date    = today + 14
        status      = ' '
        changed_at  = lv_changed_at
        changed_by  = c_user
      )

      "Travel in the future
      (
        agency_id   = lv_agency
        travel_id   = lv_max_travel_id + 3
        description = 'Travel in the future'
        customer_id = 3
        begin_date  = today + 14
        end_date    = today + 28
        status      = ' '
        changed_at  = lv_changed_at
        changed_by  = c_user
      )

      "Travel for agency 070041
      (
        agency_id   = '070041'
        travel_id   = lv_max_travel_id + 4
        description = 'Travel for agency 70041'
        customer_id = 4
        begin_date  = today + 18
        end_date    = today + 26
        status      = ' '
        changed_at  = lv_changed_at
        changed_by  = c_user
      )

      "Travel for agency 070050
      (
        agency_id   = '070050'
        travel_id   = lv_max_travel_id + 5
        description = 'Travel for agency 70050'
        customer_id = 4
        begin_date  = today + 14
        end_date    = today + 21
        status      = ' '
        changed_at  = lv_changed_at
        changed_by  = c_user
      )

    ).

    ASSIGN data_ref->* TO <lt_data>.

    "Replace the in-memory rows with the generated records.
    MOVE-CORRESPONDING lt_data TO <lt_data>.

    IF totetag_field IS NOT INITIAL.
      add_totetag_field( ).
    ENDIF.

    dbsync( ).

  ENDMETHOD.


  METHOD delete_data.

    FIELD-SYMBOLS <lt_data> TYPE ANY TABLE.

    ASSIGN data_ref->* TO <lt_data>.

    CLEAR <lt_data>.

    dbsync( ).

  ENDMETHOD.


  METHOD add_totetag_field.

    FIELD-SYMBOLS <lt_data> TYPE ANY TABLE.

    ASSIGN data_ref->* TO <lt_data>.

    LOOP AT <lt_data> ASSIGNING FIELD-SYMBOL(<ls_data>).

      ASSIGN COMPONENT totetag_field
        OF STRUCTURE <ls_data>
        TO FIELD-SYMBOL(<lv_etag>).

      IF sy-subrc = 0 AND <lv_etag> IS INITIAL.
        GET TIME STAMP FIELD <lv_etag>.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD dbselect.

    FIELD-SYMBOLS <lt_data> TYPE ANY TABLE.

    ASSIGN data_ref->* TO <lt_data>.

    SELECT FROM (tabname)
      FIELDS *
      INTO TABLE @<lt_data>.

  ENDMETHOD.


  METHOD dbsync.

    FIELD-SYMBOLS <lt_data> TYPE ANY TABLE.

    ASSIGN data_ref->* TO <lt_data>.

    IF <lt_data> IS INITIAL.

      "Delete all rows from the selected table.
      DELETE FROM (tabname).

    ELSE.

      "Insert new rows or update rows with matching primary keys.
      MODIFY (tabname) FROM TABLE @<lt_data>.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
