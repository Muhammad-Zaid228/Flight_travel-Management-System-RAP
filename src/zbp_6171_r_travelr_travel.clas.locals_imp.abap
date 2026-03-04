CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.
    METHODS cancel_travel FOR MODIFY
      IMPORTING keys FOR ACTION travel~cancel_travel.
    METHODS validatedescription FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validatedescription.
    METHODS validatecustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validatecustomer.
    METHODS validatebegindate FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validatebegindate.
    METHODS validateenddate FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validateenddate.
    METHODS validatedatesequence FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validatedatesequence.
    METHODS determinestatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR travel~determinestatus.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR travel RESULT result.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE travel.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_authorizations.

*    result = CORRESPONDING #( keys ).
*    LOOP AT result ASSIGNING FIELD-SYMBOL(<result>).
*      DATA(rc) = /lrn/cl_s4d437_model=>authority_check(
*                             i_agencyid = <result>-agencyid
*                             i_actvt = '02' ).
*      IF rc <> 0.
*        <result>-%action-cancel_travel = if_abap_behv=>auth-unauthorized.
*        <result>-%update = if_abap_behv=>auth-unauthorized.
*      ELSE.
*        <result>-%action-cancel_travel = if_abap_behv=>auth-allowed.
*        <result>-%update = if_abap_behv=>auth-allowed.
*      ENDIF.
*    ENDLOOP.

  ENDMETHOD.

  METHOD cancel_travel.

    READ ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
      ENTITY Travel
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).
      IF travel-Status <> 'C'.
        MODIFY ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
          ENTITY Travel
            UPDATE FIELDS ( Status )
              WITH VALUE #( ( %tky = travel-%tky
                              Status = 'C' ) ).
      ELSE.
        APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = travel-%tky
                        %msg = NEW zmycl_6171_create_messages(
                               textid = zmycl_6171_create_messages=>already_cancelled
                               severity = if_abap_behv_message=>severity-error ) )
          TO reported-travel.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.
  METHOD validateDescription.

    CONSTANTS c_area TYPE string VALUE `DESC`.

    READ ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
      ENTITY Travel
        FIELDS ( Description )
        WITH CORRESPONDING #( keys )
        RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      APPEND VALUE #( %tky = <travel>-%tky
                      %state_area = c_area )
        TO reported-travel.

      IF <travel>-Description IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky )
          TO failed-travel.

        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
                        %element-Description = if_abap_behv=>mk-on
                        %state_area = c_area )
          TO reported-travel.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateCustomer.

    CONSTANTS c_area TYPE string VALUE `CUST`.

    READ ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
        ENTITY Travel
          FIELDS ( CustomerId )
          WITH CORRESPONDING #( keys )
          RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      APPEND VALUE #( %tky = <travel>-%tky
                      %state_area = c_area )
        TO reported-travel.

      IF <travel>-CustomerId IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky )
            TO failed-travel.

        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
                        %element-CustomerId = if_abap_behv=>mk-on
                        %state_area = c_area )
          TO reported-travel.
      ELSE.
        SELECT SINGLE FROM /dmo/i_customer
        FIELDS CustomerID
        WHERE CustomerID = @<travel>-CustomerId
        INTO @DATA(dummy).
        IF sy-subrc <> 0.
          APPEND VALUE #( %tky = <travel>-%tky
                          %msg = NEW /lrn/cm_s4d437(
                          textid = /lrn/cm_s4d437=>customer_not_exist
                          customerid = <travel>-CustomerId )
                          %element-CustomerId = if_abap_behv=>mk-on
                          %state_area = c_area )
            TO reported-travel.
        ENDIF.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateBeginDate.

    CONSTANTS c_area TYPE string VALUE `BEGINDATE`.

    READ ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
          ENTITY Travel
            FIELDS ( BeginDate )
            WITH CORRESPONDING #( keys )
            RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      APPEND VALUE #( %tky = <travel>-%tky
                      %state_area = c_area )
        TO reported-travel.

      IF <travel>-BeginDate IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky )
            TO failed-travel.

        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
                        %element-BeginDate = if_abap_behv=>mk-on
                        %state_area = c_area )
            TO reported-travel.

      ELSEIF <travel>-BeginDate < cl_abap_context_info=>get_system_date( ).
        APPEND VALUE #( %tky = <travel>-%tky )
        TO failed-travel.
        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>begin_date_past )
                        %element-Begindate = if_abap_behv=>mk-on
                        %state_area = c_area )
        TO reported-travel.
      ENDIF.

  ENDLOOP.

