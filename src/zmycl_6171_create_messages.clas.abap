CLASS zmycl_6171_create_messages DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_t100_message .
    INTERFACES if_t100_dyn_msg .
    INTERFACES if_abap_behv_message.
    CONSTANTS:
        BEGIN OF already_cancelled,
          msgid TYPE symsgid VALUE '/LRN/S4D437',
          msgno TYPE symsgno VALUE '130',
          attr1 TYPE scx_attrname VALUE '',
          attr2 TYPE scx_attrname VALUE '',
          attr3 TYPE scx_attrname VALUE '',
          attr4 TYPE scx_attrname VALUE '',
        END OF already_cancelled.


    METHODS constructor
      IMPORTING
        !textid   LIKE if_t100_message=>t100key OPTIONAL
        severity LIKE if_abap_behv_message~m_severity OPTIONAL.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zmycl_6171_create_messages IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    CALL METHOD super->constructor.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.

    IF severity IS INITIAL.
      if_abap_behv_message~m_severity = if_abap_behv_message~severity-error.
    ELSE.
      if_abap_behv_message~m_severity = severity.
    ENDIF.
  ENDMETHOD.
ENDCLASS.





