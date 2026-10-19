
CLASS zmycl_6171_create_messages DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES if_t100_message.
    INTERFACES if_t100_dyn_msg.
    INTERFACES if_abap_behv_message.

    CONSTANTS:
      BEGIN OF already_cancelled,
        msgid TYPE symsgid VALUE 'ZMY6171_MSG',
        msgno TYPE symsgno VALUE '001',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF already_cancelled,

      BEGIN OF field_required,
        msgid TYPE symsgid VALUE 'ZMY6171_MSG',
        msgno TYPE symsgno VALUE '002',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF field_required,

      BEGIN OF flight_date_past,
        msgid TYPE symsgid VALUE 'ZMY6171_MSG',
        msgno TYPE symsgno VALUE '003',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF flight_date_past,

      BEGIN OF begin_date_past,
        msgid TYPE symsgid VALUE 'ZMY6171_MSG',
        msgno TYPE symsgno VALUE '004',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF begin_date_past,

      BEGIN OF end_date_past,
        msgid TYPE symsgid VALUE 'ZMY6171_MSG',
        msgno TYPE symsgno VALUE '005',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF end_date_past,

      BEGIN OF dates_wrong_sequence,
        msgid TYPE symsgid VALUE 'ZMY6171_MSG',
        msgno TYPE symsgno VALUE '006',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF dates_wrong_sequence,

      BEGIN OF customer_required,
        msgid TYPE symsgid VALUE 'ZMY6171_MSG',
        msgno TYPE symsgno VALUE '007',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF customer_required,

      BEGIN OF customer_not_exist,
        msgid TYPE symsgid VALUE 'ZMY6171_MSG',
        msgno TYPE symsgno VALUE '008',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF customer_not_exist,

      BEGIN OF description_required,
        msgid TYPE symsgid VALUE 'ZMY6171_MSG',
        msgno TYPE symsgno VALUE '009',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF description_required,

      BEGIN OF agency_not_assigned,
        msgid TYPE symsgid VALUE 'ZMY6171_MSG',
        msgno TYPE symsgno VALUE '010',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF agency_not_assigned,

      BEGIN OF number_generation_failed,
        msgid TYPE symsgid VALUE 'ZMY6171_MSG',
        msgno TYPE symsgno VALUE '011',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF number_generation_failed,

      BEGIN OF number_not_returned,
        msgid TYPE symsgid VALUE 'ZMY6171_MSG',
        msgno TYPE symsgno VALUE '012',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF number_not_returned,

      BEGIN OF item_not_found,
        msgid TYPE symsgid VALUE 'ZMY6171_MSG',
        msgno TYPE symsgno VALUE '013',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF item_not_found.

    METHODS constructor
      IMPORTING
        textid   LIKE if_t100_message=>t100key OPTIONAL
        severity LIKE if_abap_behv_message~m_severity OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.


CLASS zmycl_6171_create_messages IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.

    super->constructor( ).

    IF textid IS INITIAL.
      if_t100_message~t100key =
        if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.

    IF severity IS INITIAL.
      if_abap_behv_message~m_severity =
        if_abap_behv_message=>severity-error.
    ELSE.
      if_abap_behv_message~m_severity = severity.
    ENDIF.

  ENDMETHOD.

ENDCLASS.

