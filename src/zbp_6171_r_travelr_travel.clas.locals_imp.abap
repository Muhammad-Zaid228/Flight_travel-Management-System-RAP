CLASS lsc_zmy6171_r_travel DEFINITION
  INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.
    METHODS adjust_numbers REDEFINITION.
    METHODS save_modified REDEFINITION.

ENDCLASS.


CLASS lsc_zmy6171_r_travel IMPLEMENTATION.


  METHOD adjust_numbers.

    DATA lv_user TYPE syuname.
    DATA lv_agency_id TYPE zuser_agency-agency_id.

    DATA lv_number TYPE cl_numberrange_runtime=>nr_number.
    DATA lv_returned_qty
      TYPE cl_numberrange_runtime=>nr_returned_quantity.

    DATA lv_travel_id TYPE zmy6171_travel-travel_id.

    "Nothing to number
    IF mapped-travel IS INITIAL.
      RETURN.
    ENDIF.

    "Get current user
    lv_user = cl_abap_context_info=>get_user_technical_name( ).

    "Get the user's agency assignment
    SELECT SINGLE agency_id
      FROM zuser_agency
      WHERE user_name = @lv_user
      INTO @lv_agency_id.

    "The assignment must exist before the save phase
    ASSERT lv_agency_id IS NOT INITIAL.

    "Generate numbers during late numbering
    TRY.

        cl_numberrange_runtime=>number_get(
          EXPORTING
            object            = 'ZTRAVEL_NR'
            nr_range_nr       = '01'
            quantity          = CONV #(
                                  lines( mapped-travel ) )
          IMPORTING
            number            = lv_number
            returned_quantity = lv_returned_qty
        ).

      CATCH cx_number_ranges INTO DATA(lx_number_ranges).
        RAISE SHORTDUMP TYPE cx_number_ranges
          EXPORTING
            previous = lx_number_ranges.
    ENDTRY.

    "Ensure that the complete requested quantity was returned
    ASSERT lv_returned_qty = lines( mapped-travel ).

    "Calculate the first number in the returned range
    lv_travel_id = lv_number - lv_returned_qty.

    "Assign the final keys
    LOOP AT mapped-travel ASSIGNING FIELD-SYMBOL(<travel>).

      lv_travel_id += 1.

      <travel>-AgencyId = lv_agency_id.
      <travel>-TravelId =
        CONV zmy6171_travel-travel_id( lv_travel_id ).

    ENDLOOP.

  ENDMETHOD.


  METHOD save_modified.

    "Get the current UTC timestamp for audit fields
    DATA lv_now TYPE abp_lastchange_tstmpl.
    GET TIME STAMP FIELD lv_now.


    "==================================================
    "MODULE 1: DELETE TRAVEL ITEMS
    "Purpose: Delete database rows for deleted RAP items
    "==================================================
    LOOP AT delete-item ASSIGNING FIELD-SYMBOL(<item_d>).

      DELETE FROM zmy6171_tritem
        WHERE item_uuid = @<item_d>-ItemUuid.

    ENDLOOP.


    "==================================================
    "MODULE 2: CREATE TRAVEL ITEMS
    "Purpose: Build and insert each new travel-item row
    "==================================================
    LOOP AT create-item ASSIGNING FIELD-SYMBOL(<item_c>).

      DATA(ls_new_item) = VALUE zmy6171_tritem(
        client               = sy-mandt
        item_uuid            = <item_c>-ItemUuid
        agency_id            = <item_c>-AgencyId
        travel_id            = <item_c>-TravelId
        carrier_id           = <item_c>-CarrierId
        connection_id        = <item_c>-ConnectionId
        flight_date          = <item_c>-FlightDate
        booking_id            = <item_c>-BookingId
        passenger_first_name = <item_c>-PassengerFirstName
        passenger_last_name  = <item_c>-PassengerLastName
        changed_at           = lv_now
        changed_by           = sy-uname
        loc_changed_at       = lv_now ).

      "Insert the new item into the custom database table
      INSERT zmy6171_tritem FROM @ls_new_item.

    ENDLOOP.


    "==================================================
    "MODULE 3: UPDATE TRAVEL ITEMS
    "Purpose: Update only the fields supplied by the request
    "==================================================
    LOOP AT update-item ASSIGNING FIELD-SYMBOL(<item_u>).

      "Read the existing item before changing its fields
      SELECT SINGLE *
        FROM zmy6171_tritem
        WHERE item_uuid = @<item_u>-ItemUuid
        INTO @DATA(ls_existing_item).

      "Skip this item if its database row was not found
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      "Update carrier only if it was supplied
      IF <item_u>-%control-CarrierId IS NOT INITIAL.
        ls_existing_item-carrier_id = <item_u>-CarrierId.
      ENDIF.

      "Update connection only if it was supplied
      IF <item_u>-%control-ConnectionId IS NOT INITIAL.
        ls_existing_item-connection_id = <item_u>-ConnectionId.
      ENDIF.

      "Update flight date only if it was supplied
      IF <item_u>-%control-FlightDate IS NOT INITIAL.
        ls_existing_item-flight_date = <item_u>-FlightDate.
      ENDIF.

      "Update booking ID only if it was supplied
      IF <item_u>-%control-BookingId IS NOT INITIAL.
        ls_existing_item-booking_id = <item_u>-BookingId.
      ENDIF.

      "Update passenger first name only if supplied
      IF <item_u>-%control-PassengerFirstName IS NOT INITIAL.
        ls_existing_item-passenger_first_name =
          <item_u>-PassengerFirstName.
      ENDIF.

      "Update passenger last name only if supplied
      IF <item_u>-%control-PassengerLastName IS NOT INITIAL.
        ls_existing_item-passenger_last_name =
          <item_u>-PassengerLastName.
      ENDIF.

      "Update the custom class field only if supplied
      IF <item_u>-%control-ZZClassZIT IS NOT INITIAL.
        ls_existing_item-zzclasszit = <item_u>-ZZClassZIT.
      ENDIF.

      "Refresh audit information
      ls_existing_item-changed_at     = lv_now.
      ls_existing_item-changed_by     = sy-uname.
      ls_existing_item-loc_changed_at = lv_now.

      "Save the updated item
      UPDATE zmy6171_tritem FROM @ls_existing_item.

    ENDLOOP.


    "==================================================
    "MODULE 4: CREATE TRAVEL LOGS
    "Purpose: Log each newly created travel directly
    "This replaces the unavailable event-handler mechanism
    "==================================================
    LOOP AT create-travel ASSIGNING FIELD-SYMBOL(<new_travel>).

      DATA lv_log_uuid TYPE sysuuid_x16.

      "Generate a unique ID for this log entry
      TRY.
          lv_log_uuid =
            cl_system_uuid=>create_uuid_x16_static( ).

        CATCH cx_uuid_error.
          "Skip this log entry if UUID generation fails
          CONTINUE.
      ENDTRY.

      "Build the log record using the newly created travel
      DATA(ls_log) = VALUE ztravellog(
        client    = sy-mandt
        log_uuid  = lv_log_uuid
        agency_id = <new_travel>-AgencyId
        travel_id = <new_travel>-TravelId
        origin    = 'ZMY6171_R_TRAVEL'
      ).

      "Insert the log record into the custom log table
      INSERT ztravellog FROM @ls_log.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS lhc_item DEFINITION
  INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS validateFlightDate
      FOR VALIDATE ON SAVE
      IMPORTING keys FOR Item~validateFlightDate.

    METHODS determineTravelDates
      FOR DETERMINE ON SAVE
      IMPORTING keys FOR Item~determineTravelDates.

