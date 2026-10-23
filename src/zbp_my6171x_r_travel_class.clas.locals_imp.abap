CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS ZZvalidateClass
      FOR VALIDATE ON SAVE
      IMPORTING keys FOR Item~ZZvalidateClass.

ENDCLASS.


CLASS lhc_item IMPLEMENTATION.

  METHOD ZZvalidateClass.

    CONSTANTS c_area TYPE string VALUE `CLASS`.

    READ ENTITIES OF ZMY6171_R_TRAVEL IN LOCAL MODE
      ENTITY Item
        FIELDS ( AgencyId TravelId ZZClassZIT )
        WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).

      APPEND VALUE #(
        %tky       = <item>-%tky
        %state_area = c_area
      ) TO reported-item.

      IF <item>-ZZClassZIT IS INITIAL.

        APPEND VALUE #(
          %tky = <item>-%tky
        ) TO failed-item.

        APPEND VALUE #(
          %tky = <item>-%tky
          %msg = NEW zcl_my6171_create_messages(
            textid   = zcl_my6171_create_messages=>field_required
            severity = if_abap_behv_message=>severity-error
          )
          %element-ZZClassZIT = if_abap_behv=>mk-on
          %state_area = c_area
          %path-travel = CORRESPONDING #( <item> )
        ) TO reported-item.

      ELSE.

        SELECT SINGLE FROM zmy6171_tritem
          FIELDS zzclasszit
          WHERE zzclasszit = @<item>-ZZClassZIT
          INTO @DATA(lv_class_id).

        IF sy-subrc <> 0.

          APPEND VALUE #(
            %tky = <item>-%tky
          ) TO failed-item.

          APPEND VALUE #(
            %tky = <item>-%tky
            %msg = NEW zcl_my6171_create_messages(
              textid   = zcl_my6171_create_messages=>field_required
              severity = if_abap_behv_message=>severity-error
            )
            %element-ZZClassZIT = if_abap_behv=>mk-on
            %state_area = c_area
            %path-travel = CORRESPONDING #( <item> )
          ) TO reported-item.

        ENDIF.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.


CLASS lsc_ZMY6171_R_TRAVEL DEFINITION
  INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.


CLASS lsc_ZMY6171_R_TRAVEL IMPLEMENTATION.

  METHOD save_modified.

    LOOP AT update-item ASSIGNING FIELD-SYMBOL(<item>)
      WHERE %control-ZZClassZIT = if_abap_behv=>mk-on.

      UPDATE zmy6171_tritem
        SET zzclasszit = @<item>-ZZClassZIT
        WHERE item_uuid = @<item>-ItemUuid.

    ENDLOOP.

    LOOP AT create-item ASSIGNING <item>
      WHERE %control-ZZClassZIT = if_abap_behv=>mk-on.

      UPDATE zmy6171_tritem
        SET zzclasszit = @<item>-ZZClassZIT
        WHERE item_uuid = @<item>-ItemUuid.

    ENDLOOP.

  ENDMETHOD.


  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
