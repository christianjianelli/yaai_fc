CLASS ycl_aai_fc_message_class_tools DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    CONSTANTS: mc_pgmid  TYPE e071-pgmid VALUE 'R3TR',
               mc_object TYPE e071-object VALUE 'MSAG'.

    METHODS create
      IMPORTING
                i_message_class     TYPE yde_aai_fc_message_class
                i_description       TYPE as4text
                i_package           TYPE packname
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS read
      IMPORTING
                i_message_class   TYPE yde_aai_fc_message_class
      RETURNING VALUE(r_response) TYPE string.

    METHODS search
      IMPORTING
                i_package           TYPE packname
                i_message_class     TYPE yde_aai_fc_message_class OPTIONAL
                i_short_description TYPE as4text OPTIONAL
      RETURNING VALUE(r_response)   TYPE string.

    METHODS update
      IMPORTING
                i_message_class     TYPE yde_aai_fc_message_class
                i_description       TYPE as4text
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS read_message
      IMPORTING
                i_message_class   TYPE yde_aai_fc_message_class
                i_message_number  TYPE symsgno
                i_language        TYPE spras OPTIONAL
      RETURNING VALUE(r_response) TYPE string.

    METHODS add_message
      IMPORTING
                i_message_class     TYPE yde_aai_fc_message_class
                i_message_number    TYPE symsgno OPTIONAL
                i_message_text      TYPE natxt
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS update_message
      IMPORTING
                i_message_class     TYPE yde_aai_fc_message_class
                i_message_number    TYPE symsgno
                i_message_text      TYPE natxt
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS delete_message
      IMPORTING
                i_message_class     TYPE yde_aai_fc_message_class
                i_message_number    TYPE symsgno
                i_transport_request TYPE yde_aai_fc_transport_request
      RETURNING VALUE(r_response)   TYPE string.

    METHODS read_all_messages
      IMPORTING
                i_message_class   TYPE yde_aai_fc_message_class
      RETURNING VALUE(r_response) TYPE string.

    METHODS set_translation
      IMPORTING
                i_message_class     TYPE yde_aai_fc_message_class
                i_message_number    TYPE symsgno
                i_transport_request TYPE yde_aai_fc_transport_request
                i_language          TYPE spras
                i_message_text      TYPE natxt
      RETURNING VALUE(r_response)   TYPE string.

    METHODS get_translation
      IMPORTING
                i_message_class   TYPE yde_aai_fc_message_class
                i_message_number  TYPE symsgno OPTIONAL
                i_language        TYPE spras
      RETURNING VALUE(r_response) TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.

    METHODS _get_next_number
      IMPORTING
                i_message_class         TYPE yde_aai_fc_message_class
      RETURNING VALUE(r_message_number) TYPE symsgno.

ENDCLASS.



