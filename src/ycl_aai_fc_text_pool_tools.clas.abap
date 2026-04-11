CLASS ycl_aai_fc_text_pool_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    CONSTANTS: mc_pgmid  TYPE e071-pgmid VALUE 'R3TR',
               mc_object TYPE e071-object VALUE 'MSAG'.

    METHODS read
      IMPORTING
                i_program_name    TYPE programm
                i_language        TYPE spras OPTIONAL
      RETURNING VALUE(r_response) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycl_aai_fc_text_pool_tools IMPLEMENTATION.

  METHOD read.

    DATA: lt_rng_id    TYPE RANGE OF textpool-id,
          lt_text_pool TYPE STANDARD TABLE OF textpool.

    FREE r_response.

    DATA(l_program_name) = i_program_name.

    l_program_name = condense( to_upper( l_program_name ) ).

    DATA(l_language) = i_language.

    l_language = condense( to_upper( l_language ) ).

    READ TEXTPOOL l_program_name INTO lt_text_pool LANGUAGE l_language.

    IF lt_text_pool IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT lt_text_pool ASSIGNING FIELD-SYMBOL(<ls_text_pool>).

      IF <ls_text_pool>-id = 'S' AND <ls_text_pool>-entry(8) = 'D       '.

        CLEAR <ls_text_pool>-id.

        CONTINUE.

      ENDIF.

      IF <ls_text_pool>-id = 'S'.

        <ls_text_pool>-entry = <ls_text_pool>-entry+8.

      ENDIF.

    ENDLOOP.

    lt_rng_id = VALUE #( ( sign = 'I' option = 'EQ' low = 'I' )
                         ( sign = 'I' option = 'EQ' low = 'S' ) ).

    DELETE lt_text_pool WHERE id NOT IN lt_rng_id.

    IF lt_text_pool IS INITIAL.
      r_response = |The report/program { l_program_name } has no text-symbols in language { l_language }.|.
      RETURN.
    ENDIF.

    r_response = |The report/program { l_program_name } has the following text-symbols in language { l_language }:|.
    LOOP AT lt_text_pool ASSIGNING <ls_text_pool>.
      r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - { <ls_text_pool>-key } { <ls_text_pool>-entry }|.
    ENDLOOP.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_read) = abap_true.

    CASE abap_true.

      WHEN l_read.

        l_response = me->read( i_program_name = 'ZRXX_REPORT_TEMPLATE' i_language = 'E' ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