ENDCLASS.


CLASS lhc_item IMPLEMENTATION.

  METHOD validateFlightDate.

    CONSTANTS c_area TYPE string VALUE 'FLIGHTDATE'.

    "Read the items being validated
    READ ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
      ENTITY Item
        FIELDS ( AgencyId TravelId FlightDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).

      "Register this validation state area
      APPEND VALUE #(
        %tky        = <item>-%tky
        %state_area = c_area
      ) TO reported-item.

      "Reject an empty flight date
      IF <item>-FlightDate IS INITIAL.

        APPEND VALUE #( %tky = <item>-%tky )
          TO failed-item.

        APPEND VALUE #(
          %tky = <item>-%tky
          %msg = NEW zmycl_6171_create_messages(
            textid   = zmycl_6171_create_messages=>field_required
            severity = if_abap_behv_message=>severity-error
          )
          %element-FlightDate = if_abap_behv=>mk-on
          %state_area = c_area
          %path-travel = CORRESPONDING #( <item> )
        ) TO reported-item.

        "Reject a flight date earlier than today's date
      ELSEIF <item>-FlightDate <
          cl_abap_context_info=>get_system_date( ).

        APPEND VALUE #( %tky = <item>-%tky )
          TO failed-item.

        APPEND VALUE #(
          %tky = <item>-%tky
          %msg = NEW zmycl_6171_create_messages(
            textid   = zmycl_6171_create_messages=>flight_date_past
            severity = if_abap_behv_message=>severity-error
          )
          %element-FlightDate = if_abap_behv=>mk-on
          %state_area = c_area
          %path-travel = CORRESPONDING #( <item> )
        ) TO reported-item.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD determineTravelDates.

    "Read item flight dates and their parent travel dates
    READ ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
      ENTITY Item
        FIELDS ( FlightDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(items)
      BY \_Travel
        FIELDS ( BeginDate EndDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(travels)
      LINK DATA(link).

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).

      "Find the parent travel associated with this item
      ASSIGN travels[
        KEY id
        %tky = link[
          KEY id
          source-%tky = <item>-%tky
        ]-target-%tky
      ] TO FIELD-SYMBOL(<travel>).

      "Skip items without a parent or flight date
      IF sy-subrc <> 0 OR
         <item>-FlightDate IS INITIAL.
        CONTINUE.
      ENDIF.

      "Set end date to the latest item flight date
      IF <travel>-EndDate IS INITIAL OR
         <item>-FlightDate > <travel>-EndDate.
        <travel>-EndDate = <item>-FlightDate.
      ENDIF.

      "Set begin date to the earliest item flight date
      IF <travel>-BeginDate IS INITIAL OR
         <item>-FlightDate < <travel>-BeginDate.
        <travel>-BeginDate = <item>-FlightDate.
      ENDIF.

    ENDLOOP.

    "Persist the calculated parent travel dates
    MODIFY ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
      ENTITY Travel
        UPDATE FIELDS ( BeginDate EndDate )
        WITH CORRESPONDING #( travels ).

  ENDMETHOD.

ENDCLASS.

CLASS lhc_Travel DEFINITION
  INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_instance_authorizations
      FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations
      FOR Travel RESULT result.

    METHODS cancel_travel
      FOR MODIFY
      IMPORTING keys FOR ACTION Travel~cancel_travel.

    METHODS validateDescription
      FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateDescription.

    METHODS validateCustomer
      FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateCustomer.

    METHODS validateBeginDate
      FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateBeginDate.

    METHODS validateEndDate
      FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateEndDate.

    METHODS validateDateSequence
      FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateDateSequence.

    METHODS determineStatus
      FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~determineStatus.

    METHODS get_instance_features
      FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features
      FOR Travel RESULT result.


ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_authorizations.

    DATA lv_user TYPE syuname.
    DATA lv_agency_id TYPE zuser_agency-agency_id.

    "Get the current technical username
    lv_user = cl_abap_context_info=>get_user_technical_name( ).

    "Find the agency assigned to this user
    SELECT SINGLE agency_id
      FROM zuser_agency
      WHERE user_name = @lv_user
      INTO @lv_agency_id.

    "Prepare authorization results for requested travels
    result = CORRESPONDING #( keys ).

    LOOP AT result ASSIGNING FIELD-SYMBOL(<auth>).

      "Allow changes only when the travel belongs to the user's agency
      IF lv_agency_id IS NOT INITIAL AND
         <auth>-AgencyId = lv_agency_id.

        <auth>-%update = if_abap_behv=>auth-allowed.
        <auth>-%delete = if_abap_behv=>auth-allowed.
        <auth>-%action-cancel_travel =
          if_abap_behv=>auth-allowed.

      ELSE.

        "Deny changes when the agency does not match
        <auth>-%update = if_abap_behv=>auth-unauthorized.
        <auth>-%delete = if_abap_behv=>auth-unauthorized.
        <auth>-%action-cancel_travel =
          if_abap_behv=>auth-unauthorized.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD cancel_travel.

    "Read selected travel records
    READ ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
      ENTITY Travel
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels INTO DATA(travel).

      "Only cancel a travel that is not already cancelled
      IF travel-Status <> 'C'.

        MODIFY ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
          ENTITY Travel
            UPDATE FIELDS ( Status )
            WITH VALUE #(
              ( %tky = travel-%tky
                Status = 'C' )
            ).

      ELSE.

        "Report an error if it was already cancelled
        APPEND VALUE #( %tky = travel-%tky )
          TO failed-travel.

        APPEND VALUE #(
          %tky = travel-%tky
          %msg = NEW zmycl_6171_create_messages(
            textid   = zmycl_6171_create_messages=>already_cancelled
            severity = if_abap_behv_message=>severity-error
          )
        ) TO reported-travel.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateDescription.

    CONSTANTS c_area TYPE string VALUE 'DESC'.

    READ ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
      ENTITY Travel
        FIELDS ( Description )
        WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      APPEND VALUE #(
        %tky        = <travel>-%tky
        %state_area = c_area
      ) TO reported-travel.

      "Description must not be empty
      IF <travel>-Description IS INITIAL.

        APPEND VALUE #( %tky = <travel>-%tky )
          TO failed-travel.

        APPEND VALUE #(
          %tky = <travel>-%tky
          %msg = NEW zmycl_6171_create_messages(
            textid   = zmycl_6171_create_messages=>description_required
            severity = if_abap_behv_message=>severity-error
          )
          %element-Description = if_abap_behv=>mk-on
          %state_area = c_area
        ) TO reported-travel.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateCustomer.

    CONSTANTS c_area TYPE string VALUE 'CUST'.

    READ ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
      ENTITY Travel
        FIELDS ( CustomerId )
        WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      APPEND VALUE #(
        %tky        = <travel>-%tky
        %state_area = c_area
      ) TO reported-travel.

      "Customer ID is mandatory
      IF <travel>-CustomerId IS INITIAL.

        APPEND VALUE #( %tky = <travel>-%tky )
          TO failed-travel.

        APPEND VALUE #(
          %tky = <travel>-%tky
          %msg = NEW zmycl_6171_create_messages(
            textid   = zmycl_6171_create_messages=>customer_required
            severity = if_abap_behv_message=>severity-error
          )
          %element-CustomerId = if_abap_behv=>mk-on
          %state_area = c_area
        ) TO reported-travel.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateBeginDate.

    CONSTANTS c_area TYPE string VALUE 'BEGINDATE'.

    READ ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
      ENTITY Travel
        FIELDS ( BeginDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      APPEND VALUE #(
        %tky        = <travel>-%tky
        %state_area = c_area
      ) TO reported-travel.

      "Begin date is mandatory
      IF <travel>-BeginDate IS INITIAL.

        APPEND VALUE #( %tky = <travel>-%tky )
          TO failed-travel.

        APPEND VALUE #(
          %tky = <travel>-%tky
          %msg = NEW zmycl_6171_create_messages(
            textid   = zmycl_6171_create_messages=>field_required
            severity = if_abap_behv_message=>severity-error
          )
          %element-BeginDate = if_abap_behv=>mk-on
          %state_area = c_area
        ) TO reported-travel.

        "Begin date cannot be earlier than today
      ELSEIF <travel>-BeginDate <
          cl_abap_context_info=>get_system_date( ).

        APPEND VALUE #( %tky = <travel>-%tky )
          TO failed-travel.

        APPEND VALUE #(
          %tky = <travel>-%tky
          %msg = NEW zmycl_6171_create_messages(
            textid   = zmycl_6171_create_messages=>begin_date_past
            severity = if_abap_behv_message=>severity-error
          )
          %element-BeginDate = if_abap_behv=>mk-on
          %state_area = c_area
        ) TO reported-travel.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateEndDate.

    CONSTANTS c_area TYPE string VALUE 'ENDDATE'.

    READ ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
      ENTITY Travel
        FIELDS ( EndDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      APPEND VALUE #(
        %tky        = <travel>-%tky
        %state_area = c_area
      ) TO reported-travel.

      "End date is mandatory
      IF <travel>-EndDate IS INITIAL.

        APPEND VALUE #( %tky = <travel>-%tky )
          TO failed-travel.

        APPEND VALUE #(
          %tky = <travel>-%tky
          %msg = NEW zmycl_6171_create_messages(
            textid   = zmycl_6171_create_messages=>field_required
            severity = if_abap_behv_message=>severity-error
          )
          %element-EndDate = if_abap_behv=>mk-on
          %state_area = c_area
        ) TO reported-travel.

        "End date cannot be earlier than today
      ELSEIF <travel>-EndDate <
          cl_abap_context_info=>get_system_date( ).

        APPEND VALUE #( %tky = <travel>-%tky )
          TO failed-travel.

        APPEND VALUE #(
          %tky = <travel>-%tky
          %msg = NEW zmycl_6171_create_messages(
            textid   = zmycl_6171_create_messages=>end_date_past
            severity = if_abap_behv_message=>severity-error
          )
          %element-EndDate = if_abap_behv=>mk-on
          %state_area = c_area
        ) TO reported-travel.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateDateSequence.

    CONSTANTS c_area TYPE string VALUE 'SEQUENCE'.

    READ ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
      ENTITY Travel
        FIELDS ( BeginDate EndDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      APPEND VALUE #(
        %tky        = <travel>-%tky
        %state_area = c_area
      ) TO reported-travel.

      "End date must not be earlier than begin date
      IF <travel>-BeginDate IS NOT INITIAL AND
         <travel>-EndDate IS NOT INITIAL AND
         <travel>-EndDate < <travel>-BeginDate.

        APPEND VALUE #( %tky = <travel>-%tky )
          TO failed-travel.

        APPEND VALUE #(
          %tky = <travel>-%tky
          %msg = NEW zmycl_6171_create_messages(
            textid   = zmycl_6171_create_messages=>dates_wrong_sequence
            severity = if_abap_behv_message=>severity-error
          )
          %element = VALUE #(
            BeginDate = if_abap_behv=>mk-on
            EndDate   = if_abap_behv=>mk-on
          )
          %state_area = c_area
        ) TO reported-travel.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD determineStatus.

    "Read the status of the affected travels
    READ ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
      ENTITY Travel
        FIELDS ( Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    "Keep only travels whose status is currently empty
    DELETE travels WHERE Status IS NOT INITIAL.
    CHECK travels IS NOT INITIAL.

    "Assign N as the default status
    MODIFY ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
      ENTITY Travel
        UPDATE FIELDS ( Status )
        WITH VALUE #(
          FOR travel IN travels
          ( %tky   = travel-%tky
            Status = 'N' )
        )
        REPORTED DATA(update_reported).

    "Return messages produced by the update
    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.

  METHOD get_instance_features.

    "Read fields needed to determine which actions are allowed
    READ ENTITIES OF ZMY6171_R_Travel IN LOCAL MODE
      ENTITY Travel
        FIELDS ( Status BeginDate EndDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

      "Build a result entry for the current travel
      APPEND CORRESPONDING #( <travel> ) TO result
        ASSIGNING FIELD-SYMBOL(<result>).

      "Disable update and cancellation for cancelled or expired travels
      IF <travel>-Status = 'C' OR
         ( <travel>-EndDate IS NOT INITIAL AND
           <travel>-EndDate <
             cl_abap_context_info=>get_system_date( ) ).

        <result>-%update = if_abap_behv=>fc-o-disabled.
        <result>-%action-cancel_travel =
          if_abap_behv=>fc-o-disabled.

      ELSE.

        "Otherwise, enable update and cancellation
        <result>-%update = if_abap_behv=>fc-o-enabled.
        <result>-%action-cancel_travel =
          if_abap_behv=>fc-o-enabled.

      ENDIF.

      "Lock customer and begin date when travel has already begun
      IF <travel>-BeginDate IS NOT INITIAL AND
         <travel>-BeginDate <
           cl_abap_context_info=>get_system_date( ).

        <result>-%field-CustomerId =
          if_abap_behv=>fc-f-read_only.

        <result>-%field-BeginDate =
          if_abap_behv=>fc-f-read_only.

      ELSE.

        "Otherwise, mark those fields as mandatory
        <result>-%field-CustomerId =
          if_abap_behv=>fc-f-mandatory.

        <result>-%field-BeginDate =
          if_abap_behv=>fc-f-mandatory.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