ENDMETHOD.

  METHOD validateEndDate.

    CONSTANTS c_area TYPE string VALUE `ENDDATE`.

    READ ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
          ENTITY Travel
            FIELDS ( EndDate )
            WITH CORRESPONDING #( keys )
            RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      APPEND VALUE #( %tky = <travel>-%tky
                      %state_area = c_area )
        TO reported-travel.

      IF <travel>-EndDate IS INITIAL.
        APPEND VALUE #( %tky = <travel>-%tky )
            TO failed-travel.

        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
                        %element-EndDate = if_abap_behv=>mk-on
                        %state_area = c_area )
            TO reported-travel.

      ELSEIF <travel>-EndDate < cl_abap_context_info=>get_system_date( ).
        APPEND VALUE #( %tky = <travel>-%tky )
        TO failed-travel.
        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>end_date_past )
                        %element-EndDate = if_abap_behv=>mk-on
                        %state_area = c_area )
        TO reported-travel.
      ENDIF.

  ENDLOOP.

ENDMETHOD.

METHOD validateDateSequence.

  CONSTANTS c_area TYPE string VALUE `SEQUENCE`.

  READ ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
  ENTITY Travel
  FIELDS ( BeginDate EndDate )
  WITH CORRESPONDING #( keys )
  RESULT DATA(travels).
  LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

    APPEND VALUE #( %tky = <travel>-%tky
                      %state_area = c_area )
        TO reported-travel.

    IF <travel>-EndDate < <travel>-BeginDate.
      APPEND VALUE #( %tky = <travel>-%tky )
      TO failed-travel.
      APPEND VALUE #( %tky      = <travel>-%tky
                       %msg     = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>dates_wrong_sequence )
                       %element = VALUE #(
                                BeginDate = if_abap_behv=>mk-on
                                EndDate = if_abap_behv=>mk-on )
                                %state_area = c_area )
      TO reported-travel.
    ENDIF.
  ENDLOOP.
ENDMETHOD.

  METHOD earlynumbering_create.

  DATA(agencyid) = /lrn/cl_s4d437_model=>get_agency_by_user( ).
  mapped-travel = CORRESPONDING #( entities ).
  LOOP AT mapped-travel ASSIGNING FIELD-SYMBOL(<mapped_travel>).
    <mapped_travel>-AgencyID = agencyid.
    <mapped_travel>-TravelID = /lrn/cl_s4d437_model=>get_next_travelid( ).
  ENDLOOP.

  ENDMETHOD.

  METHOD determineStatus.

  READ ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
    ENTITY Travel
      FIELDS ( Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

  DELETE travels WHERE Status IS NOT INITIAL.
  CHECK travels IS NOT INITIAL.

  MODIFY ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
    ENTITY Travel
      UPDATE FIELDS ( Status )
        WITH VALUE #( FOR key IN travels ( %tky = key-%tky
                                              Status = 'N' ) )
        REPORTED DATA(update_reported).

  reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
      ENTITY Travel
        FIELDS ( Status BeginDate EndDate )
        WITH CORRESPONDING #( keys )
        RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

     APPEND CORRESPONDING #( <travel> ) TO result
       ASSIGNING FIELD-SYMBOL(<result>).

    IF <travel>-Status = 'C' OR
       ( <travel>-EndDate IS NOT INITIAL AND
         <travel>-EndDate < cl_abap_context_info=>get_system_date( ) ).

       <result>-%update = if_abap_behv=>fc-o-disabled.
       <result>-%action-cancel_travel = if_abap_behv=>fc-o-disabled.

    " This else is optional bcz constant fc-o has initial(default) value 'enabled'.
    ELSE.
        <result>-%update = if_abap_behv=>fc-o-enabled.
        <result>-%action-cancel_travel = if_abap_behv=>fc-o-enabled.

    ENDIF.

    IF <travel>-BeginDate IS NOT INITIAL AND
       <travel>-BeginDate < cl_abap_context_info=>get_system_date( ).

       <result>-%field-CustomerId = if_abap_behv=>fc-f-read_only.
       <result>-%field-BeginDate = if_abap_behv=>fc-f-read_only.

    " This else is required bcz constant fc-f has not initial(default) value 'mandatory'.
    ELSE.
        <result>-%field-CustomerId = if_abap_behv=>fc-f-mandatory.
        <result>-%field-BeginDate = if_abap_behv=>fc-f-mandatory.

    ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
