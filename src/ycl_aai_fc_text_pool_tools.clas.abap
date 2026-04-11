CLASS ycl_aai_fc_text_pool_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    CONSTANTS: mc_pgmid  TYPE e071-pgmid VALUE 'R3TR',
               mc_object TYPE e071-object VALUE 'PROG'.

    METHODS create
      IMPORTING
                i_program_name      TYPE programm
                i_language          TYPE spras OPTIONAL
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
                i_language          TYPE spras OPTIONAL
                i_transport_request TYPE yde_aai_fc_transport_request
                i_t_text_elements   TYPE yyt_aai_fc_text_pool
      RETURNING VALUE(r_response)   TYPE string.

    METHODS delete
      IMPORTING
                i_program_name      TYPE programm
                i_text_element_key  TYPE textpoolky
                i_language          TYPE spras OPTIONAL
                i_transport_request TYPE yde_aai_fc_transport_request
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

    DATA: lt_text_pool TYPE STANDARD TABLE OF textpool,
          lt_e071      TYPE trwbo_t_e071.

    DATA l_reserve TYPE i.

    CLEAR r_response.

    IF i_t_text_elements IS INITIAL.
      r_response = 'No text elements provided.'.
      RETURN.
    ENDIF.

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

    IF l_language IS INITIAL.
      l_language = ls_tadir-masterlang.
    ENDIF.

    READ TEXTPOOL l_program_name INTO lt_text_pool LANGUAGE l_language.

    LOOP AT i_t_text_elements INTO DATA(ls_text_element).

      ls_text_element-key = to_upper( ls_text_element-key ).

      READ TABLE lt_text_pool
        WITH KEY key = ls_text_element-key
        ASSIGNING FIELD-SYMBOL(<ls_text_pool>).

      IF sy-subrc = 0.

        IF <ls_text_pool>-id = 'I'. "Text Symbol

          <ls_text_pool>-entry = ls_text_element-text.

        ENDIF.

        IF <ls_text_pool>-id = 'S'. "Selection Text

          <ls_text_pool>-entry+8 = ls_text_element-text.

        ENDIF.

      ELSE.

        APPEND INITIAL LINE TO lt_text_pool ASSIGNING <ls_text_pool>.

        IF strlen( ls_text_element-text ) < 20.
          l_reserve = strlen( ls_text_element-text ) + 10.
        ELSE.
          l_reserve = strlen( ls_text_element-text ) * 2.
        ENDIF.

        IF l_reserve > 132.
          l_reserve = 132.
        ENDIF.

        <ls_text_pool>-id = 'I'. "Text Symbol
        <ls_text_pool>-key = ls_text_element-key.
        <ls_text_pool>-entry = ls_text_element-text.
        <ls_text_pool>-length = l_reserve.

      ENDIF.

    ENDLOOP.

    INSERT TEXTPOOL l_program_name FROM lt_text_pool LANGUAGE l_language.

    IF sy-subrc <> 0.
      r_response = |Error while creating the text elements for report/program { l_program_name } in language { l_language }.|.
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
      r_response = |Text elements for report/program { l_program_name } created successfully in language { l_language },|.
      r_response = |{ r_response } but an error occurred while adding them to the transport request { l_transport_request }.|.
      RETURN.
    ENDIF.

    r_response = |Text elements for report/program { l_program_name } created successfully in language { l_language }.|.

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

    DATA: lt_text_pool TYPE STANDARD TABLE OF textpool,
          lt_e071      TYPE trwbo_t_e071.

    DATA l_update TYPE abap_bool.

    CLEAR r_response.

    IF i_t_text_elements IS INITIAL.
      r_response = 'No text elements provided.'.
      RETURN.
    ENDIF.

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

    IF l_language IS INITIAL.
      l_language = ls_tadir-masterlang.
    ENDIF.

    READ TEXTPOOL l_program_name INTO lt_text_pool LANGUAGE l_language.

    IF lt_text_pool IS INITIAL.
      r_response = |The report/program { l_program_name } has no text elements in language { l_language }.|.
      RETURN.
    ENDIF.

    LOOP AT i_t_text_elements INTO DATA(ls_text_element).

      ls_text_element-key = to_upper( ls_text_element-key ).

      READ TABLE lt_text_pool
        WITH KEY key = ls_text_element-key
        ASSIGNING FIELD-SYMBOL(<ls_text_pool>).

      IF sy-subrc = 0.

        l_update = abap_true.

        IF <ls_text_pool>-id = 'I'. "Text Symbol

          <ls_text_pool>-entry = ls_text_element-text.

        ENDIF.

        IF <ls_text_pool>-id = 'S'. "Selection Text

          <ls_text_pool>-entry+8 = ls_text_element-text.

        ENDIF.

      ENDIF.

    ENDLOOP.

    IF l_update = abap_false.
      r_response = |None of the text elements provided were found in the report/program { l_program_name }, language { l_language }.|.
      RETURN.
    ENDIF.

    INSERT TEXTPOOL l_program_name FROM lt_text_pool LANGUAGE l_language.

    IF sy-subrc <> 0.
      r_response = |Error while updating the text elements for report/program { l_program_name } in language { l_language }.|.
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
      r_response = |Text elements for report/program { l_program_name } updated successfully in language { l_language },|.
      r_response = |{ r_response } but an error occurred while adding them to the transport request { l_transport_request }.|.
      RETURN.
    ENDIF.

    r_response = |Text elements for report/program { l_program_name } updated successfully in language { l_language }.|.

  ENDMETHOD.

  METHOD delete.

    DATA: lt_text_pool TYPE STANDARD TABLE OF textpool,
          lt_e071      TYPE trwbo_t_e071.

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

    IF l_language IS INITIAL.
      l_language = ls_tadir-masterlang.
    ENDIF.

    DATA(l_text_element_key) = i_text_element_key.

    l_text_element_key = condense( to_upper( l_text_element_key ) ).

    READ TEXTPOOL l_program_name INTO lt_text_pool LANGUAGE l_language.

    IF lt_text_pool IS INITIAL.
      r_response = |The report/program { l_program_name } has no text elements in language { l_language }.|.
      RETURN.
    ENDIF.

    DELETE lt_text_pool
      WHERE key = l_text_element_key.

    IF sy-subrc <> 0.
      r_response = |The text element provided was not found in the report/program { l_program_name } in language { l_language }.|.
      RETURN.
    ENDIF.

    INSERT TEXTPOOL l_program_name FROM lt_text_pool LANGUAGE l_language.

    IF sy-subrc <> 0.
      r_response = |Error while deleting the text element { l_text_element_key } of report/program { l_program_name } in language { l_language }.|.
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
      r_response = |Text element { l_text_element_key } of report/program { l_program_name } deleted successfully in language { l_language },|.
      r_response = |{ r_response } but an error occurred while adding it to the transport request { l_transport_request }.|.
      RETURN.
    ENDIF.

    r_response = |Text element { l_text_element_key } of report/program { l_program_name } deleted successfully in language { l_language }.|.

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

    DATA(l_create) = abap_false.
    DATA(l_read) = abap_true.
    DATA(l_update) = abap_false.
    DATA(l_delete) = abap_false.
    DATA(l_translate) = abap_false.

    CASE abap_true.

      WHEN l_create.

        l_response = me->create(
                       i_program_name      = 'ZCHRJS25'
                       i_transport_request = 'NPLK900137'
                       i_t_text_elements   = VALUE #( ( key = '008' text = 'Text symbol 008' ) )
                     ).

      WHEN l_read.

        l_response = me->read( i_program_name = 'ZCHRJS25' i_language = 'E' ).

      WHEN l_update.

        l_response = me->update(
                       i_program_name      = 'ZCHRJS25'
                       i_transport_request = 'NPLK900137'
                       i_t_text_elements   = VALUE #( ( key = '005' text = 'Text Symbol 5' )
                                                      ( key = '006' text = 'Text Symbol 6' ) )
                     ).

      WHEN l_delete.

        l_response = me->delete(
                       i_program_name      = 'ZCHRJS25'
                       i_text_element_key  = '008'
                       i_transport_request = 'NPLK900137'
                     ).

      WHEN l_translate.

        l_response = me->translate(
                       i_program_name      = 'ZCHRJS25'
                       i_language          = 'P'
                       i_transport_request = 'NPLK900137'
                       i_t_text_elements   = VALUE #( ( key = '001' text = 'Símbolo de texto 1' )
                                                      ( key = '002' text = 'Símbolo de texto 2' )
                                                      ( key = '003' text = 'Símbolo de texto 3' )
                                                      ( key = '004' text = 'Símbolo de texto 4' )
                                                      ( key = '005' text = 'Símbolo de texto 5' )
                                                      ( key = '006' text = 'Símbolo de texto 6' )
                                                      ( key = '007' text = 'Símbolo de texto 7' ) )
                     ).


    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
