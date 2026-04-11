CLASS ycl_aai_fc_text_pool_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    CONSTANTS: mc_pgmid       TYPE e071-pgmid VALUE 'R3TR',
               mc_object      TYPE e071-object VALUE 'PROG',
               mc_object_text TYPE e071-object VALUE 'REPT'.

    METHODS create
      IMPORTING
                i_program_name      TYPE programm
                i_transport_request TYPE yde_aai_fc_transport_request
                i_t_text_elements   TYPE yyt_aai_fc_text_pool
      RETURNING VALUE(r_response)   TYPE string.

    METHODS read
      IMPORTING
                i_program_name    TYPE programm
                i_language        TYPE spras OPTIONAL
      RETURNING VALUE(r_response) TYPE string.

    METHODS update
      IMPORTING
                i_program_name      TYPE programm
                i_transport_request TYPE yde_aai_fc_transport_request
                i_t_text_elements   TYPE yyt_aai_fc_text_pool
      RETURNING VALUE(r_response)   TYPE string.

    METHODS delete
      IMPORTING
                i_program_name      TYPE programm
                i_transport_request TYPE yde_aai_fc_transport_request
                i_t_text_elements   TYPE yyt_aai_fc_text_pool
      RETURNING VALUE(r_response)   TYPE string.

    METHODS translate
      IMPORTING
                i_program_name      TYPE programm
                i_language          TYPE spras
                i_transport_request TYPE yde_aai_fc_transport_request
                i_t_text_elements   TYPE yyt_aai_fc_text_pool
      RETURNING VALUE(r_response)   TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ycl_aai_fc_text_pool_tools IMPLEMENTATION.

  METHOD create.

    CLEAR r_response.

    DATA(l_program_name) = i_program_name.

    l_program_name = condense( to_upper( l_program_name ) ).

    SELECT SINGLE pgmid, object, obj_name, masterlang, devclass
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_program_name
      INTO @DATA(ls_tadir).

  ENDMETHOD.

  METHOD read.

    DATA: lt_rng_id    TYPE RANGE OF textpool-id,
          lt_text_pool TYPE STANDARD TABLE OF textpool.

    CLEAR r_response.

    DATA(l_program_name) = i_program_name.

    l_program_name = condense( to_upper( l_program_name ) ).

    DATA(l_language) = i_language.

    l_language = condense( to_upper( l_language ) ).

    READ TEXTPOOL l_program_name INTO lt_text_pool LANGUAGE l_language.

    IF lt_text_pool IS INITIAL.
      r_response = |The report/program { l_program_name } has no text elements in language { l_language }.|.
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
      r_response = |The report/program { l_program_name } has no text elements in language { l_language }.|.
      RETURN.
    ENDIF.

    r_response = |The report/program { l_program_name } has the following text elements in language { l_language }:|.

    LOOP AT lt_text_pool ASSIGNING <ls_text_pool>.
      r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - { <ls_text_pool>-key } { <ls_text_pool>-entry }|.
    ENDLOOP.

  ENDMETHOD.

  METHOD update.

    CLEAR r_response.

  ENDMETHOD.

  METHOD delete.

    CLEAR r_response.

  ENDMETHOD.

  METHOD translate.

    DATA: lt_text_pool_master TYPE STANDARD TABLE OF textpool,
          lt_text_pool_target TYPE STANDARD TABLE OF textpool,
          lt_e071             TYPE trwbo_t_e071.

    CLEAR r_response.

    DATA(l_program_name) = i_program_name.

    l_program_name = condense( to_upper( l_program_name ) ).

    SELECT SINGLE pgmid, object, obj_name, masterlang, devclass
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_program_name
      INTO @DATA(ls_tadir).

    IF sy-subrc <> 0.
      r_response = |Report/Program { l_program_name } not found.|.
      RETURN.
    ENDIF.

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.
      r_response = |The transport request { l_transport_request } is invalid.|.
      RETURN.
    ENDIF.

    DATA(l_language) = i_language.

    l_language = condense( to_upper( l_language ) ).

    READ TEXTPOOL l_program_name INTO lt_text_pool_master LANGUAGE ls_tadir-masterlang.
    READ TEXTPOOL l_program_name INTO lt_text_pool_target LANGUAGE l_language.

    IF lt_text_pool_master IS INITIAL.
      r_response = |The report/program { l_program_name } has no text elements.|.
      RETURN.
    ENDIF.

    LOOP AT i_t_text_elements INTO DATA(ls_text_element).

      ls_text_element-key = to_upper( ls_text_element-key ).

      READ TABLE lt_text_pool_master
        WITH KEY key = ls_text_element-key
        ASSIGNING FIELD-SYMBOL(<ls_text_pool_master>).

      IF sy-subrc = 0.

        READ TABLE lt_text_pool_target
          WITH KEY key = ls_text_element-key
          ASSIGNING FIELD-SYMBOL(<ls_text_pool_target>).

        IF sy-subrc <> 0.

          APPEND INITIAL LINE TO lt_text_pool_target ASSIGNING <ls_text_pool_target>.

          <ls_text_pool_target> = <ls_text_pool_master>.

        ENDIF.

        IF <ls_text_pool_target>-id = 'I'. "Text Symbol

          <ls_text_pool_target>-entry = ls_text_element-text.

        ENDIF.

        IF <ls_text_pool_target>-id = 'S'. "Selection Text

          <ls_text_pool_target>-entry+8 = ls_text_element-text.

        ENDIF.

      ENDIF.

    ENDLOOP.

    INSERT TEXTPOOL l_program_name FROM lt_text_pool_target LANGUAGE l_language.

    IF sy-subrc <> 0.
      r_response = |Error while saving text element translations for report/program { l_program_name } to language { l_language }.|.
      RETURN.
    ENDIF.

    lt_e071 = VALUE #( ( trkorr = l_transport_request
                         pgmid = 'LANG'
                         object = 'REPT'
                         obj_name = l_program_name
                         lang = l_language ) ).

    DATA(l_success) = NEW ycl_aai_fc_cts_api( )->add_object(
      EXPORTING
        i_transport_request = l_transport_request
      CHANGING
        ch_t_e071           = lt_e071
    ).

    IF l_success = abap_false.
      r_response = |Text elements for report/program { l_program_name } translated successfully to language { l_language },|.
      r_response = |{ r_response } but an error occurred while adding them to the transport request { l_transport_request }.|.
      RETURN.
    ENDIF.

    r_response = |Text elements for report/program { l_program_name } translated successfully to language { l_language }.|.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_read) = abap_false.
    DATA(l_translate) = abap_true.

    CASE abap_true.

      WHEN l_read.

        l_response = me->read( i_program_name = 'ZCHRJS25' i_language = 'E' ).

      WHEN l_translate.

        l_response = me->translate(
                       i_program_name      = 'ZCHRJS25'
                       i_language          = 'P'
                       i_transport_request = 'NPLK900137'
                       i_t_text_elements   = VALUE #( ( key = '001' text = 'Elemento de texto 001' )
                                                      ( key = '002' text = 'Elemento de texto 002' )
                                                      ( key = '003' text = 'Elemento de texto 003' )
                                                      ( key = '004' text = 'Elemento de texto 004' ) )
                     ).


    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