CLASS ycl_aai_fc_message_class_tools IMPLEMENTATION.

  METHOD create.

    CLEAR r_response.

    DATA(l_message_class) = i_message_class.

    l_message_class = condense( to_upper( l_message_class ) ).

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.
      r_response = |The transport request { l_transport_request } is invalid.|.
      RETURN.
    ENDIF.

    DATA(l_package) = i_package.

    l_package = condense( to_upper( l_package ) ).

    DATA(lo_message_class_api) = NEW cl_adt_message_class_api( ).

    DATA(l_success) = lo_message_class_api->create(
      EXPORTING
        iv_name              = CONV #( l_message_class )
        iv_description       = CONV #( i_description )
        iv_package           = l_package
        iv_transport_request = l_transport_request
    ).

    IF l_success = abap_false.
      r_response = |An error occurred while creating the message class { l_message_class }.|.
      RETURN.
    ENDIF.

    r_response = |Message class { l_message_class } created successfully.|.

  ENDMETHOD.

  METHOD read.

    CLEAR r_response.

    DATA(l_message_class) = i_message_class.

    l_message_class = condense( to_upper( l_message_class ) ).

    SELECT SINGLE arbgb, masterlang
      FROM t100a
      WHERE arbgb = @l_message_class
      INTO @DATA(ls_t100a).

    IF sy-subrc <> 0.
      r_response = |Message class { l_message_class } not found.|.
      RETURN.
    ENDIF.

    SELECT SINGLE sprsl, arbgb, stext
      FROM t100t
      WHERE sprsl = @sy-langu
        AND arbgb = @l_message_class
      INTO @DATA(ls_t100t).

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_message_class
      INTO @DATA(ls_tadir).

    r_response = |Message Class: { l_message_class }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Description: { ls_t100t-stext }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Package: { ls_tadir-devclass }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Original Language: { ls_tadir-masterlang }|.

    NEW cl_adt_message_class_api( )->read(
      EXPORTING
        iv_name              = l_message_class
        iv_fetch_master_lang = abap_true
        iv_fetch_all         = abap_false
      IMPORTING
        rt_messages          = DATA(lt_messages)
    ).

    IF lt_messages IS INITIAL.
      r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Messages: the message class has no messages|.
    ENDIF.

    LOOP AT lt_messages ASSIGNING FIELD-SYMBOL(<ls_message>).

      IF sy-tabix = 1.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Messages:|.
      ENDIF.

      r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - '{ <ls_message>-msgnr }' { <ls_message>-text }|.

    ENDLOOP.

  ENDMETHOD.

  METHOD search.

    DATA: l_message_class     TYPE string,
          l_short_description TYPE string.

    CLEAR r_response.

    DATA(l_package) = i_package.

    l_package = condense( to_upper( l_package ) ).

    SELECT pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND devclass = @l_package
        AND delflag <> @abap_true
      INTO TABLE @DATA(lt_tadir).                       "#EC CI_GENBUFF

    IF sy-subrc <> 0.
      r_response = |No message class found.|.
      RETURN.
    ENDIF.

    l_message_class = |*{ i_message_class }*|.

    l_short_description = |*{ i_short_description }*|.

    LOOP AT lt_tadir ASSIGNING FIELD-SYMBOL(<ls_tadir>).

      IF l_message_class IS NOT INITIAL.

        IF NOT <ls_tadir>-obj_name CP l_message_class.
          CONTINUE.
        ENDIF.

      ENDIF.

      SELECT SINGLE sprsl, arbgb, stext
        FROM t100t
        WHERE sprsl = @sy-langu
          AND arbgb = @<ls_tadir>-obj_name
         INTO @DATA(ls_t100t).

      IF i_short_description IS NOT INITIAL.

        IF NOT ls_t100t-stext CP l_short_description.
          CONTINUE.
        ENDIF.

      ENDIF.

      IF r_response IS NOT INITIAL.
        r_response = |{ r_response }{ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }|.
      ENDIF.

      r_response = |{ r_response }Message Class: { <ls_tadir>-obj_name }{ cl_abap_char_utilities=>newline }|.
      r_response = |{ r_response }Description: { ls_t100t-stext }{ cl_abap_char_utilities=>newline }|.

    ENDLOOP.

    IF r_response IS INITIAL.
      r_response = |No message class found.|.
      RETURN.
    ENDIF.

  ENDMETHOD.

  METHOD update.

    CLEAR r_response.

    DATA(l_message_class) = i_message_class.

    l_message_class = condense( to_upper( l_message_class ) ).

    SELECT SINGLE @abap_true
      FROM t100a
      WHERE arbgb = @l_message_class
      INTO @DATA(l_exists).

    IF sy-subrc <> 0.
      r_response = |Message class { l_message_class } not found.|.
      RETURN.
    ENDIF.

    SELECT SINGLE pgmid, object, obj_name, devclass
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_message_class
      INTO @DATA(ls_tadir).

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.
      r_response = |The transport request { l_transport_request } is invalid.|.
      RETURN.
    ENDIF.

    DATA(lo_message_class_api) = NEW cl_adt_message_class_api( ).

    DATA(l_success) = lo_message_class_api->update_class( iv_msg_class_name    = CONV #( l_message_class )
                                                          iv_short_text        = i_description
                                                          iv_package           = ls_tadir-devclass
                                                          iv_transport_request = l_transport_request ).

    IF l_success = abap_false.
      r_response = |An error occurred while updating the message class { l_message_class }.|.
      RETURN.
    ENDIF.

    r_response = |Message class { l_message_class } updated successfully.|.

  ENDMETHOD.

  METHOD add_message.

    DATA l_msgnr TYPE symsgno.

    DATA lt_message TYPE if_adt_mc_res_controller=>tt_message_api.

    DATA(l_message_class) = i_message_class.

    l_message_class = condense( to_upper( l_message_class ) ).

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.
      r_response = |The transport request { l_transport_request } is invalid.|.
      RETURN.
    ENDIF.

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_message_class
        AND delflag <> @abap_true
      INTO @DATA(ls_tadir).

    IF sy-subrc <> 0.
      r_response = |Message class { l_message_class } not found.|.
      RETURN.
    ENDIF.

    l_msgnr = i_message_number.

    IF l_msgnr IS INITIAL.
      l_msgnr = me->_get_next_number( l_message_class ).
    ENDIF.

    lt_message = VALUE #( ( message_no = l_msgnr
                            text = i_message_text ) ).

    DATA(lo_message_class_api) = NEW cl_adt_message_class_api( ).

    lo_message_class_api->read(
      EXPORTING
        iv_name              = l_message_class
        iv_fetch_master_lang = abap_true
        iv_fetch_all         = abap_true
      IMPORTING
        rt_messages          = DATA(lt_messages)
    ).

    DATA(l_success) = lo_message_class_api->update_message(
                        iv_name              = CONV #( l_message_class )
                        it_message           = lt_message
                        iv_transport_request = l_transport_request
                        iv_package           = ls_tadir-devclass
                      ).

    IF l_success = abap_false.
      r_response = |An error occurred while adding the message { l_msgnr }.|.
      RETURN.
    ENDIF.

    r_response = |Message { l_msgnr } added successfully.|.

  ENDMETHOD.

  METHOD update_message.

    DATA lt_message TYPE if_adt_mc_res_controller=>tt_message_api.

    DATA(l_message_class) = i_message_class.

    l_message_class = condense( to_upper( l_message_class ) ).

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.
      r_response = |The transport request { l_transport_request } is invalid.|.
      RETURN.
    ENDIF.

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_message_class
        AND delflag <> @abap_true
      INTO @DATA(ls_tadir).

    IF sy-subrc <> 0.
      r_response = |Message class { l_message_class } not found.|.
      RETURN.
    ENDIF.

    lt_message = VALUE #( ( message_no = i_message_number text = i_message_text ) ).

    DATA(lo_message_class_api) = NEW cl_adt_message_class_api( ).

    DATA(l_success) = lo_message_class_api->update_message(
                        iv_name              = CONV #( l_message_class )
                        it_message           = lt_message
                        iv_transport_request = l_transport_request
                        iv_package           = ls_tadir-devclass
                      ).

    IF l_success = abap_false.
      r_response = |An error occurred while updating the message { i_message_number }.|.
      RETURN.
    ENDIF.

    r_response = |Message { i_message_number } updated successfully.|.

  ENDMETHOD.

  METHOD delete_message.

    DATA(l_message_class) = i_message_class.

    l_message_class = condense( to_upper( l_message_class ) ).

    DATA(l_transport_request) = i_transport_request.

    l_transport_request = condense( to_upper( l_transport_request ) ).

    DATA(lo_cts_api) = NEW ycl_aai_fc_cts_api( ).

    IF lo_cts_api->is_valid( l_transport_request ) = abap_false.
      r_response = |The transport request { l_transport_request } is invalid.|.
      RETURN.
    ENDIF.

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_message_class
        AND delflag <> @abap_true
      INTO @DATA(ls_tadir).

    IF sy-subrc <> 0.
      r_response = |Message class { l_message_class } not found.|.
      RETURN.
    ENDIF.

    DATA(lo_message_class_api) = NEW cl_adt_message_class_api( ).

    DATA(l_success) = lo_message_class_api->delete(
                        iv_name              = CONV #( l_message_class )
                        iv_number            = i_message_number
                        iv_transport_request = l_transport_request
                        iv_package           = ls_tadir-devclass
                      ).

    IF l_success = abap_false.
      r_response = |An error occurred while deleting the message { i_message_number }.|.
      RETURN.
    ENDIF.

    r_response = |Message { i_message_number } deleted successfully.|.

  ENDMETHOD.

  METHOD read_all_messages.

    DATA(l_message_class) = i_message_class.

    l_message_class = condense( to_upper( l_message_class ) ).

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_message_class
        AND delflag <> @abap_true
      INTO @DATA(ls_tadir).

    IF sy-subrc <> 0.
      r_response = |Message class { l_message_class } not found.|.
      RETURN.
    ENDIF.

    DATA(lo_message_class_api) = NEW cl_adt_message_class_api( ).

    lo_message_class_api->read(
      EXPORTING
        iv_name              = l_message_class
        iv_fetch_master_lang = abap_true
        iv_fetch_all         = abap_false
      IMPORTING
        rt_messages          = DATA(lt_messages)
    ).

    IF lt_messages IS INITIAL.
      r_response = |The message class { l_message_class } has no messages.|.
      RETURN.
    ENDIF.

    r_response = |The message class { l_message_class } has the following messages:|.

    LOOP AT lt_messages ASSIGNING FIELD-SYMBOL(<ls_message>).

      r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - '{ <ls_message>-msgnr }' { <ls_message>-text }|.

    ENDLOOP.

  ENDMETHOD.

  METHOD read_message.

    DATA l_language_out TYPE c LENGTH 2.

    DATA(l_message_class) = i_message_class.
    DATA(l_language) = i_language.

    l_message_class = condense( to_upper( l_message_class ) ).

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_message_class
        AND delflag <> @abap_true
      INTO @DATA(ls_tadir).

    IF sy-subrc <> 0.
      r_response = |Message class { l_message_class } not found.|.
      RETURN.
    ENDIF.

    IF l_language IS INITIAL.
      l_language = ls_tadir-masterlang.
    ENDIF.

    DATA(lo_message_class_api) = NEW cl_adt_message_class_api( ).

    lo_message_class_api->read(
      EXPORTING
        iv_name              = l_message_class
        iv_number            = i_message_number
        iv_language          = l_language
        iv_fetch_master_lang = abap_false
        iv_fetch_all         = abap_false
      IMPORTING
        rv_message_text      = DATA(l_message_text)
    ).

    CALL FUNCTION 'CONVERSION_EXIT_ISOLA_OUTPUT'
      EXPORTING
        input            = l_language
      IMPORTING
        output           = l_language_out
      EXCEPTIONS
        unknown_language = 0
        OTHERS           = 0.

    IF l_message_text IS INITIAL.
      r_response = |The message { i_message_number } has no text in language { l_language_out }.|.
      RETURN.
    ENDIF.

    r_response = |Message Class: { l_message_class }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Message Number: { i_message_number }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Message Text: { l_message_text }|.
    r_response = |{ r_response }{ cl_abap_char_utilities=>newline }Language: { l_language_out }|.

  ENDMETHOD.

  METHOD get_translation.

    DATA(l_message_class) = i_message_class.

    l_message_class = condense( to_upper( l_message_class ) ).

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_message_class
        AND delflag <> @abap_true
      INTO @DATA(ls_tadir).

    IF sy-subrc <> 0.
      r_response = |Message class { l_message_class } not found.|.
      RETURN.
    ENDIF.

    DATA(l_language) = i_language.

    l_language = to_upper( l_language ).

    DATA(lo_message_class_api) = NEW cl_adt_message_class_api( ).

    lo_message_class_api->read(
      EXPORTING
        iv_name              = l_message_class
        iv_number            = i_message_number
        iv_language          = l_language
        iv_fetch_master_lang = abap_false
        iv_fetch_all         = abap_false
      IMPORTING
        rt_messages          = DATA(lt_messages)
    ).

    IF lt_messages IS INITIAL.
      r_response = |The message class { l_message_class } has no messages in language { l_language }.|.
      RETURN.
    ENDIF.

    r_response = |The message class { l_message_class } has the following messages in language { l_language }:|.

    LOOP AT lt_messages ASSIGNING FIELD-SYMBOL(<ls_message>).

      r_response = |{ r_response }{ cl_abap_char_utilities=>newline } - '{ <ls_message>-msgnr }' { <ls_message>-text }|.

    ENDLOOP.

  ENDMETHOD.

  METHOD set_translation.

    DATA: lt_message TYPE if_adt_mc_res_controller=>tt_message_api,
          lt_e071    TYPE trwbo_t_e071.

    DATA l_language_out TYPE c LENGTH 2.

    DATA(l_message_class) = i_message_class.

    l_message_class = condense( to_upper( l_message_class ) ).

    SELECT SINGLE pgmid, object, obj_name, devclass, masterlang
      FROM tadir
      WHERE pgmid = @mc_pgmid
        AND object = @mc_object
        AND obj_name = @l_message_class
        AND delflag <> @abap_true
      INTO @DATA(ls_tadir).

    IF sy-subrc <> 0.
      r_response = |Message class { l_message_class } not found.|.
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

    l_language = to_upper( l_language ).

    IF l_language IS INITIAL.
      l_language = ls_tadir-masterlang.
    ENDIF.

    lt_message = VALUE #( ( message_no = i_message_number
                            text = i_message_text ) ).

    DATA(lo_message_class_api) = NEW cl_adt_message_class_api( ).

    DATA(l_success) = lo_message_class_api->update_message(
                        iv_name              = CONV #( l_message_class )
                        iv_language          = l_language
                        it_message           = lt_message
                        iv_transport_request = l_transport_request
                        iv_package           = ls_tadir-devclass
                      ).

    CALL FUNCTION 'CONVERSION_EXIT_ISOLA_OUTPUT'
      EXPORTING
        input            = l_language
      IMPORTING
        output           = l_language_out
      EXCEPTIONS
        unknown_language = 0
        OTHERS           = 0.

    IF l_success = abap_false.
      r_response = |An error occurred while updating the message { i_message_number } in language { l_language_out }.|.
      RETURN.
    ENDIF.

    lt_e071 = VALUE #( ( trkorr = l_transport_request
                         pgmid = 'LANG'
                         object = 'MESS'
                         obj_name = |{ l_message_class }{ i_message_number }|
                         lang = l_language ) ).

    l_success = NEW ycl_aai_fc_cts_api( )->add_object(
      EXPORTING
        i_transport_request = l_transport_request
      CHANGING
        ch_t_e071           = lt_e071
    ).

    IF l_success = abap_true.
      r_response = |Translation updated successfully. Message: { i_message_number }. Target language: { l_language_out }.|.
    ELSE.
      r_response = |Translation updated but it was not added to the transport request { l_transport_request }. Message: { i_message_number }. Target language: { l_language_out }.|.
    ENDIF.

  ENDMETHOD.

  METHOD _get_next_number.

    DATA l_msgnr TYPE symsgno.

    r_message_number = 0.

    DATA(lo_message_class_api) = NEW cl_adt_message_class_api( ).

    lo_message_class_api->read(
      EXPORTING
        iv_name              = i_message_class
        iv_fetch_master_lang = abap_true
        iv_fetch_all         = abap_false
      IMPORTING
        rt_messages          = DATA(lt_messages)
    ).

    l_msgnr = 1.

    DO 999 TIMES.

      READ TABLE lt_messages TRANSPORTING NO FIELDS
        WITH KEY msgnr = l_msgnr.

      IF sy-subrc <> 0.
        r_message_number = l_msgnr.
        EXIT.
      ENDIF.

      l_msgnr = l_msgnr + 1.

    ENDDO.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA l_response TYPE string.

    DATA(l_create) = abap_false.
    DATA(l_read) = abap_false.
    DATA(l_search) = abap_false.
    DATA(l_update) = abap_true.
    DATA(l_read_all_messages) = abap_false.
    DATA(l_add_message) = abap_false.
    DATA(l_update_message) = abap_false.
    DATA(l_delete_message) = abap_false.
    DATA(l_get_next) = abap_false.
    DATA(l_get_translation) = abap_false.
    DATA(l_set_translation) = abap_false.

    CASE abap_true.

      WHEN l_create.

        l_response = me->create(
          EXPORTING
            i_message_class     = 'ZMSG001'
            i_description       = 'Testing ADT API'
            i_package           = 'Z001'
            i_transport_request = 'NPLK900137'
        ).

      WHEN l_read.

        l_response = me->read(
          EXPORTING
            i_message_class = 'ZMSG002'
        ).

      WHEN l_search.

        l_response = me->search(
          EXPORTING
            i_package = 'Z001'
        ).

      WHEN l_update.

        l_response = me->update(
          EXPORTING
            i_message_class     = 'ZMSG002'
            i_description       = 'Testing API update 2'
            i_transport_request = 'NPLK900125'
        ).

      WHEN l_add_message.

        l_response = me->add_message(
                       i_message_class     = 'ZMSG001'
*                       i_message_number    = '003'
                       i_message_text      = 'Testing ADT API 2'
                       i_transport_request = 'NPLK900137'
                     ).

      WHEN l_update_message.

        l_response = me->update_message(
                       i_message_class     = 'ZMSG001'
                       i_message_number    = '003'
                       i_message_text      = 'Testing ADT API 2'
                       i_transport_request = 'NPLK900137'
                     ).

      WHEN l_read_all_messages.

        l_response = me->read_all_messages( i_message_class = 'ZMSG001' ).

      WHEN l_delete_message.

        l_response = me->delete_message(
                       i_message_class     = 'ZMSG001'
                       i_message_number    = '002'
                       i_transport_request = 'NPLK900137'
                     ).

      WHEN l_get_next.

        DATA(l_msgno) = me->_get_next_number( 'ZMSG001' ).

        l_response = l_msgno.

      WHEN l_get_translation.

        l_response = me->get_translation( i_message_class = 'ZMSG001' i_language = 'P' ).

      WHEN l_set_translation.

        l_response = me->set_translation(
                       i_message_class     = 'ZMSG001'
                       i_message_number    = '001'
                       i_language          = 'P'
                       i_message_text      = 'Testando a API do ADT'
                       i_transport_request = 'NPLK900137'
                     ).

*        l_response = me->set_translation(
*                       i_message_class     = 'ZMSG001'
*                       i_message_number    = '001'
*                       i_language          = 'S'
*                       i_message_text      = 'Pruebas de la API de ADT'
*                       i_transport_request = 'NPLK900137'
*                     ).

    ENDCASE.

    out->write( l_response ).

  ENDMETHOD.

ENDCLASS.
